pub suberror ParticleControlConfigError String
pub suberror GameStateError String

///|
/// 鼠标相关的JavaScript FFI函数
extern "js" fn getMouseX(p : @p5js.P5Instance) -> Double = 
  #| (p) => p.mouseX

extern "js" fn getMouseY(p : @p5js.P5Instance) -> Double = 
  #| (p) => p.mouseY

extern "js" fn mouseIsPressed(p : @p5js.P5Instance) -> Bool = 
  #| (p) => p.mouseIsPressed

struct Game {
	world : @box2d.B2World
	weapon : WeaponManager
	mut state : GameState
	mut particle_list:Array[Particle]
	mut particle_index:Int
	
	mut platform_list:Array[&PlatformTrait]
	mut platform_index:Int
	
	mut enemy_list : Array[&EnemyTrait?]
	
	mut bullet_list : Array[Bullet]
	mut item_list : Array[Item]
	mut frame_count : Int

	// 玩家控制配置列表
	mut particle_control_configs : Array[ParticleControlConfig]

	// 自定义函数列表
	mut custom_functions : Array[&GameCustomFunctionTrait]
	
	anchor : @box2d.B2Body
}

trait GameCustomFunctionTrait {
	call_custom_function(self: Self, game: Game, p5: @p5js.P5Instance) -> Unit
	get_call_stage(self: Self) -> GameState
}

pub(all) struct GameCustomFunction {
	stage : GameState
	func : (Game, @p5js.P5Instance) -> Unit
}

pub fn GameCustomFunction::new(
	stage : GameState,
	func : (Game, @p5js.P5Instance) -> Unit
) -> Self {
	GameCustomFunction::{
		stage,
		func
	}
}

pub impl GameCustomFunctionTrait for GameCustomFunction with call_custom_function(self, game: Game, p5: @p5js.P5Instance) -> Unit {
		(self.func)(game, p5)
}

pub impl GameCustomFunctionTrait for GameCustomFunction with get_call_stage(self) -> GameState {
		self.stage
}


///| 玩家控制配置结构体
struct ParticleControlConfig {
	from_internet : Bool

	left_key : @p5js.KeyCode
	right_key : @p5js.KeyCode
	jump_key : @p5js.KeyCode
	shoot_key : @p5js.KeyCode

	target_ip : String
	target_port : Int
	target_particle_index : Int
}

fn ParticleControlConfig::new(
	target_particle_index : Int,
	left_key~ : @p5js.KeyCode? = Some(KeyA),
	right_key~ : @p5js.KeyCode? = Some(KeyD),
	jump_key~ : @p5js.KeyCode? = Some(KeyW),
	shoot_key~ : @p5js.KeyCode? = Some(KeyZ),
	from_internet~ : Bool = false,
	target_ip~ : String? = None,
	target_port~ : Int? = None,
	) -> Self raise ParticleControlConfigError {

	if from_internet {
		// 检查必要参数
		if target_ip == None || target_port == None {
			println("Error: Missing target_ip or target_port for internet control.")
			raise ParticleControlConfigError("Missing target_ip or target_port for internet control.")
		}

		return ParticleControlConfig::{
			from_internet,
			left_key: @p5js.UnknownKey,
			right_key: @p5js.UnknownKey,
			jump_key: @p5js.UnknownKey,
			shoot_key: @p5js.UnknownKey,
			target_ip: target_ip.unwrap(),
			target_port: target_port.unwrap(),
			target_particle_index,
		}

	}

	if from_internet == false {
		// 检查必要参数
		if left_key == None || right_key == None || jump_key == None || shoot_key == None {
			println("Error: Missing key bindings for local control.")
			raise ParticleControlConfigError("Missing key bindings for local control.")
		}
		return ParticleControlConfig::{
			from_internet,
			left_key: left_key.unwrap(),
			right_key: right_key.unwrap(),
			jump_key: jump_key.unwrap(),
			shoot_key: shoot_key.unwrap(),
			target_ip: "",
			target_port: 0,
			target_particle_index,
		}
	}

	raise ParticleControlConfigError("Unknown error in ParticleControlConfig::new")

}

///| 游戏状态
enum GameState {
	GamePreparing
	GameRunning
	GamePaused
	GameOver
}derive(Eq)

///| 注册玩家控制配置，按键绑定或网络控制
pub fn Game::register_particle_control_config(
	self:Self,
	config: ParticleControlConfig
) -> Unit {
	self.particle_control_configs.push(config)
}

pub fn Game::register_custom_function(self:Self, func : &GameCustomFunctionTrait) -> Unit {
	self.custom_functions.push(func)
}

fn Game::run_custom_functions(self:Self, stage:GameState, p5: @p5js.P5Instance) -> Unit {
	for func in self.custom_functions {
		if func.get_call_stage() == stage {
			func.call_custom_function(self, p5)
		}
	}
}

fn Game::state_machine_update(self:Self, p5: @p5js.P5Instance) -> Unit {
	match self.state {
		GamePreparing => {
			self.prepare(p5)
		}
		GameRunning => {
			self.running(p5)
		}
		GamePaused => {
			self.pause(p5)
		}
		GameOver => {
			self.game_over(p5)
		}
	}
}

fn Game::prepare(self:Self, p5: @p5js.P5Instance) -> Unit {
	self.run_custom_functions(GamePreparing, p5)
	self.state = GameRunning
}

