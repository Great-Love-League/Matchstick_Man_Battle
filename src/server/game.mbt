struct Game {
	world : @box2d.B2World
	weapon : WeaponManager
	mut particle_list:Array[Particle]
	mut particle_index:Int
	
	mut platform_list:Array[Platform]
	mut platform_index:Int
	
	mut enemy_list : Array[&EnemyTrait?]
	
	mut bullet_list : Array[Bullet]
	mut item_list : Array[Item]
	mut frame_count : Int
}
fn create_game() -> Game{
	let world = create_world(level=level1,flag=true)
	let weapon=create_weapon_manager()
	let game = Game::{
		world,
		weapon,
		particle_list:Array::new(),
		particle_index:0,
		platform_list:Array::new(),
		platform_index:0,
		enemy_list : Array::new(),
		bullet_list : Array::new(),
		item_list : Array::new(),
		frame_count : 0
	}
	game
}

fn Game::update(self:Self, p: @p5js.P5Instance) -> Unit {
		self.frame_count += 1
		
		if(self.particle_list[0].control.faint_state){
			if(self.particle_list[0].control.faint_resistance<300){
				self.particle_list[0].control.faint_resistance+=1
			}
			else{
				self.particle_list[0].control.faint_state=false
				self.particle_list[0].control.health=100
				self.particle_list[0].control.faint_resistance=0
			}
			self.world.step(1.0/60.0, 4)
			draw_world(p, self.world)
			return
		}
	if(p.keyIsDown(KeyJ)){
		self.particle_list[0].control.faint_state=true
	}
	
	// ===== 武器系统控制 =====
	// I、O、P、L键：装备不同武器
	if(p.keyIsDown(KeyI)){
		// 销毁旧武器
		for gun in self.weapon.gun_list {
			if gun.owner_id == 0 {
				gun.destroy(self)
			}
		}
		self.weapon.gun_list.clear()
		// 创建手枪
		self.create_pistol(0)
		println("装备手枪!")
	}
	if(p.keyIsDown(KeyO)){
		// 销毁旧武器
		for gun in self.weapon.gun_list {
			if gun.owner_id == 0 {
				gun.destroy(self)
			}
		}
		self.weapon.gun_list.clear()
		// 创建霰弹枪
		self.create_shotgun(0)
		println("装备霰弹枪!")
	}
	if(p.keyIsDown(KeyP)){
		// 销毁旧武器
		for gun in self.weapon.gun_list {
			if gun.owner_id == 0 {
				gun.destroy(self)
			}
		}
		self.weapon.gun_list.clear()
		// 创建狙击枪
		self.create_sniper(0)
		println("装备狙击枪!")
	}
	if(p.keyIsDown(KeyL)){
		// 销毁旧武器
		for gun in self.weapon.gun_list {
			if gun.owner_id == 0 {
				gun.destroy(self)
			}
		}
		self.weapon.gun_list.clear()
		// 创建激光枪
		self.create_laser_rifle(0)
		println("装备激光枪!")
	}
	
	// S键：使用武器射击
	if(p.keyIsDown(KeyS)){
		// 遍历找到玩家的武器并射击
		for gun in self.weapon.gun_list {
			if gun.owner_id == 0 {
				gun.attack(self)
				break
			}
		}
	}
	
	// 射击控制 - Z键发射子弹（直接发射，无需武器）
	if(p.keyIsDown(KeyZ)){
		let direction = if self.particle_list[0].control.walk_direction > 0.0 { 1.0 } else { -1.0 }
		self.shoot_bullet(0, direction)
	}		// 测试生成物品 - K键在角色前方生成生命包
		if(p.keyIsDown(KeyK)){
			let particle_pos = self.particle_list[0].torso.getCenterPosition()
			self.spawn_health_pack((particle_pos.getX() + 3.0, particle_pos.getY()))
		}
		
		if(p.keyIsDown(KeyA)){
			self.particle_walk(self.particle_list[0],-1)
		}
		else if(p.keyIsDown(KeyD)){
			self.particle_walk(self.particle_list[0],1)
		}
		else if(!self.particle_list[0].control.jump_state){
			self.particle_stand(self.particle_list[0])
		}
		if(p.keyIsDown(KeyW)){
			if self.particle_list[0].control.jump_cooldown <= 0 {
				if !self.particle_list[0].control.jump_state { // 如果不在跳跃状态，则开始跳跃
					self.particle_list[0].control.jump_state = true
					self.particle_list[0].control.jump_frame_count = 0  // 重置跳跃帧计数
					self.particle_list[0].control.jump_cooldown = j_dur_A + j_dur_B + j_dur_C  // 总共跳跃帧数
				}
			}
		}
		if(self.particle_list[0].control.jump_cooldown > 0){
			self.particle_list[0].control.jump_cooldown -= 1 
		}
		self.particle_jump(self.particle_list[0],0)
		
		// 更新子弹系统
		self.update_all_bullets()
		
		// 更新物品系统
		self.update_all_items()
		
		// 每60帧清理一次
		if self.frame_count % 60 == 0 {
			self.cleanup_bullets()
			self.cleanup_items()
		}
		
		self.world.step(1.0/60.0, 4)
}
// fn Game::

