
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
fn create_particle_control(
	walk_state?: Bool=false,
	walk_cooldown?: Int=0,
	jump_cooldown?: Int=-1,
	jump_state?: Bool=false,
	jump_frame_count?: Int=0
) -> ParticleControl{
	ParticleControl::{
		walk_state,
		walk_cooldown,
		jump_cooldown,
		jump_state,
		jump_frame_count
	}
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
	let left_shank = create_dynamic_box(world, (position.0, position.1-2),(0.15,0.5),density=1.0,groupindex=-1,friciton=0.8)
	let right_shank = create_dynamic_box(world, (position.0, position.1-2),(0.15,0.5),density=1.0,groupindex=-1,friciton=0.8)
	let neck_joint = create_joint(world, torso, head, (position.0, position.1+1.0),enable_limit=true,lower_angle=0.0,upper_angle=0.0)
	let thigh_left_joint = create_joint(world, torso, left_thigh, (position.0, position.1-0.5),enable_limit=true,lower_angle=-1.0,upper_angle=1.0)
	let thigh_right_joint = create_joint(world, torso, right_thigh, (position.0, position.1-0.5),enable_limit=true,lower_angle=-1.0,upper_angle=1.0)
	let knee_left_joint = create_joint(world, left_thigh, left_shank, (position.0, position.1-1.5),enable_limit=true,lower_angle=-1.3,upper_angle=1.3)
	let knee_right_joint = create_joint(world, right_thigh, right_shank, (position.0, position.1-1.5),enable_limit=true,lower_angle=-1.3,upper_angle=1.3)
	let left_arm = create_dynamic_box(world, (position.0, position.1+0.5),(0.15,0.5),density=1.0,groupindex=-1)
	let right_arm = create_dynamic_box(world, (position.0, position.1+0.5),(0.15,0.5),density=1.0,groupindex=-1)
	let left_forearm = create_dynamic_box(world, (position.0, position.1-0.25),(0.15,0.5),density=1.0,groupindex=-1)
	let right_forearm = create_dynamic_box(world, (position.0, position.1-0.25),(0.15,0.5),density=1.0,groupindex=-1)
	let arm_left_joint = create_joint(world, torso, left_arm, (position.0, position.1+1),enable_limit=true,lower_angle=-1.0,upper_angle=1.0)
	let arm_right_joint = create_joint(world, torso, right_arm, (position.0, position.1+1),enable_limit=true,lower_angle=-1.0,upper_angle=1.0)
	let forearm_left_joint = create_joint(world, left_arm, left_forearm, (position.0, position.1),enable_limit=true,lower_angle=-1.3,upper_angle=1.3)
	let forearm_right_joint = create_joint(world, right_arm, right_forearm, (position.0, position.1),enable_limit=true,lower_angle=-1.3,upper_angle=1.3)
	let index= particle_index.val-1
	let tmp=Particle::{
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
		left_forearm,
		right_forearm,
		left_arm,
		right_arm,
		arm_left_joint,
		arm_right_joint,
		forearm_left_joint,
		forearm_right_joint,
		index,
		control: create_particle_control()
	}
	particle_list.val.push(tmp)
	tmp
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

fn maintain_torso(
	particle: Particle,
	target_angle: Double,
	target_pos: (Double, Double)
)-> Unit {
	maintain_rotation(particle.torso, target_angle)
	maintain_position(particle.torso, target_pos)
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

fn which_platform(
	particle: Particle
)->Int{
	for platform in platform_list.val {
		if is_contact(particle.left_shank, platform.body) {
			return platform.index
		}
		if is_contact(particle.right_shank, platform.body) {
			return platform.index
		}
		// if is_contact(particle.right_thigh, platform.body) {
		// 	return platform.index
		// }
		// if is_contact(particle.right_thigh, platform.body) {
		// 	return platform.index
		// }
	}
	-1
}
//particle walk
let knee_angle : Double = 63.0 / 180.0 * Pi
let thigh_angle_forward = 0.8
let thigh_angle_backward = -0.5
let elbow_angle : Double = 63.0 / 180.0 * Pi
let arm_angle_forward = 0.5
let arm_angle_backward = -0.5
fn particle_walk(
	particle: Particle,
	direction: Double
)->Unit{
	//腿部动作处理
	if particle.control.walk_state{	maintain_joint(particle.thigh_left_joint, thigh_angle_backward,kp=50.0,kd=1.0)}
	else{					maintain_joint(particle.thigh_left_joint, thigh_angle_forward,kp=50.0,kd=1.0)}
	if particle.control.walk_state{	maintain_joint(particle.thigh_right_joint, thigh_angle_forward,kp=50.0,kd=1.0)}
	else{					maintain_joint(particle.thigh_right_joint,thigh_angle_backward,kp=50.0,kd=1.0)}
	maintain_joint(particle.knee_left_joint, -knee_angle*direction,kp=30.0,kd=1.0)
	maintain_joint(particle.knee_right_joint, -knee_angle*direction,kp=30.0,kd=1.0)
	
	//手部动作处理
	if particle.control.walk_state{	maintain_joint(particle.arm_left_joint, arm_angle_backward,kp=30.0,kd=1.0)}
	else{					maintain_joint(particle.arm_left_joint, arm_angle_forward,kp=30.0,kd=1.0)}
	if particle.control.walk_state{	maintain_joint(particle.arm_right_joint, arm_angle_forward,kp=30.0,kd=1.0)}
	else{					maintain_joint(particle.arm_right_joint, arm_angle_backward,kp=30.0,kd=1.0)}
	maintain_joint(particle.forearm_left_joint, elbow_angle*direction,kp=30.0,kd=1.0)
	maintain_joint(particle.forearm_right_joint, elbow_angle*direction,kp=30.0,kd=1.0)
	
	//躯干姿态处理
	maintain_rotation(particle.torso, 0,kp=100.0,kd=10.0)
	
	//状态处理
	if particle.control.walk_cooldown<=0{
		particle.control.walk_state = !particle.control.walk_state
		particle.control.walk_cooldown=20
	}
	else{particle.control.walk_cooldown-=1}

	//力学处理
	let index=which_platform(particle)
	if(index==-1){
		particle.torso.applyForce(@box2d.b2Vec2(50.0*direction,0.0), particle.torso.getCenterPosition())
		return 
	}
	
	let platform=platform_list.val[index]
	let p_angle=platform.body.getRotation()
	let target_y=(
		particle.torso.getCenterPosition().getX()-platform.body.getCenterPosition().getX()
	)*@cmath.tan(p_angle)+platform.body.getCenterPosition().getY()//Fuck
	
	maintain_position(particle.torso,(particle.torso.getCenterPosition().getX(),target_y+3.4),kd=5.0,kp=1.0)
	let v=@box2d.b2Vec2(50.0*direction*@cmath.cos(p_angle),50.0*direction*@cmath.sin(p_angle))
	particle.torso.applyForce(v, particle.torso.getCenterPosition())
}
//这里缺少了走路停下的阻尼,和站稳的阻尼

//这里缺少了跳跃的动作
let knee_angle_bend_max : Double = -2.50  // 最大弯曲角度 (前10帧)
let knee_angle_straight : Double = 0.0  // 最大伸直角度 (最后3帧)
let j_dur_A : Int = 40  // 前10帧膝盖弯曲
let j_dur_B : Int = 1  // 后3帧膝盖伸直
let j_dur_C : Int = 20  // 后3帧膝盖伸直
let jump_force : Double = 200.0  // 跳跃力大小

fn particle_jump(
    particle: Particle,
    direction: Double
)-> Unit {
    // 控制跳跃动作的帧计数

    // 跳跃的膝盖弯曲和伸直处理
    if particle.control.jump_state {
		println(particle.control.jump_frame_count)
		maintain_rotation(particle.torso, 0,kp=100.0,kd=10.0)
        // 膝盖弯曲: 前10帧
        particle.control.jump_frame_count += 1
        if particle.control.jump_frame_count < j_dur_A {
            let bend_factor : Double = (particle.control.jump_frame_count.to_double() / j_dur_A.to_double()) * knee_angle_bend_max
			println(bend_factor)
            maintain_joint(particle.knee_left_joint, bend_factor, kp = 50.0, kd = 2.0)
            maintain_joint(particle.knee_right_joint, bend_factor, kp = 50.0, kd = 2.0)
            maintain_joint(particle.thigh_left_joint, thigh_angle_forward, kp = 50.0, kd = 2.0)
            maintain_joint(particle.thigh_right_joint, -thigh_angle_backward, kp = 50.0, kd = 2.0)
			return 
        }
		else if particle.control.jump_frame_count < j_dur_A+j_dur_B {
			let v = @box2d.b2Vec2(jump_force * direction, 50.0) // 沿x轴和y轴施加力
        	particle.torso.applyImpulse(v, particle.torso.getCenterPosition())
			return 
		}
        else if particle.control.jump_frame_count < (j_dur_A + j_dur_B + j_dur_C) {
			//let v = @box2d.b2Vec2(jump_force * direction, 5.0) // 沿x轴和y轴施加力
        	//particle.torso.applyImpulse(v, particle.torso.getCenterPosition())
            let straight_factor: Double = knee_angle_bend_max - ((particle.control.jump_frame_count - j_dur_A - j_dur_B).to_double() / j_dur_C.to_double()) * knee_angle_bend_max
            maintain_joint(particle.knee_left_joint, 0, kp = 70.0, kd = 2.0)
            maintain_joint(particle.knee_right_joint, 0, kp = 70.0, kd = 2.0)
            maintain_joint(particle.thigh_left_joint, 0, kp = 70.0, kd = 2.0)
            maintain_joint(particle.thigh_right_joint, 0, kp = 70.0, kd = 2.0)
			return 
        }


        // 跳跃完成，重置状态
            particle.control.jump_state = false  // 跳跃结束
    }
}

fn particle_stand(
	particle: Particle
)->Unit{
	let index=which_platform(particle)
	maintain_joint(particle.thigh_left_joint, 0.0,kp=50.0,kd=2.0)
	maintain_joint(particle.thigh_right_joint, 0.0,kp=50.0,kd=2.0)
	maintain_joint(particle.knee_left_joint, 0.0,kp=10.0,kd=2.0)
	maintain_joint(particle.knee_right_joint, 0.0,kp=10.0,kd=2.0)
	maintain_joint(particle.arm_left_joint, 0.0,kp=10.0,kd=2.0)
	maintain_joint(particle.arm_right_joint, 0.0,kp=10.0,kd=2.0)
	maintain_joint(particle.forearm_left_joint, 0.0,kp=30.0,kd=2.0)
	maintain_joint(particle.forearm_right_joint, 0.0,kp=30.0,kd=2.0)
	maintain_rotation(particle.torso, 0,kp=100.0,kd=10.0)
	if(index==-1){
		return 
	}
	println("stand")
	let platform=platform_list.val[index]
	
	let p_angle=platform.body.getRotation()

	let target_y=(
		particle.torso.getCenterPosition().getX()-platform.body.getCenterPosition().getX()
	)*@cmath.tan(p_angle)+platform.body.getCenterPosition().getY()
	
	maintain_position(particle.torso,(particle.torso.getCenterPosition().getX(),target_y+3.7))
}
fn particle_action(particle:Particle) -> Unit {
	// if(particle.jump_cooldown>=0){//有jump优先处理jump
		
	// }
}