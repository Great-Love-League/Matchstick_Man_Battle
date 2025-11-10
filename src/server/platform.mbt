//Platform Entity
pub(all) struct Platform{
	body : @box2d.B2Body
	index : Int
	width : Double   // 半宽度（Box2D 的 extent）
	height : Double  // 半高度（Box2D 的 extent）
	img : ImageLoader
}
pub(all) struct RotatablePlatform{
	body : @box2d.B2Body
	index : Int
	angle_speed : Double // 角速度，单位弧度每秒
	width : Double   // 半宽度（Box2D 的 extent）
	height : Double  // 半高度（Box2D 的 extent）
	mut angle : Double
}
pub(all) struct MovablePlatform{
	fulcrum : @box2d.B2Body
	body : @box2d.B2Body
	now_position : @box2d.B2Vec2
	index : Int
	start_position : @box2d.B2Vec2
	end_position : @box2d.B2Vec2
	speed : Double // 移动速度，单位米每秒
	mut direction : Int // 1表示从start到end，-1表示从end到start
	mut cooldown : Int  // 冷却时间，防止频繁切换方向
	cooldown_time : Int // 冷却时间总长
	width : Double   // 半宽度（Box2D 的 extent）
	height : Double  // 半高度（Box2D 的 extent）
}

pub impl RenderAble for Platform with get_render(platform: Platform){
	// Some(
	// 	fn (world: &@box2d.World, p: &@p5js.P5JS) -> Unit {
	// 		world |> ignore
			
	// 		// 将物理世界的尺寸（半宽度/半高度）转换为屏幕像素尺寸
	// 		// platform.width 和 platform.height 是半宽度和半高度
	// 		// 完整宽度 = width * 2, 完整高度 = height * 2
	// 		let pixel_width = 0.0;
	// 		let pixel_height = 0.0;

	// 		drawBody(p, platform.body, None, pixel_width, pixel_height, 0.0, 0.0)
	// 	}
	// )
	Some(
		fn (world: &@box2d.World, p: &@p5js.P5JS) -> Unit {
			world |> ignore
			
			// 使用 PlatformTrait 获取物理世界的宽度和高度（单位：米）
			let width_meters = platform.get_width()
			let height_meters = platform.get_height()
			
			// 使用 world_to_screen_size 转换为屏幕像素
			// PPM (Pixels Per Meter) 是转换比例
			let pixel_width = world_to_screen_size(width_meters, PPM)
			let pixel_height = world_to_screen_size(height_meters, PPM)
			
			debugln("Drawing Platform \{platform.get_index()} with pixel size (\{pixel_width}, \{pixel_height})", prio=11)
			
			drawBody(p, platform.body, platform.img.get_image(p), pixel_width, pixel_height, 0.0, 0.0)
		}
	)
}

pub impl RenderAble for RotatablePlatform with get_render(rotatable_platform: RotatablePlatform){
	Some(fn (world: &@box2d.World, p: &@p5js.P5JS) -> Unit {
		world|> ignore
		for shape in rotatable_platform.get_body().getShapeList() {
		// debugln("Drawing RotatablePlatform \{rotatable_platform.get_index()}")
			match shape.getType() {
				PolygonShape => drawPolygon(p, shape.toPolygonShape())
				BoxShape => drawPolygon(p, shape.toPolygonShape())
				CircleShape => drawCircle(p, shape.toCircleShape())
				UnknownShape => {
					debugln("Unknown Shape")
				}
			}
		}
	})
}

pub impl RenderAble for MovablePlatform with get_render(movable_platform: MovablePlatform){
	Some(fn (world: &@box2d.World, p: &@p5js.P5JS) -> Unit {

		world |> ignore

		for shape in movable_platform.get_body().getShapeList() {
		// debugln("Drawing MovablePlatform \{movable_platform.get_index()}")
			match shape.getType() {
				PolygonShape => drawPolygon(p, shape.toPolygonShape())
				BoxShape => drawPolygon(p, shape.toPolygonShape())
				CircleShape => drawCircle(p, shape.toCircleShape())
				UnknownShape => {
					debugln("Unknown Shape")
				}
			}
		}
	})
}

