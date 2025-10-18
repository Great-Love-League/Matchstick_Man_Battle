//return a particle and its index in the particle system

fn create_particle_control(
	walk_state?: Bool=false,
	walk_direction?: Double=1.0,
	walk_cooldown?: Int=0,
	jump_cooldown?: Int=-1,
	jump_state?: Bool=false,
	jump_frame_count?: Int=0,
	health?: Int=100,
	is_faint?: Bool=false
) -> ParticleControl{
	ParticleControl::{
		walk_state,
		walk_direction,
		walk_cooldown,
		jump_cooldown,
		jump_state,
		jump_frame_count,
		health,
		is_faint
	}
}

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
	let left_shank = create_dynamic_box(world, (position.0, position.1-2),(0.15,0.5),density=1.0,groupindex=-1,friciton=0.2)
	let right_shank = create_dynamic_box(world, (position.0, position.1-2),(0.15,0.5),density=1.0,groupindex=-1,friciton=0.2)
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