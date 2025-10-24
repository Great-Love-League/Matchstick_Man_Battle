//Platform Entity
pub struct Platform{
	body : @box2d.B2Body
	index : Int
}
pub struct RotatablePlatform{
	mut body : @box2d.B2Body
	index : Int
	angle_speed : Double // 角速度，单位弧度每秒
	mut angle : Double
}
// pub struct MovablePlatform{
// 	fulcrum : @box2d.B2Body
// 	body : @box2d.B2Body
// 	index : Int
// 	start_position : @box2d.B2Vec2
// 	end_position : @box2d.B2Vec2
// 	speed : Double // 移动速度，单位米每秒
// 	direction : Int // 1表示从start到end，-1表示从end到start
// }

// 还需要一个操作 , 探测某个人是否能站在平台上
pub(open) trait PlatformTrait{
	//destroy(Self, game:Game) -> Unit
	update(Self, game:Game) -> Unit
	get_index(Self) -> Int
	get_body(Self) -> @box2d.B2Body
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
		index : game.platform_index
	}
	game.platform_list.push(new)
	game.platform_index += 1
	new
}
pub impl PlatformTrait for Platform with update(self, game) -> Unit {
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
	box_def.setDensity(1.0)
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
		angle : initial_angle
	}
	
	let pos = (body.getCenterPosition().getX(), body.getCenterPosition().getY())

	game.create_joint(game.anchor, body , pos)|> ignore

	game.platform_list.push(new)
	game.platform_index += 1
	new
}

pub impl PlatformTrait for RotatablePlatform with update(self, game) -> Unit {
	let current_angle = self.body.getRotation()
	let new_angle = current_angle + self.angle_speed * (1.0/60.0) // 假设每帧更新一次，60FPS
	self.angle += self.angle_speed * (1.0/60.0)
	println("RotatablePlatform ${self.index} angle: ${self.angle}")
	maintain_rotation(self.body, new_angle,kp=1000.0, kd=100.0)
}

pub impl PlatformTrait for RotatablePlatform with get_index(self) -> Int {
	return self.index
}

pub impl PlatformTrait for RotatablePlatform with get_body(self) -> @box2d.B2Body {
	return self.body
}
