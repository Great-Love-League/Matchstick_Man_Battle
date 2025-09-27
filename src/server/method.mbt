
pub const VIEWPORT_WIDTH : Double = 1920 // 视口宽度
pub const VIEWPORT_HEIGHT : Double = 1080 // 视口高度
pub const PPM = 20.0

pub const Pi : Double = 3.141592653589793

fn world_to_screen(world_x : Double, world_y : Double) -> (Double, Double) {
  let screen_x : Double = world_x * PPM
  let screen_y : Double = world_y * PPM
  (screen_x,-screen_y+VIEWPORT_HEIGHT)
}

///|
fn screen_to_world(screen_x : Double, screen_y : Double) -> (Double, Double) {
  let world_x : Double = screen_x / PPM
  let world_y : Double = (VIEWPORT_HEIGHT - screen_y) / PPM
  (world_x, world_y)
}

fn world_to_screen_siz(world_x : Double, world_y : Double) -> (Double, Double) {
  let screen_x : Double = world_x * PPM
  let screen_y : Double = world_y * PPM
  (screen_x,screen_y)
}

fn screen_to_world_siz(screen_x : Double, screen_y : Double) -> (Double, Double) {
  let world_x : Double = screen_x / PPM
  let world_y : Double = screen_y / PPM
  (world_x, world_y)
}


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
	let world=@box2d.b2World(worldAABB,@box2d.b2Vec2(gravity.0, gravity.1), true)
	world
}

//return a particle and its index in the particle system
let particle_index:Ref[Int]=Ref::new(0)
fn create_particle(
	world: @box2d.B2World,
	position: (Double, Double)
)-> Particle {
	particle_index.val+=1
	let torso = create_dynamic_box(world, position,(0.25,1.0),density=1.0,groupindex=-1)
	let head = create_dynamic_box(world, (position.0, position.1+1.5),(0.2,0.25),density=1.0,groupindex=-1)
	let left_thigh = create_dynamic_box(world, (position.0, position.1-1),(0.15,0.5),density=1.0,groupindex=-1)
	let right_thigh = create_dynamic_box(world, (position.0, position.1-1),(0.15,0.5),density=1.0,groupindex=-1)
	let left_shank = create_dynamic_box(world, (position.0, position.1-2),(0.15,0.5),density=1.0,groupindex=-1)
	let right_shank = create_dynamic_box(world, (position.0, position.1-2),(0.15,0.5),density=1.0,groupindex=-1)
	let neck_joint = create_joint(world, torso, head, (position.0, position.1+1.0),enable_limit=true,lower_angle=0.0,upper_angle=0.0)
	let thigh_left_joint = create_joint(world, torso, left_thigh, (position.0, position.1-0.5),enable_limit=true,lower_angle=-1.0,upper_angle=1.0)
	let thigh_right_joint = create_joint(world, torso, right_thigh, (position.0, position.1-0.5),enable_limit=true,lower_angle=-1.0,upper_angle=1.0)
	let knee_left_joint = create_joint(world, left_thigh, left_shank, (position.0, position.1-1.5),enable_limit=true,lower_angle=-1.3,upper_angle=1.3)
	let knee_right_joint = create_joint(world, right_thigh, right_shank, (position.0, position.1-1.5),enable_limit=true,lower_angle=-1.3,upper_angle=1.3)
	let index= particle_index.val
	Particle::{
    torso,
    head,
    left_thigh,
    right_thigh,
    left_shank,
    right_shank,
    thigh_left_joint,
    thigh_right_joint,
    knee_left_joint,
    knee_right_joint,
    neck_joint,
		index,
		walk_state:false,
		cooldown:0
	}
}

let platform_index:Ref[Int]=Ref::new(0)
fn create_platform(
	world : @box2d.B2World,
	position: (Double, Double),
	size: (Double, Double)
)-> Platform{
	platform_index.val+=1
	let body = create_static_box(world, position, size)
	let index = platform_index.val
	Platform::{
		body,
		index
	}
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
	error =(error + Pi) % (2.0 * Pi) - Pi
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
	kp?:Double=300.0,
	kd?:Double=10.0
)-> Unit {
	let angle = body.getRotation()
	let mut error=target_angle - angle
	error =(error + Pi) % (2.0 * Pi) - Pi
	let torque=kp*error - kd*body.getAngularVelocity()
	body.applyTorque(torque)
}

