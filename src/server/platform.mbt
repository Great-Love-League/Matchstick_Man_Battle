//Platform Entity
pub struct Platform{
	body : @box2d.B2Body
	index : Int
}
pub struct RotatablePlatform{
	body : @box2d.B2Body
	index : Int
	angle_speed : Double // 角速度，单位弧度每秒
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
	create(game:Game,position:(Double,Double),size:(Double,Double),angle:Double) -> Int
	//destroy(Self, game:Game) -> Unit
	update(Self, game:Game) -> Unit
	get_index(Self) -> Int
	get_body(Self) -> @box2d.B2Body
	
}

// pub create impl 

pub impl PlatformTrait for Platform with create(game,position,size,angle)
->Int {
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

	game.platform_index -1
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