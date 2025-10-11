//Player Entity
pub struct Particle{
	torso : @box2d.B2Body
	head : @box2d.B2Body
	left_thigh : @box2d.B2Body
	right_thigh : @box2d.B2Body
	left_shank: @box2d.B2Body
	right_shank: @box2d.B2Body
	thigh_left_joint : @box2d.B2Joint
	thigh_right_joint : @box2d.B2Joint
	knee_left_joint : @box2d.B2Joint
	knee_right_joint : @box2d.B2Joint
	neck_joint : @box2d.B2Joint
	left_forearm : @box2d.B2Body
	right_forearm : @box2d.B2Body
	left_arm : @box2d.B2Body
	right_arm : @box2d.B2Body
	arm_left_joint : @box2d.B2Joint
	arm_right_joint : @box2d.B2Joint
	forearm_left_joint : @box2d.B2Joint
	forearm_right_joint : @box2d.B2Joint
	index : Int
	
	mut walk_state : Bool
	mut cooldown : Int
}

//Platform Entity
pub struct Platform{
	body : @box2d.B2Body
	index : Int
}