fn maintain_torso(
	particle: Particle,
	target_angle: Double,
	target_pos: (Double, Double)
)-> Unit {
	maintain_rotation(particle.torso, target_angle)
	maintain_position(particle.torso, target_pos)
}

pub extern "js" fn op_equal(a:@box2d.B2Body, b:@box2d.B2Body)->Bool=
	#| (a, b) => a===b

fn which_platform(
	particle: Particle
)->Int{
	let contact_list=world.val.getContactList()
	for contact in contact_list {
		let bodyA=contact.getShape1().getBody()
		let bodyB=contact.getShape2().getBody()
		if(op_equal(bodyA, particle.left_shank)||
			op_equal(bodyA, particle.right_shank)){
			for platform in platform_list.val {
				if(op_equal(bodyB, platform.body)){
					return platform.index
				}
			}
		}
		if(op_equal(bodyB, particle.left_shank)||
			op_equal(bodyB, particle.right_shank)){
			for platform in platform_list.val {
				if(op_equal(bodyA, platform.body)){
					return platform.index
				}
			}
		}
	}
	-1
}
let knee_angle : Double = 63.0 / 180.0 * Pi
let thigh_angle_forward = 0.5
let thigh_angle_backward = -0.5
fn walk(
	particle: Particle,
	direction: Double
)->Unit{
	let index=which_platform(particle)
	if(index==-1){
		return 
	}
	let platform=platform_list.val[index]
	
	let p_angle=platform.body.getRotation()

	let target_y=(
		particle.torso.getCenterPosition().getX()-platform.body.getCenterPosition().getX()
	)*@cmath.tan(p_angle)+platform.body.getCenterPosition().getY()
	
	maintain_position(particle.torso,(particle.torso.getCenterPosition().getX(),target_y+3.0))
	maintain_rotation(particle.torso, p_angle*0.7)
	
	let mut left_target :Double=0.0
	let mut right_target :Double=0.0
	if particle.walk_state {
		left_target = thigh_angle_backward
		right_target = thigh_angle_forward
	}
	else {
		left_target = thigh_angle_forward
		right_target = thigh_angle_backward
	}
	
	maintain_joint(particle.thigh_left_joint, left_target + p_angle*0.7)
	maintain_joint(particle.thigh_right_joint, right_target + p_angle*0.7)
	maintain_joint(particle.knee_left_joint, -knee_angle*direction,kp=300.0,kd=10.0)
	maintain_joint(particle.knee_right_joint, -knee_angle*direction,kp=300.0,kd=10.0)
	if particle.cooldown<=0{
		particle.walk_state = !particle.walk_state
		particle.cooldown=10
	}
	else{
		particle.cooldown-=1
	}
}
//这里缺少了走路停下的阻尼,和站稳的阻尼
fn stand(
	particle: Particle
)->Unit{
	let index=which_platform(particle)
	if(index==-1){
		return 
	}
	let platform=platform_list.val[index]
	
	let p_angle=platform.body.getRotation()

	let target_y=(
		particle.torso.getCenterPosition().getX()-platform.body.getCenterPosition().getX()
	)*@cmath.tan(p_angle)+platform.body.getCenterPosition().getY()
	
	maintain_position(particle.torso,(particle.torso.getCenterPosition().getX(),target_y+3.0))
}

//这里缺少了跳跃的动作
fn jump(
	particle: Particle,
	force: Double
)->Unit{
	let index=which_platform(particle)
	if(index==-1){
		return 
	}
	let platform=platform_list.val[index]
	
	let p_angle=platform.body.getRotation()

	let target_y=(
		particle.torso.getCenterPosition().getX()-platform.body.getCenterPosition().getX()
	)*@cmath.tan(p_angle)+platform.body.getCenterPosition().getY()
	
	maintain_position(particle.torso,(particle.torso.getCenterPosition().getX(),target_y+3.0))
	particle.torso.applyImpulse(@box2d.b2Vec2(0.0,force), particle.torso.getCenterPosition())
}