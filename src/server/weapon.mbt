
let sword_shift:@box2d.B2Vec2=@box2d.b2Vec2(((-6.35)-(-7.07))/2, ((17.00)-(15.10))/2)
let gun_body_shift:@box2d.B2Vec2=@box2d.b2Vec2(0.0, 0.0)


pub struct WeaponManager{
	mut sword_index : Int
	sword_list : Array[Sword]
	mut gun_index : Int
	gun_list : Array[Gun]
}

fn create_weapon_manager() -> WeaponManager{
	let weapon_manager=WeaponManager::{
		sword_index:0,
		sword_list:Array::new(),
		gun_index:0,
		gun_list:Array::new()
	}
	weapon_manager
}

pub struct Sword{
	id : Int
	owner_id : Int
	body : @box2d.B2Body
}
pub struct Gun{
	id : Int
	owner_id : Int
	body : @box2d.B2Body
	
	// 子弹配置
	bullet_damage : Double
	bullet_speed : Double
	bullet_penetration : Int
	bullet_targets : Array[TargetType]
	
	// 射击控制
	fire_rate : Int  // 射速（帧间隔）
	mut last_fire_frame : Int  // 上次射击帧
	
	// 武器类型
	gun_type : GunType
}

// 枪械类型
pub enum GunType {
	Pistol       // 手枪：低伤害，快射速
	Shotgun      // 霰弹枪：散射，近距离
	Sniper       // 狙击枪：高伤害，穿透
	LaserRifle   // 激光枪：高穿透，中伤害
} derive(Show, Eq)

pub(open) trait WeaponCreate {
	create(game:Game,owner_id:Int) -> Unit
}

pub(open) trait WeaponControl {
	attack(Self, game:Game) -> Unit
	attack_at_angle(Self, game:Game, angle:Double) -> Unit
  get_attack_field(Self) -> Double = _
}

pub(open) trait WeaponDestroy {
	destroy(Self, game:Game) -> Unit
}

impl WeaponControl with get_attack_field(self) -> Double {
	return 1.0
}

pub impl WeaponCreate for Sword with create(game, owner_id){
	let bodydef=@map_loader.get_bodydef_from_raw(Some(sword_body), None) catch {
        _=> {
					println("Failed to create body definition for Sword")
					@box2d.b2BodyDef()
				}
    }
	let centerpos=game.particle_list[owner_id].right_forearm.getCenterPosition()
	let rotate =game.particle_list[owner_id].right_forearm.getRotation()
	let handpos=@box2d.b2Vec2(-@cmath.sin(rotate)*0.25+centerpos.getX(),-@cmath.cos(rotate)*0.25+centerpos.getY())

	bodydef.setPosition(@box2d.b2Vec2(handpos.getX()+sword_shift.getX(), handpos.getY()+sword_shift.getY()))
	
	game.weapon.sword_index+=1
	let aa:Sword=Sword::{
		id:game.weapon.sword_index,
		owner_id:owner_id,
		body:game.world.createBody(bodydef)
	}
	game.weapon.sword_list.push(aa)

	game.create_revolute_joint(game.particle_list[owner_id].right_forearm, aa.body, (handpos.getX(),handpos.getY()), enable_limit=false)|> ignore
}

