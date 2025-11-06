pub suberror ParticleControlConfigError String
pub suberror GameStateError String

pub(all) struct Game {
	world : @box2d.B2World
	weapon : WeaponManager
	render : &RenderTrait
	mut state : GameState
	mut particle_list:Array[Particle]
	mut particle_index:Int
	
	mut platform_list:Array[&PlatformTrait]
	mut platform_index:Int
	
	mut enemy_list : Array[&EnemyTrait?]
	
	mut bullet_list : Array[Bullet]
	mut item_list : Array[Item]
	mut frame_count : Int

	// 时间控制（两档：正常 / 1/4 速度）
	mut slow_mode : Bool

	// 窗口振动（屏幕抖动）
	mut shake_timer : Int
	mut shake_duration : Int
	mut shake_magnitude : Double

	// 玩家控制配置列表
	mut particle_control_configs : Array[ParticleControlConfig]

	// 自定义函数列表
	mut custom_functions : Array[&GameCustomFunctionTrait]
	
	// 自动瞄准配置列表（每个玩家一个配置）
	mut auto_aim_configs : Array[AutoAimConfig]

	mut animation_list : Array[&Animation]
	
	// 音频管理器
	audio : AudioManager
	
	anchor : @box2d.B2Body
}

// pub trait renderable 用于每个可渲染对象的渲染接口，如果没有设置则使用 render 的默认实现
pub trait RenderAble {
	get_render(self: Self) -> Option[(&@box2d.World, &@p5js.P5JS) -> Unit] = _
}

impl RenderAble with get_render(self: Self) -> Option[(&@box2d.World, &@p5js.P5JS) -> Unit] {
	self |> ignore
	None
}

pub trait GameCustomFunctionTrait {
	call_custom_function(self: Self, game: Game, p5: &@p5js.P5JS) -> Unit
	get_call_stage(self: Self) -> GameState
}

pub(all) enum AnimationState {
	NotStarted
	InProgress
	Completed
}

trait Animation {
	///| 动画更新函数，如果返回Completed则表示动画结束，反之则继续进行
	update(self: Self, world: &@box2d.World, p5: &@p5js.P5JS) -> AnimationState
}


pub(all) struct GameCustomFunction {
	stage : GameState
	func : (Game, &@p5js.P5JS) -> Unit
}

pub fn GameCustomFunction::new(
	stage : GameState,
	func : (Game, &@p5js.P5JS) -> Unit
) -> Self {
	GameCustomFunction::{
		stage,
		func
	}
}

pub impl GameCustomFunctionTrait for GameCustomFunction with call_custom_function(self, game: Game, p5: &@p5js.P5JS) -> Unit {
		(self.func)(game, p5)
}

pub impl GameCustomFunctionTrait for GameCustomFunction with get_call_stage(self) -> GameState {
		self.stage
}


///| 玩家控制配置结构体
pub(all) struct ParticleControlConfig {
	from_internet : Bool

	left_key : @p5js.KeyCode
	right_key : @p5js.KeyCode
	jump_key : @p5js.KeyCode
	shoot_key : @p5js.KeyCode
	faint_key : @p5js.KeyCode
	toggle_auto_aim_key : @p5js.KeyCode  // 切换自动瞄准的按键

	target_ip : String
	target_port : Int
	target_particle_index : Int
}

pub fn ParticleControlConfig::new(
	target_particle_index : Int,
	left_key~ : @p5js.KeyCode? = Some(KeyA),
	right_key~ : @p5js.KeyCode? = Some(KeyD),
	jump_key~ : @p5js.KeyCode? = Some(KeyW),
	faint_key~ : @p5js.KeyCode? = Some(KeyS),
	shoot_key~ : @p5js.KeyCode? = Some(KeyZ),
	toggle_auto_aim_key~ : @p5js.KeyCode? = Some(KeyT),  // 默认使用T键
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
			faint_key: @p5js.UnknownKey,
			toggle_auto_aim_key: @p5js.UnknownKey,
			target_ip: target_ip.unwrap(),
			target_port: target_port.unwrap(),
			target_particle_index,
		}

	}

	if from_internet == false {
		// 检查必要参数
		if left_key == None || right_key == None || jump_key == None || shoot_key == None || toggle_auto_aim_key == None {
			println("Error: Missing key bindings for local control.")
			raise ParticleControlConfigError("Missing key bindings for local control.")
		}
		return ParticleControlConfig::{
			from_internet,
			left_key: left_key.unwrap(),
			right_key: right_key.unwrap(),
			jump_key: jump_key.unwrap(),
			shoot_key: shoot_key.unwrap(),
			faint_key: faint_key.unwrap(),
			toggle_auto_aim_key: toggle_auto_aim_key.unwrap(),
			target_ip: "",
			target_port: 0,
			target_particle_index,
		}
	}

	raise ParticleControlConfigError("Unknown error in ParticleControlConfig::new")

}