// 还需要一个操作 , 探测某个人是否能站在平台上
pub(open) trait PlatformTrait : RenderAble{
	//destroy(Self, game:Game) -> Unit
	update(Self, game:Game) -> Unit
	get_index(Self) -> Int
	get_body(Self) -> @box2d.B2Body
	get_height(Self) -> Double 
	get_width(Self) -> Double 
	get_rotation(Self) -> Double = _
}

pub impl PlatformTrait for Platform with get_width(self) -> Double {
	return self.width
}
pub impl PlatformTrait for Platform with get_height(self) -> Double {
	return self.height
}
pub impl PlatformTrait for RotatablePlatform with get_width(self) -> Double {
	return self.width
}
pub impl PlatformTrait for RotatablePlatform with get_height(self) -> Double {
	return self.height
}
pub impl PlatformTrait for MovablePlatform with get_width(self) -> Double {
	return self.width
}
pub impl PlatformTrait for MovablePlatform with get_height(self) -> Double {
	return self.height
}


impl PlatformTrait with get_rotation(self) -> Double {
	return self.get_body().getRotation()
}

pub fn create_platform(game:Game,position:(Double,Double),size:(Double,Double),angle?:Double=0.0)
->Platform {
	let box_def = @box2d.b2BoxDef()
	box_def.setExtents(@box2d.b2Vec2(size.0, size.1))
	box_def.setDensity(0.0)
	let body_def = @box2d.b2BodyDef()
	body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
	body_def.addShape(box_def.getBase())
	body_def.setRotation(angle)
	body_def.setAllowSleep(false)
	let new = Platform::{
		body : game.world.createBody(body_def),
		index : game.platform_index,
		width : size.0,
		height : size.1,
		img : ImageLoader::new(Some("src/assets/platform1.png"))
	}
	// new.body.getShapeList()[0].getBase().getRestitution
	game.platform_list.push(new)
	game.platform_index += 1
	new
}

pub impl PlatformTrait for Platform with update(self, game) -> Unit {
	self |> ignore
	game |> ignore
	// 静止平台不需要更新
}
pub impl PlatformTrait for Platform with get_index(self) -> Int {
	return self.index
}
pub impl PlatformTrait for Platform with get_body(self) -> @box2d.B2Body {
	return self.body
}
pub fn create_rotatable_platform(game:Game,position:(Double,Double),size:(Double,Double),angle_speed:Double,initial_angle?:Double=0.0) -> RotatablePlatform {
	let box_def = @box2d.b2BoxDef()
	box_def.setExtents(@box2d.b2Vec2(size.0, size.1))
	box_def.setDensity(50.0)
	let body_def = @box2d.b2BodyDef()
	body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
	body_def.addShape(box_def.getBase())
	body_def.setRotation(initial_angle)
	body_def.setAllowSleep(false)
	let body = game.world.createBody(body_def)
	let new = RotatablePlatform::{
		body,
		index : game.platform_index,
		angle_speed : angle_speed,
		angle : initial_angle,
		width : size.0,
		height : size.1
	}
	
	let pos = (body.getCenterPosition().getX(), body.getCenterPosition().getY())

	game.create_revolute_joint(game.anchor, body , pos)|> ignore

	game.platform_list.push(new)
	game.platform_index += 1
	new
}

pub impl PlatformTrait for RotatablePlatform with update(self, game) -> Unit {

	game |> ignore

	let current_angle = self.body.getRotation()
	let new_angle = current_angle + self.angle_speed * (1.0/60.0) // 假设每帧更新一次，60FPS
	self.angle += self.angle_speed * (1.0/60.0)
	// debugln("RotatablePlatform ${self.index} angle: ${self.angle}")
	maintain_rotation(self.body, new_angle,kp=100000.0, kd=10000.0)
}