pub impl WeaponControl for Sword with attack(self,game){
	for i in game.particle_list {
		if i.index==self.owner_id{
			continue
		}
		if game.is_contact(i.torso, self.body) || game.is_contact(i.head, self.body){
			i.control.health-=10
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
		else if game.is_contact(i.left_thigh, self.body) || game.is_contact(i.right_thigh, self.body){
			i.control.health-=5
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
		else if game.is_contact(i.left_shank, self.body) || game.is_contact(i.right_shank, self.body){
			i.control.health-=3
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
		else if game.is_contact(i.left_arm, self.body) || game.is_contact(i.right_arm, self.body){
			i.control.health-=4
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
		else if game.is_contact(i.left_forearm, self.body) || game.is_contact(i.right_forearm, self.body){
			i.control.health-=2
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
	}
	println("Sword attack!")
}

///|
/// 剑的角度攻击（近战武器不需要角度，直接调用普通攻击）
pub impl WeaponControl for Sword with attack_at_angle(self, game, _angle){
	self.attack(game)
}

pub impl WeaponDestroy for Sword with destroy(self, game){
	game.world.destroyBody(self.body)
}

pub impl WeaponCreate for Gun with create( game, owner_id){
	let bodydef:@box2d.B2BodyDef=@map_loader.get_bodydef_from_raw(Some(gun_body), None) catch {
				_=> {
					println("Failed to create body definition for Gun")
					@box2d.b2BodyDef()
				}
		}
	let centerpos=game.particle_list[owner_id].right_forearm.getCenterPosition()
	let rotate =game.particle_list[owner_id].right_forearm.getRotation()
	let handpos=@box2d.b2Vec2(-@cmath.sin(rotate)*0.25+centerpos.getX(),-@cmath.cos(rotate)*0.25+centerpos.getY())

	bodydef.setPosition(@box2d.b2Vec2(handpos.getX()+gun_body_shift.getX(), handpos.getY()+gun_body_shift.getY()))
	
	game.weapon.gun_index+=1
	
	// 创建手枪
	let aa:Gun=Gun::{
		id:game.weapon.gun_index,
		owner_id:owner_id,
		body:game.world.createBody(bodydef),
		
		// 手枪配置
		bullet_damage: 10.0,
		bullet_speed: 60.0,  // 提升速度
		bullet_penetration: 0,
		bullet_targets: [Player],
		
		fire_rate: 15,  // 每15帧可射击一次
		last_fire_frame: 0,
		
		gun_type: Pistol
	}
	game.weapon.gun_list.push(aa)

	game.create_revolute_joint(game.particle_list[owner_id].right_forearm, aa.body, (handpos.getX(),handpos.getY()), enable_limit=false)|> ignore
}

pub impl WeaponControl for Gun with attack(self,game){
	// 检查冷却
	if game.frame_count - self.last_fire_frame < self.fire_rate {
		return  // 还在冷却中
	}
	
	// 获取持有者信息
	let holder = game.particle_list[self.owner_id]
	let direction = if holder.control.walk_direction > 0.0 { 1.0 } else { -1.0 }
	
	// 根据枪械类型选择射击方式及参数
	match self.gun_type {
		Pistol => {
			// 手枪：轻微下坠，轻微后坐力
			game.shoot_bullet_advanced(
				self.owner_id, 
				direction,
				speed=60.0,
				damage=10,
				max_distance=100.0,
				penetration=0,
				gravity_compensation=0.95,  // 95%补偿，轻微下坠
				recoil_horizontal=3,       // 轻微水平后坐力
				recoil_vertical=0.3          // 轻微向上抬升
			)
			println("手枪射击，持有者: #\{self.owner_id}")
		}
		
		Shotgun => {
			// 霰弹枪：明显下坠，强烈后坐力
			game.shoot_shotgun(
				self.owner_id, 
				direction, 
				5,     // 5发子弹
				0.52,  // 30度扩散
				gravity_compensation=0.85,  // 85%补偿，明显下坠
				recoil_horizontal=4.0,      // 强烈水平后坐力
				recoil_vertical=0.6         // 明显向上抬升
			)
			println("霰弹枪射击，持有者: #\{self.owner_id}")
		}
		
		Sniper => {
			// 狙击枪：轻微下坠，中等后坐力
			game.shoot_penetrating_bullet_advanced(
				self.owner_id, 
				direction, 
				2,  // 穿透2个目标
				speed=80.0,
				damage=30,
				max_distance=120.0,
				gravity_compensation=0.98,  // 98%补偿，极轻微下坠
				recoil_horizontal=30.0,       // 高水平后坐力
				recoil_vertical=0.5          // 中等向上抬升
			)
			println("狙击枪射击，持有者: #\{self.owner_id}")
		}
		
		LaserRifle => {
			// 激光枪：完全无下坠，无后坐力（能量武器）
			game.shoot_penetrating_bullet_advanced(
				self.owner_id, 
				direction, 
				5,  // 穿透5个目标
				speed=100.0,
				damage=15,
				max_distance=150.0,
				gravity_compensation=1.0,    // 100%补偿，完全无下坠 ✨
				recoil_horizontal=0.0,       // 无后坐力 ✨
				recoil_vertical=0.0          // 无向上抬升 ✨
			)
			println("激光枪射击，持有者: #\{self.owner_id}")
		}
	}
	
	// 更新冷却
	self.last_fire_frame = game.frame_count
}

///|
/// Gun的角度攻击实现（支持鼠标控制）
pub impl WeaponControl for Gun with attack_at_angle(self, game, angle){
	// 检查冷却
	if game.frame_count - self.last_fire_frame < self.fire_rate {
		return  // 还在冷却中
	}
	
	// 根据枪械类型选择射击方式及参数
	match self.gun_type {
		Pistol => {
			// 手枪：轻微下坠，轻微后坐力
			game.shoot_bullet_at_angle(
				self.owner_id, 
				angle,
				speed=60.0,
				damage=10,
				max_distance=100.0,
				penetration=0,
				gravity_compensation=0.95,  // 95%补偿，轻微下坠
				recoil_horizontal=3.0,      // 轻微水平后坐力
				recoil_vertical=0.3         // 轻微向上抬升
			)
		}
		
		Shotgun => {
			// 霰弹枪：5发子弹，分散射击
			// 角度范围：±15度 (约0.26弧度)
			let spread = 0.26  // 总扩散角度
			let bullet_count = 5
			let angle_step = spread / (bullet_count - 1).to_double()
			let start_angle = angle - spread / 2.0
			
			for i = 0; i < bullet_count; i = i + 1 {
				let bullet_angle = start_angle + angle_step * i.to_double()
				game.shoot_bullet_at_angle(
					self.owner_id, 
					bullet_angle,
					speed=50.0,
					damage=6,
					max_distance=80.0,
					penetration=0,
					gravity_compensation=0.85,  // 85%补偿，明显下坠
					recoil_horizontal=4.0,      // 强烈水平后坐力
					recoil_vertical=0.6         // 明显向上抬升
				)
			}
		}
		
		Sniper => {
			// 狙击枪：轻微下坠，中等后坐力
			game.shoot_bullet_at_angle(
				self.owner_id, 
				angle,
				speed=80.0,
				damage=30,
				max_distance=120.0,
				penetration=2,  // 穿透2个目标
				gravity_compensation=0.98,  // 98%补偿，极轻微下坠
				recoil_horizontal=30.0,     // 高水平后坐力
				recoil_vertical=0.5         // 中等向上抬升
			)
		}
		
		LaserRifle => {
			// 激光枪：完全无下坠，无后坐力（能量武器）
			game.shoot_bullet_at_angle(
				self.owner_id, 
				angle,
				speed=100.0,
				damage=15,
				max_distance=150.0,
				penetration=5,  // 穿透5个目标
				gravity_compensation=1.0,    // 100%补偿，完全无下坠 ✨
				recoil_horizontal=0.0,       // 无后坐力 ✨
				recoil_vertical=0.0          // 无向上抬升 ✨
			)
		}
	}
	
	// 更新冷却
	self.last_fire_frame = game.frame_count
}

pub impl WeaponDestroy for Gun with destroy(self, game){
	game.world.destroyBody(self.body)
}

///|
/// 创建手枪（快捷方法）
fn Game::create_pistol(self : Self, owner_id : Int) -> Unit {
	Gun::create(self, owner_id)  // 默认就是手枪
}

///|
/// 创建霰弹枪
fn Game::create_shotgun(self : Self, owner_id : Int) -> Unit {
	let bodydef:@box2d.B2BodyDef=@map_loader.get_bodydef_from_raw(Some(gun_body), None) catch {
		_=> {
			println("Failed to create body definition for Shotgun")
			@box2d.b2BodyDef()
		}
	}
	let centerpos=self.particle_list[owner_id].right_forearm.getCenterPosition()
	let rotate =self.particle_list[owner_id].right_forearm.getRotation()
	let handpos=@box2d.b2Vec2(-@cmath.sin(rotate)*0.25+centerpos.getX(),-@cmath.cos(rotate)*0.25+centerpos.getY())

	bodydef.setPosition(@box2d.b2Vec2(handpos.getX()+gun_body_shift.getX(), handpos.getY()+gun_body_shift.getY()))
	
	self.weapon.gun_index+=1
	
	let gun:Gun=Gun::{
		id:self.weapon.gun_index,
		owner_id:owner_id,
		body:self.world.createBody(bodydef),
		
		// 霰弹枪配置（真实霰弹枪约350-400 m/s）
		bullet_damage: 6.0,
		bullet_speed: 50.0,  // 提升速度
		bullet_penetration: 0,
		bullet_targets: [Player],
		
		fire_rate: 40,  // 慢射速
		last_fire_frame: 0,
		
		gun_type: Shotgun
	}
	self.weapon.gun_list.push(gun)
	self.create_revolute_joint(self.particle_list[owner_id].right_forearm, gun.body, (handpos.getX(),handpos.getY()), enable_limit=false)|> ignore
}

///|
/// 创建狙击枪
fn Game::create_sniper(self : Self, owner_id : Int) -> Unit {
	let bodydef:@box2d.B2BodyDef=@map_loader.get_bodydef_from_raw(Some(gun_body), None) catch {
		_=> {
			println("Failed to create body definition for Sniper")
			@box2d.b2BodyDef()
		}
	}
	let centerpos=self.particle_list[owner_id].right_forearm.getCenterPosition()
	let rotate =self.particle_list[owner_id].right_forearm.getRotation()
	let handpos=@box2d.b2Vec2(-@cmath.sin(rotate)*0.25+centerpos.getX(),-@cmath.cos(rotate)*0.25+centerpos.getY())

	bodydef.setPosition(@box2d.b2Vec2(handpos.getX()+gun_body_shift.getX(), handpos.getY()+gun_body_shift.getY()))
	
	self.weapon.gun_index+=1
	
	let gun:Gun=Gun::{
		id:self.weapon.gun_index,
		owner_id:owner_id,
		body:self.world.createBody(bodydef),
		
		// 狙击枪配置（真实狙击步枪约800-1000 m/s）
		bullet_damage: 30.0,
		bullet_speed: 80.0,  // 高速度
		bullet_penetration: 2,
		bullet_targets: [Player],
		
		fire_rate: 60,  // 很慢的射速
		last_fire_frame: 0,
		
		gun_type: Sniper
	}
	self.weapon.gun_list.push(gun)
	self.create_revolute_joint(self.particle_list[owner_id].right_forearm, gun.body, (handpos.getX(),handpos.getY()), enable_limit=false)|> ignore
}

///|
/// 创建激光枪
fn Game::create_laser_rifle(self : Self, owner_id : Int) -> Unit {
	let bodydef:@box2d.B2BodyDef=@map_loader.get_bodydef_from_raw(Some(gun_body), None) catch {
		_=> {
			println("Failed to create body definition for LaserRifle")
			@box2d.b2BodyDef()
		}
	}
	let centerpos=self.particle_list[owner_id].right_forearm.getCenterPosition()
	let rotate =self.particle_list[owner_id].right_forearm.getRotation()
	let handpos=@box2d.b2Vec2(-@cmath.sin(rotate)*0.25+centerpos.getX(),-@cmath.cos(rotate)*0.25+centerpos.getY())

	bodydef.setPosition(@box2d.b2Vec2(handpos.getX()+gun_body_shift.getX(), handpos.getY()+gun_body_shift.getY()))
	
	self.weapon.gun_index+=1
	
	let gun:Gun=Gun::{
		id:self.weapon.gun_index,
		owner_id:owner_id,
		body:self.world.createBody(bodydef),
		
		// 激光枪配置（科幻武器，极高速度）
		bullet_damage: 15.0,
		bullet_speed: 1000.0,  // 超高速度
		bullet_penetration: 5,
		bullet_targets: [Player],
		
		fire_rate: 5,  // 超快射速
		last_fire_frame: 0,
		
		gun_type: LaserRifle
	}
	self.weapon.gun_list.push(gun)
	self.create_revolute_joint(self.particle_list[owner_id].right_forearm, gun.body, (handpos.getX(),handpos.getY()), enable_limit=false)|> ignore
}