pub const VIEWPORT_WIDTH : Double = 1920 // 视口宽度
pub const VIEWPORT_HEIGHT : Double = 1080 // 视口高度

pub const Pi : Double = 3.141592653589793
let platform_index:Ref[Int]=Ref::new(0)

fn Game::create_static_box(
	self:Self,
	position: (Double, Double),
	size: (Double, Double)
)-> @box2d.B2Body{
	let box_def = @box2d.b2BoxDef()
	box_def.setExtents(@box2d.b2Vec2(size.0, size.1))
	box_def.setDensity(0.0)
	let body_def = @box2d.b2BodyDef()
	body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
	body_def.addShape(box_def.getBase())
	body_def.setRotation(0.0)
	body_def.setAllowSleep(false)
	let body = self.world.createBody(body_def)
	body
}
fn Game::create_dynamic_box(
	self:Self,
	position: (Double, Double),
	size: (Double, Double),
	density?: Double=1.0,
	friciton?: Double=0.2,
	groupindex?: Int=-1
)-> @box2d.B2Body{
	let box_def = @box2d.b2BoxDef()
	box_def.setExtents(@box2d.b2Vec2(size.0, size.1))
	box_def.setDensity(density)
	box_def.setFriction(friciton)
	box_def.setGroupIndex(groupindex)
	let body_def = @box2d.b2BodyDef()
	body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
	body_def.addShape(box_def.getBase())
	body_def.setRotation(0.0)
	body_def.setAllowSleep(false)
	let body = self.world.createBody(body_def)
	body
}
fn Game::create_joint(
	self: Self,
	body_a: @box2d.B2Body,
	body_b: @box2d.B2Body,
	anchor: (Double, Double),
	enable_limit?: Bool=false,
	lower_angle?: Double=0.0,
	upper_angle?: Double=0.0
)-> @box2d.B2Joint{
	let joint_def = @box2d.b2RevoluteJointDef()
	joint_def.setBody1(body_a)
	joint_def.setBody2(body_b)
	joint_def.setAnchorPoint(@box2d.b2Vec2(anchor.0, anchor.1))
	joint_def.setEnableLimit(enable_limit)
	joint_def.setLowerAngle(lower_angle)
	joint_def.setUpperAngle(upper_angle)
	let joint = self.world.createJoint(joint_def.getBase())
	joint
}
fn Game::is_contact(self:Self,a:@box2d.B2Body, b:@box2d.B2Body)->Bool{
	let contact_list=self.world.getContactList()
	for contact in contact_list {
		let bodyA=contact.getShape1().getBody()
		let bodyB=contact.getShape2().getBody()
		if (equals(bodyA, a) && equals(bodyB, b)) || (equals(bodyA, b) && equals(bodyB, a)) {
			return true
		}
	}
	false
}