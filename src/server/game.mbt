struct Game {
	world : @box2d.B2World
	mut particle_list:Array[Particle]
	mut particle_index:Int
	
	mut platform_list:Array[Platform]
	mut platform_index:Int
	
	mut enemy_list : Array[&EnemyTrait?]
}
fn create_game() -> Game{
	let world = create_world()
	let game = Game::{
		world,
		particle_list:Array::new(),
		particle_index:0,
		platform_list:Array::new(),
		platform_index:0,
		enemy_list : Array::new(),
	}
	game
}


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