pub impl PlatformTrait for RotatablePlatform with get_index(self) -> Int {
	return self.index
}

pub impl PlatformTrait for RotatablePlatform with get_body(self) -> @box2d.B2Body {
	return self.body
}


pub fn create_movable_platform(game:Game, size:(Double,Double), start_position:(Double,Double), end_position:(Double,Double), speed:Double, now_position:(Double,Double)) -> MovablePlatform {
	let box_def = @box2d.b2BoxDef()
	box_def.setExtents(@box2d.b2Vec2(size.0, size.1))
	box_def.setDensity(50.0)
	let body_def = @box2d.b2BodyDef()
	body_def.setPosition(@box2d.b2Vec2(now_position.0, now_position.1))
	body_def.addShape(box_def.getBase())
	body_def.setRotation(0.0)
	body_def.setAllowSleep(false)
	let body = game.world.createBody(body_def)
	
	let to_target = @box2d.b2Vec2(end_position.0 - start_position.0, end_position.1 - start_position.1)
	let cooldown_time = ((to_target.length() / speed) ).to_int() // 转换为帧数，假设60FPS
	
	
	let new = MovablePlatform::{
		fulcrum : game.anchor,
		body,
		index : game.platform_index,
		start_position : @box2d.b2Vec2(start_position.0, start_position.1),
		end_position : @box2d.b2Vec2(end_position.0, end_position.1),
		now_position : @box2d.b2Vec2(now_position.0, now_position.1),
		speed,
		direction : 1,
		cooldown : cooldown_time,
		cooldown_time,
		width : size.0,
		height : size.1
	}
	// let axis = @box2d.b2Vec2(end_position.0 - start_position.0, end_position.1 - start_position.1)
	//game.create_prismatic_joint(game.anchor, body, (0.0, 0.0), axis, enable_limit=true, lower_translation=0.0, upper_translation=5.0)|> ignore
	
	game.platform_list.push(new)
	game.platform_index += 1
	
	new
}

pub impl PlatformTrait for MovablePlatform with update(self, game) -> Unit {

	game |> ignore
	
	self.body.applyForce(@box2d.b2Vec2(0.0, 9.8*self.body.getMass()), self.body.getCenterPosition())
	// debugln("rotation")
	maintain_rotation(self.body, 0.0, kp=100000.0, kd=10000.0)
	
	let current_pos = self.body.getCenterPosition()
	let target_pos = if self.direction == 1 { self.end_position } else { self.start_position }
	let to_target = @box2d.b2Vec2(target_pos.getX() - current_pos.getX(), target_pos.getY() - current_pos.getY())
	let distance = to_target.length()
	
	// debugln("\{self.direction} \{self.cooldown} \{distance}")
	self.cooldown -= 1
	
	if distance < 0.1 && self.cooldown<0 {
		// 到达目标点，切换方向
		self.direction *= -1
		self.cooldown = self.cooldown_time // 设置冷却时间，防止频繁切换
	} else {
		let move_distance = self.speed * (1.0/60.0)
		let move_vector = to_target
		let len=move_vector.length()
		move_vector.setX(move_vector.getX() * move_distance/len )
		move_vector.setY(move_vector.getY() * move_distance/len )
		let new_pos = @box2d.b2Vec2(current_pos.getX() + move_vector.getX(), current_pos.getY() + move_vector.getY())
		
		//debugln("MovablePlatform \{self.index} position: (\{new_pos.getX()}, \{new_pos.getY()})")
		
		maintain_position(self.body,(new_pos.getX(), new_pos.getY()), kp=1000000.0, kd=5000.0)
	}
}

pub impl PlatformTrait for MovablePlatform with get_index(self) -> Int {
	return self.index
}
pub impl PlatformTrait for MovablePlatform with get_body(self) -> @box2d.B2Body {
	return self.body
}