fn Game::pause(self:Self, p5: @p5js.P5Instance) -> Unit {
	self.run_custom_functions(GamePaused, p5)
	self.state = GameRunning
}

fn Game::running(self:Self, p5: @p5js.P5Instance) -> Unit {

	self.frame_count += 1

	for platform in self.platform_list {
		platform.update(self)
	}

	for config in self.particle_control_configs {
		if !config.from_internet {
			self.particle_control(config, p5) catch{
				e => {
					println("Error in particle_control: \{e} in particle index \{config.target_particle_index}.")
				}
			}
		}
		// 网络控制待实现
	}

	// 更新子弹系统
	self.update_all_bullets()
	
	// 更新物品系统
	self.update_all_items()
	
	// 每60帧清理一次
	if self.frame_count % 60 == 0 {
		self.cleanup_bullets()
		self.cleanup_items()
	}
		

	self.run_custom_functions(GameRunning, p5)


	self.world.step(1.0/60.0, 4)
	self.state = GameRunning
}

fn Game::game_over(self:Self, p5: @p5js.P5Instance) -> Unit {
	self.run_custom_functions(GameOver, p5)
	self.state = GameRunning
}

///| 重构后的玩家移动函数
fn Game::particle_control(self:Self, control_config: ParticleControlConfig, p : @p5js.P5Instance) -> Unit raise{

	let particle_index = control_config.target_particle_index
	if particle_index < 0 || particle_index >= self.particle_list.length() {
		println("Error: Invalid target_particle_index \{particle_index} in particle_control.")
		raise GameStateError("Invalid target_particle_index in particle_control. want to control \{particle_index}, but only \{self.particle_list.length()} particles exist.")
	}
	let particle = self.particle_list[particle_index]

	if control_config.from_internet {
		raise GameStateError("Internet control not implemented yet.")
	}

	if p.keyIsDown(control_config.shoot_key) {
		for gun in self.weapon.gun_list {
			if gun.owner_id == particle_index {
				gun.attack(self)
				break
			}
		}
	}

	if(p.keyIsDown((control_config.left_key))){
		self.particle_walk(particle,-1)
	}
	else if(p.keyIsDown((control_config.right_key))){
		self.particle_walk(particle,1)
	}
	else if(!particle.control.jump_state){
		self.particle_stand(particle)
	}
	if(p.keyIsDown((control_config.jump_key))){
		if particle.control.jump_cooldown <= 0 {
			if !particle.control.jump_state { // 如果不在跳跃状态，则开始跳跃
				particle.control.jump_state = true
				particle.control.jump_frame_count = 0  // 重置跳跃帧计数
				particle.control.jump_cooldown = j_dur_A + j_dur_B + j_dur_C  // 总共跳跃帧数
			}
		}
	}
	if(particle.control.jump_cooldown > 0){
		particle.control.jump_cooldown -= 1
	}
	self.particle_jump(particle,0)

}

pub const VIEWPORT_WIDTH : Double = 1920 // 视口宽度
pub const VIEWPORT_HEIGHT : Double = 1080 // 视口高度

pub const Pi : Double = 3.141592653589793

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

fn create_game() -> Game{
	let world = create_world(level=level1,flag=true)
	
	let platform_list=Array::new()
	for body in world.getBodyList() {
		if body.getMass() == 0.0 {
			platform_list.push(body)
		}
	}
	
	for i in platform_list {
		let sh = i.getShapeList()
		for j in sh {
			let t = j.getBase().getFriction()
		}
	}
	
	let weapon=create_weapon_manager()
	
	let anchor_box_def = @box2d.b2BoxDef()
	anchor_box_def.setExtents(@box2d.b2Vec2(0.01, 0.01))
	anchor_box_def.setDensity(0.0)
	let anchor_body_def = @box2d.b2BodyDef()
	anchor_body_def.setPosition(@box2d.b2Vec2(0.0, 0.0))
	anchor_body_def.addShape(anchor_box_def.getBase())
	anchor_body_def.setRotation(0.0)
	anchor_body_def.setAllowSleep(false)
	let anchor = world.createBody(anchor_body_def)
	
	let game = Game::{
		world,
		weapon,
		state: GameRunning,
		particle_list:Array::new(),
		particle_index:0,
		platform_list:Array::new(),
		platform_index:0,
		enemy_list : Array::new(),
		bullet_list : Array::new(),
		item_list : Array::new(),
		frame_count : 0,
		anchor,
		particle_control_configs : Array::new(),
		custom_functions : Array::new()
	}
	game
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
fn Game::create_revolute_joint(
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
fn Game::create_prismatic_joint(
	self :Self,
	body_a: @box2d.B2Body,
	body_b: @box2d.B2Body,
	anchor: (Double, Double),
	axis: @box2d.B2Vec2,
	enable_limit?: Bool=false,
	lower_translation?: Double=-10000.0,
	upper_translation?: Double=10000.0
)-> @box2d.B2Joint{
	let joint_def = @box2d.b2PrismaticJointDef()
	joint_def.setBody1(body_a)
	joint_def.setBody2(body_b)
	joint_def.setAnchorPoint(@box2d.b2Vec2(anchor.0, anchor.1))
	joint_def.setEnableLimit(enable_limit)
	joint_def.setLowerTranslation(lower_translation)
	joint_def.setUpperTranslation(upper_translation)
	joint_def.setAxis(axis)
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