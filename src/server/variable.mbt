pub let world :Ref[@box2d.B2World]=Ref::new(create_world())

pub let particle_list:Ref[Array[Particle]]=Ref::new(Array::new())
pub let platform_list:Ref[Array[Platform]]=Ref::new(Array::new())

// pub let body_entity_list : Array[@system.Entity] = Array::new()