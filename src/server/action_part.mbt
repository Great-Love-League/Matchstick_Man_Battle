///|
fn which_platform(particle : Particle) -> Int {
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

///|
let knee_angle : Double = 63.0 / 180.0 * Pi
let thigh_angle_forward = 0.8
let thigh_angle_backward = -0.5
let elbow_angle : Double = 63.0 / 180.0 * Pi
let arm_angle_forward = 0.5
let arm_angle_backward = -0.5

///|
fn particle_walk(particle : Particle, direction : Double) -> Unit {
  //腿部动作处理
	particle.control.walk_direction = direction
	if !particle.control.jump_state {
		if particle.control.walk_state {
			maintain_joint(particle.thigh_left_joint,thigh_angle_backward,kp=50.0,kd=1.0,)
		} else {
			maintain_joint(particle.thigh_left_joint,thigh_angle_forward,kp=50.0,kd=1.0,)
		}
		if particle.control.walk_state {
			maintain_joint(particle.thigh_right_joint,thigh_angle_forward,kp=50.0,kd=1.0,)
		} else {
			maintain_joint(particle.thigh_right_joint,thigh_angle_backward,kp=50.0,kd=1.0,)
		}
		maintain_joint(particle.knee_left_joint,-knee_angle * direction,kp=30.0,kd=1.0,)
		maintain_joint(particle.knee_right_joint,-knee_angle * direction,kp=30.0,kd=1.0,)
		if particle.control.walk_state {
			maintain_joint(particle.arm_left_joint, arm_angle_backward, kp=30.0, kd=1.0)
		} else {
			maintain_joint(particle.arm_left_joint, arm_angle_forward, kp=30.0, kd=1.0)
		}
		if particle.control.walk_state {
			maintain_joint(particle.arm_right_joint, arm_angle_forward, kp=30.0, kd=1.0)
		} else {
			maintain_joint(particle.arm_right_joint,arm_angle_backward,kp=30.0,kd=1.0)
		}
		maintain_joint(particle.forearm_left_joint,elbow_angle * direction,kp=30.0,kd=1.0)
		maintain_joint(particle.forearm_right_joint,elbow_angle * direction,kp=30.0,kd=1.0)
	}

  //手部动作处理

  //躯干姿态处理
  maintain_rotation(particle.torso, 0, kp=100.0, kd=10.0)

  //状态处理
  if particle.control.walk_cooldown <= 0 {
    particle.control.walk_state = !particle.control.walk_state
    particle.control.walk_cooldown = 20
  } else {
    particle.control.walk_cooldown -= 1
  }

	particle.torso.applyForce(
		@box2d.b2Vec2(50.0 * direction, 0.0),
		particle.torso.getCenterPosition(),
	)
  //力学处理
  let index = which_platform(particle)
  if index == -1 {
    return
  }
  let platform = platform_list.val[index]
  let p_angle = platform.body.getRotation()
  let target_y = (
      particle.torso.getCenterPosition().getX() -
      platform.body.getCenterPosition().getX()
    ) *
    @cmath.tan(p_angle) +
    platform.body.getCenterPosition().getY() //Fuck
  maintain_position(particle.torso,(particle.torso.getCenterPosition().getX(), target_y + 3.5))
  let v = @box2d.b2Vec2(
    50.0 * direction * @cmath.cos(p_angle),
    50.0 * direction * @cmath.sin(p_angle),
  )
  particle.torso.applyForce(v, particle.torso.getCenterPosition())
}
//这里缺少了走路停下的阻尼,和站稳的阻尼

//这里缺少了跳跃的动作

///|
let knee_angle_bend_max : Double = -2.50 // 最大弯曲角度 (前10帧)
let knee_angle_straight : Double = 0.0 // 最大伸直角度 (最后3帧)
let j_thigh_angle_forward : Double = 1.0 
let j_thigh_angle_backward : Double = 0.3
let j_arm_angle_backward : Double = -0.3
let j_dur_A : Int = 40 // 前10帧膝盖弯曲
let j_dur_B : Int = 1 // 后3帧膝盖伸直
let j_dur_C : Int = 20 // 后3帧膝盖伸直
let jump_force : Double = 200.0 // 跳跃力大小

///|
fn particle_jump(particle : Particle, direction : Double) -> Unit {
  // 控制跳跃动作的帧计数

  // 跳跃的膝盖弯曲和伸直处理
  if particle.control.jump_state {
    // 膝盖弯曲: 前10帧
    particle.control.jump_frame_count += 1
    if particle.control.jump_frame_count < j_dur_A {
    	maintain_rotation(particle.torso, particle.control.walk_direction*-0.2, kp=100.0, kd=10.0)
      let bend_factor : Double = particle.control.jump_frame_count.to_double() /
        j_dur_A.to_double() *
        knee_angle_bend_max
      println(bend_factor)
			maintain_joint(particle.arm_left_joint, j_arm_angle_backward*particle.control.walk_direction, kp=30.0, kd=1.0)
			maintain_joint(particle.arm_right_joint, j_arm_angle_backward*particle.control.walk_direction, kp=30.0, kd=1.0)
			maintain_joint(particle.forearm_left_joint, elbow_angle * particle.control.walk_direction, kp=30.0, kd=1.0)
			maintain_joint(particle.forearm_right_joint, elbow_angle * particle.control.walk_direction, kp=30.0, kd=1.0)
      maintain_joint(particle.knee_left_joint, bend_factor*particle.control.walk_direction, kp=50.0, kd=2.0)
      maintain_joint(particle.knee_right_joint, bend_factor*particle.control.walk_direction, kp=50.0, kd=2.0)
      maintain_joint(particle.thigh_left_joint,j_thigh_angle_forward*particle.control.walk_direction,kp=50.0,kd=2.0)
      maintain_joint(particle.thigh_right_joint,j_thigh_angle_backward*particle.control.walk_direction,kp=50.0,kd=2.0)
      return
    } else if particle.control.jump_frame_count < j_dur_A + j_dur_B {
      maintain_rotation(particle.torso, 0, kp=100.0, kd=10.0)
      let v = @box2d.b2Vec2(jump_force * direction, 50.0) // 沿x轴和y轴施加力
      particle.torso.applyImpulse(v, particle.torso.getCenterPosition())
      return
    } else if particle.control.jump_frame_count < j_dur_A + j_dur_B + j_dur_C {
      maintain_rotation(particle.torso, 0, kp=100.0, kd=10.0)
      let straight_factor : Double = knee_angle_bend_max -
        (particle.control.jump_frame_count - j_dur_A - j_dur_B).to_double() /
        j_dur_C.to_double() *
        knee_angle_bend_max
			maintain_joint(particle.arm_left_joint, 0, kp=30.0, kd=2.0)
			maintain_joint(particle.arm_right_joint, 0, kp=30.0, kd=2.0)
			maintain_joint(particle.forearm_left_joint, 0, kp=30.0, kd=2.0)
			maintain_joint(particle.forearm_right_joint, 0, kp=30.0, kd=2.0)
      maintain_joint(particle.knee_left_joint, 0, kp=70.0, kd=2.0)
      maintain_joint(particle.knee_right_joint, 0, kp=70.0, kd=2.0)
      maintain_joint(particle.thigh_left_joint, 0, kp=70.0, kd=2.0)
      maintain_joint(particle.thigh_right_joint, 0, kp=70.0, kd=2.0)
      return
    }

    // 跳跃完成，重置状态
    particle.control.jump_state = false // 跳跃结束
  }
}

///|
fn particle_stand(particle : Particle) -> Unit {
  let index = which_platform(particle)
  maintain_joint(particle.thigh_left_joint, 0.0, kp=50.0, kd=2.0)
  maintain_joint(particle.thigh_right_joint, 0.0, kp=50.0, kd=2.0)
  maintain_joint(particle.knee_left_joint, 0.0, kp=10.0, kd=2.0)
  maintain_joint(particle.knee_right_joint, 0.0, kp=10.0, kd=2.0)
  maintain_joint(particle.arm_left_joint, 0.0, kp=10.0, kd=2.0)
  maintain_joint(particle.arm_right_joint, 0.0, kp=10.0, kd=2.0)
  maintain_joint(particle.forearm_left_joint, 0.0, kp=30.0, kd=2.0)
  maintain_joint(particle.forearm_right_joint, 0.0, kp=30.0, kd=2.0)
  maintain_rotation(particle.torso, 0, kp=100.0, kd=10.0)
  if index == -1 {
    return
  }
  let platform = platform_list.val[index]
  let p_angle = platform.body.getRotation()
  let target_y = (
      particle.torso.getCenterPosition().getX() -
      platform.body.getCenterPosition().getX()
    ) *
    @cmath.tan(p_angle) +
    platform.body.getCenterPosition().getY()
  maintain_position(
    particle.torso,
    (particle.torso.getCenterPosition().getX(), target_y + 3.7),
  )
}

///|
fn particle_action(particle : Particle) -> Unit {
  // if(particle.jump_cooldown>=0){//有jump优先处理jump

  // }
}