///| 游戏状态
pub(all) enum GameState {
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

///| 注册自动瞄准配置
/// @param player_id 玩家索引
/// @param config 自动瞄准配置
pub fn Game::register_auto_aim_config(
	self : Self, 
	player_id : Int, 
	config : AutoAimConfig
) -> Unit {
	// 确保数组足够大
	while self.auto_aim_configs.length() <= player_id {
		self.auto_aim_configs.push(AutoAimConfig::new())
	}
	self.auto_aim_configs[player_id] = config
}

///| 获取玩家的自动瞄准配置
pub fn Game::get_auto_aim_config(self : Self, player_id : Int) -> AutoAimConfig? {
	if player_id >= 0 && player_id < self.auto_aim_configs.length() {
		return Some(self.auto_aim_configs[player_id])
	}
	return None
}

///| 切换自动瞄准开关
pub fn Game::toggle_auto_aim(self : Self, player_id : Int) -> Unit {
	match self.get_auto_aim_config(player_id) {
		Some(config) => config.set_enabled(not(config.enabled))
		None => ()
	}
}

fn Game::run_custom_functions(self:Self, stage:GameState, p5: &@p5js.P5JS) -> Unit {
	for func in self.custom_functions {
		if func.get_call_stage() == stage {
			func.call_custom_function(self, p5)
		}
	}
}

fn Game::state_machine_update(self:Self, p5: &@p5js.P5JS) -> Unit {
	self.render.clear_screen(self.world, p5)
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
	self.render.render(self, p5)
}

fn Game::prepare(self:Self, p5: &@p5js.P5JS) -> Unit {
	self.run_custom_functions(GamePreparing, p5)
	self.state = GameRunning
}

fn Game::pause(self:Self, p5: &@p5js.P5JS) -> Unit {
	self.run_custom_functions(GamePaused, p5)
	self.state = GameRunning
}

fn Game::running(self:Self, p5: &@p5js.P5JS) -> Unit {

	self.frame_count += 1

	// 全局按键：
	// 按 8 触发屏幕振动；按 9 减速；按 0 加速。
	// 使用 frame_count 做简单节流，避免按下时瞬间多次变化。
	if p5.keyIsDown(@p5js.Digit8) {
		self.shake_timer = self.shake_duration
	}

	// 按 9 切换到 1/4 速（只在每 4 帧步进一次物理）
	// if p5.keyIsDown(@p5js.Digit9) {
	// 	if self.frame_count % 10 == 0 {
	// 		self.slow_mode = true
	// 		println("切换到 1/4 时间模式")
	// 	}
	// }

	// // 按 0 切换回正常速度
	// if p5.keyIsDown(@p5js.Digit0) {
	// 	if self.frame_count % 10 == 0 {
	// 		self.slow_mode = false
	// 		println("切换到正常时间模式")
	// 	}
	// }

	// 如果处于慢速模式，则只在每 4 的倍数帧执行完整的游戏更新逻辑（包括物理步进）
	let do_tick = true

	if do_tick {

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

	// 更新敌人系统
	for enemy_opt in self.enemy_list {
		match enemy_opt {
			Some(enemy) => enemy.update(self)
			None => ()
		}
	}
	
	// 更新自动瞄准系统（为每个玩家更新目标）
	for i = 0; i < self.auto_aim_configs.length(); i = i + 1 {
		self.update_auto_aim_target(i, self.auto_aim_configs[i])
	}
	
	// 每60帧清理一次
	if self.frame_count % 60 == 0 {
		self.cleanup_bullets()
		self.cleanup_items()
	}
	
	// 保证玩家血量不低于0
	for particle in self.particle_list {
		if particle.control.health < 0 {
			particle.control.health = 0
		}
	}

		// 更新敌人系统
		for enemy_opt in self.enemy_list {
			match enemy_opt {
				Some(enemy) => enemy.update(self)
				None => ()
			}
		}
		
		// 更新自动瞄准系统（为每个玩家更新目标）
		for i = 0; i < self.auto_aim_configs.length(); i = i + 1 {
			self.update_auto_aim_target(i, self.auto_aim_configs[i])
		}
		
		// 每60帧清理一次（基于全局 frame_count）
		if self.frame_count % 60 == 0 {
			self.cleanup_bullets()
			self.cleanup_items()
		}
			
		for i in self.weapon.gun_list {
			maintain_rotation(i.body, 0, kp=2.0, kd=2.0)
		}
		// 物理步进
	}
	
	
	
	if(self.slow_mode){
			println("1/4 速模式：物理步进")
		self.world.step(1.0/60.0/4.0, 4)
		}
		else{
			self.world.step(1.0/60.0, 4)
		}
		self.run_custom_functions(GameRunning, p5)

		// 更新动画系统
		self.update_animations(p5)

	// 振动计时器每帧递减（即使在慢速下也要每帧表现抖动）
	if self.shake_timer > 0 {
		self.shake_timer = self.shake_timer - 1
	}

	// 如果有玩家死亡，则切换到游戏结束状态
	for i in self.particle_list {
		if i.control.health <= 0 {
			self.state = GameOver
			return
		}
	}

	self.state = GameRunning
}

fn Game::game_over(self:Self, p5: &@p5js.P5JS) -> Unit {
	self.run_custom_functions(GameOver, p5)

	// 画一个简单的游戏结束画面
	// 找出获胜者（血量大于0的玩家）
	let mut winner_index = -1
	for i = 0; i < self.particle_list.length(); i = i + 1 {
		if self.particle_list[i].control.health > 0 {
			winner_index = i
			break
		}
	}
	
	// 显示半透明背景
	p5.fillColorPara(0.0, Some(0.0), Some(0.0), Some(180.0))
	p5.noStroke()
	p5.rect(0.0, 0.0, VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	
	// 显示游戏结束文字
	p5.textSizeSet(80.0)
	p5.fillColorPara(255.0, Some(255.0), Some(255.0), Some(255.0))
	p5.textAlign("center", Some("center"))
	p5.text("游戏结束", VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0 - 80.0, None, None)
	
	// 显示获胜者
	if winner_index >= 0 {
		p5.textSizeSet(60.0)
		p5.fillColorPara(255.0, Some(215.0), Some(0.0), Some(255.0))  // 金色
		p5.text("玩家 \{winner_index} 获胜!", VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0, None, None)
	} else {
		p5.textSizeSet(60.0)
		p5.fillColorPara(200.0, Some(200.0), Some(200.0), Some(255.0))
		p5.text("平局", VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0, None, None)
	}
	
	// 显示提示文字
	p5.textSizeSet(30.0)
	p5.fillColorPara(255.0, Some(255.0), Some(255.0), Some(255.0))
	p5.text("刷新页面重新开始", VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0 + 80.0, None, None)

	self.state = GameOver
}

///| 重构后的玩家移动函数
fn Game::particle_control(self:Self, control_config: ParticleControlConfig, p : &@p5js.P5JS) -> Unit raise{

	let particle_index = control_config.target_particle_index
	if particle_index < 0 || particle_index >= self.particle_list.length() {
		println("Error: Invalid target_particle_index \{particle_index} in particle_control.")
		raise GameStateError("Invalid target_particle_index in particle_control. want to control \{particle_index}, but only \{self.particle_list.length()} particles exist.")
	}
	let particle = self.particle_list[particle_index]

	if control_config.from_internet {
		raise GameStateError("Internet control not implemented yet.")
	}

	// 检查自动瞄准切换键（使用cooldown避免重复触发）
	if p.keyIsDown(control_config.toggle_auto_aim_key) {
		if self.frame_count % 30 == 0 {  // 每半秒最多切换一次
			self.toggle_auto_aim(particle_index)
			match self.get_auto_aim_config(particle_index) {
				Some(config) => {
					if config.enabled {
						println("玩家 \{particle_index}: 自动瞄准已启用")
					} else {
						println("玩家 \{particle_index}: 自动瞄准已禁用")
					}
				}
				None => ()
			}
		}
	}
	
	// for gun in self.weapon.gun_list {
	// 	if gun.owner_id == self.particle_index {
	// 		// 若玩家有多把枪，只调整第一把匹配到的武器
	// 		println("自动瞄准调整武器朝向至角度：\{0}")
	// 		maintain_rotation(gun.body, 0, kp=200.0, kd=20.0)
	// 		break
	// 	}
	// }
	
	if p.keyIsDown(control_config.shoot_key) {
		for gun in self.weapon.gun_list {
			if gun.owner_id == particle_index {
				// 检查是否启用自动瞄准
				match self.get_auto_aim_config(particle_index) {
					Some(config) => {
						if config.enabled {
							// 使用自动瞄准角度攻击
							match self.get_auto_aim_angle(particle_index, config) {
								Some(angle) => gun.attack_at_angle(self, angle)
								None => gun.attack(self)  // 没有目标时使用默认攻击
							}
						} else {
							gun.attack(self)  // 未启用自动瞄准时使用默认攻击
						}
					}
					None => gun.attack(self)  // 没有配置时使用默认攻击
				}
				break
			}
		}
		// 近战武器
		for sword in self.weapon.sword_list {
			if sword.owner_id == particle_index {
				sword.attack(self)
				break
			}
		}
	}
	if(p.keyIsDown(control_config.faint_key)){
		return
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

pub const VIEWPORT_WIDTH : Double = Width // 视口宽度
pub const VIEWPORT_HEIGHT : Double = Height // 视口高度

pub const Pi : Double = 3.141592653589793

pub fn Game::create_static_box(
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

pub fn create_game(render~: &RenderTrait = DefaultRenderable::{}) -> Game{
	let world = create_world()
	
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
	
	// 创建并初始化音频管理器
	let audio = AudioManager::new()
	audio.init_audio_configs()
	
	let game = Game::{
		world,
		weapon,
		render,
			state: GameRunning,
		particle_list:Array::new(),
		particle_index:0,
		platform_list:Array::new(),
		platform_index:0,
		enemy_list : Array::new(),
		bullet_list : Array::new(),
		item_list : Array::new(),
			frame_count : 0,

			// 默认正常速度
			slow_mode: false,

			// shake defaults
			shake_timer: 0,
			shake_duration: 15,
			shake_magnitude: 8.0,
		anchor,
		particle_control_configs : Array::new(),
		custom_functions : Array::new(),
		auto_aim_configs : Array::new(),
		animation_list : Array::new(),
		audio
	}
	
	game
}

pub fn Game::create_dynamic_box(
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
pub fn Game::create_revolute_joint(
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
pub fn Game::create_prismatic_joint(
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
pub fn Game::is_contact(self:Self,a:@box2d.B2Body, b:@box2d.B2Body)->Bool{
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

pub fn Game::who_shape_belongs_to(self:Self, shape:@box2d.B2Shape) -> (Int) {
	let father = shape.getBody()
	for i = 0; i < self.particle_list.length(); i = i + 1 {
		let particle = self.particle_list[i]

		if equals(particle.head, father) {
			return i
		}
		if equals(particle.left_arm, father) {
			return i
		}
		if equals(particle.right_arm, father) {
			return i
		}
		if equals(particle.torso, father) {
			return i
		}
		if equals(particle.left_forearm, father) {
			return i
		}
		if equals(particle.right_forearm, father) {
			return i
		}
		if equals(particle.right_thigh, father) {
			return i
		}
		if equals(particle.right_shank, father) {
			return i
		}
		if equals(particle.left_thigh, father) {
			return i
		}
		if equals(particle.left_shank, father) {
			return i
		}
	}
	return -1
}

fn Game::update_animations(self:Self, p5: &@p5js.P5JS) -> Unit {

	let animations_state = Array::new()
	for animation in self.animation_list {
		let state = animation.update(self.world, p5)
		animations_state.push(state)
	}
	// 移除已完成的动画
	let rest_animations = Array::new()
	for i = 0; i < self.animation_list.length(); i = i + 1 {
		match animations_state[i] {
			AnimationState::Completed => ()
			AnimationState::InProgress => rest_animations.push(self.animation_list[i])
			AnimationState::NotStarted => rest_animations.push(self.animation_list[i])
		}
	}
	self.animation_list = rest_animations
}

pub fn Game::add_animation(self:Self, animation: &Animation) -> Unit {
	self.animation_list.push(animation)
}

// 开始游戏运行，不阻塞
pub fn Game::start_run(self:Self) -> Unit {
	self.state = GamePreparing
	getP5Instance(fn(p : @p5js.P5Instance) -> Unit {
		self.state_machine_update(p)
	}) |> ignore
}