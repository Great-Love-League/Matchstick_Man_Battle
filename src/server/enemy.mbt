

enum ActionType{
	Patrol
	Pursuit
	Attack
}

struct Enemy {
	id : Int
	//hp
	hp : Int
	hp_limit : Int
	damage_scale : Double
	//movement
	acceleration: @box2d.B2Vec2
	max_speed : Double
	jump_force : Double
	action_type : ActionType
	
	field_of_view : Double
	field_of_attack : Double
	
	body : @box2d.B2Body
	target_particle_id : Int
}



pub(open) trait EnemyCreate{
	
}
pub(open) trait EnemyControl{
	
}
pub(open) trait EnemyDestroy{
	
}
