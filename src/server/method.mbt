
pub const VIEWPORT_WIDTH : Double = 1920 // 视口宽度
pub const VIEWPORT_HEIGHT : Double = 1080 // 视口高度

pub const Pi : Double = 3.141592653589793


//return a static box
fn create_static_box(
	world: @box2d.B2World,
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
	let body = world.createBody(body_def)
	body
}

//return a dynamic box
fn create_dynamic_box(
	world: @box2d.B2World,
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
	let body = world.createBody(body_def)
	body
}

//return a joint
fn create_joint(
	world: @box2d.B2World,
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
	let joint = world.createJoint(joint_def.getBase())
	joint
}

fn create_world(
	gravity?: (Double, Double) = (0.0, -9.8)
)-> @box2d.B2World{
	let worldAABB= @box2d.b2AABB()
	worldAABB.setminVertex(@box2d.b2Vec2(-10000.0, -10000.0))
	worldAABB.setmaxVertex(@box2d.b2Vec2(10000.0, 10000.0))
	let world : @box2d.B2World = {world : @box2d.b2World(worldAABB,@box2d.b2Vec2(gravity.0, gravity.1), true)}
	world
}

let platform_index:Ref[Int]=Ref::new(0)
fn create_platform(
	world : @box2d.B2World,
	position: (Double, Double),
	size: (Double, Double)
)-> Platform{
	platform_index.val+=1
	let body = create_static_box(world, position, size)
	let index = platform_index.val-1
	let tmp=Platform::{
		body,
		index
	}
	platform_list.val.push(tmp)
	tmp
}

fn maintain_joint(
	joint: @box2d.B2Joint,
	target_angle: Double,
	kp?:Double=300.0,
	kd?:Double=10.0
)-> Unit {
	let bodyA=joint.toRevoluteJoint().getBody1()
	let bodyB=joint.toRevoluteJoint().getBody2()
	let angle = bodyB.getRotation() - bodyA.getRotation()
	let mut error=target_angle - angle
	//error =(error + Pi) % (2.0 * Pi) - Pi
	let torque=kp*error - kd*(bodyB.getAngularVelocity()-bodyA.getAngularVelocity())
	bodyB.applyTorque(torque)
}

fn maintain_position(
	body: @box2d.B2Body,
	target_pos: (Double, Double),
	kp?:Double=300.0,
	kd?:Double=10.0
)-> Unit {
	let pos=body.getCenterPosition()
	let vel=body.getLinearVelocity()
	let error_x=target_pos.0 - pos.getX()
	let error_y=target_pos.1 - pos.getY()
	let force_x=kp*error_x - kd*vel.getX()
	let force_y=kp*error_y - kd*vel.getY()
	body.applyForce(@box2d.b2Vec2(force_x, force_y), pos)
}

fn maintain_rotation(
	body: @box2d.B2Body,
	target_angle: Double,
	kp?:Double=30.0,
	kd?:Double=10.0
)-> Unit {
	let angle = body.getRotation()
	let mut error=target_angle - angle
	//error =(error + Pi) % (2.0 * Pi) - Pi
	let torque=kp*error - kd*body.getAngularVelocity()
	body.applyTorque(torque)
}

extern "js" fn equals(a:@box2d.B2Body, b:@box2d.B2Body)->Bool=
#|(a,b)=>{return a===b}

fn is_contact(a:@box2d.B2Body, b:@box2d.B2Body)->Bool{
	let contact_list=world.val.getContactList()
	for contact in contact_list {
		let bodyA=contact.getShape1().getBody()
		let bodyB=contact.getShape2().getBody()
		if (equals(bodyA, a) && equals(bodyB, b)) || (equals(bodyA, b) && equals(bodyB, a)) {
			return true
		}
	}
	false
}