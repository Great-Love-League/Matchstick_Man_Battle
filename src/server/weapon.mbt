
let sword_shift:@box2d.B2Vec2=@box2d.b2Vec2((-6.35)-(-7.07), (17.00)-(15.10))
let sword_index : Ref[Int]=Ref::new(0)
pub struct Sword{
	mut id : Int
	mut owner_id : Int
	mut body : @box2d.B2Body
}
let sword_list : Ref[Array[Sword]]=Ref::new(Array::new())
let gun_body:String="13".to_string()
let gun_body_shift:@box2d.B2Vec2=@box2d.b2Vec2(0.0, 0.0)
let gun_index : Ref[Int]=Ref::new(0)
pub struct Gun{
	mut id : Int
	mut owner_id : Int
	mut body : @box2d.B2Body
}
let gun_list : Ref[Array[Gun]]=Ref::new(Array::new())

pub(open) trait WeaponCreate {
	create(world:@box2d.B2World,owner_id:Int) -> Unit
}

pub(open) trait WeaponControl {
	attack(Self) -> Unit
}

pub(open) trait WeaponDestroy {
	destroy(Self, world:@box2d.B2World) -> Unit
}

pub impl WeaponCreate for Sword with create(world, owner_id){
	let bodydef=@map_loader.get_bodydef_from_raw(Some(sword_body), None) catch {
        _=> {
					println("Failed to create body definition for Sword")
					@box2d.b2BodyDef()
				}
    }
	return
	let centerpos=particle_list.val[owner_id].right_forearm.getCenterPosition()
	let rotate =particle_list.val[owner_id].right_forearm.getRotation()
	let handpos=@box2d.b2Vec2(@cmath.sin(rotate)+centerpos.getX(),@cmath.cos(rotate)+centerpos.getY())

	bodydef.setPosition(@box2d.b2Vec2(handpos.getX()+sword_shift.getX(), handpos.getY()+sword_shift.getY()))
	
	sword_index.val+=1
	let aa:Sword=Sword::{
		id:sword_index.val,
		owner_id:owner_id,
		body:world.createBody(bodydef)
	}
	sword_list.val.push(aa)
	
	create_joint(world, particle_list.val[owner_id].right_forearm, aa.body, (handpos.getX(),handpos.getY()), enable_limit=false)|> ignore
}

pub impl WeaponControl for Sword with attack(self){
	for i in particle_list.val {
		if i.index==self.owner_id{
			continue
		}
		if is_contact(i.torso, self.body) || is_contact(i.head, self.body){
			i.control.health-=10
			if i.control.health<=0{
				i.control.is_faint=true
			}
			break
		}
		else if is_contact(i.left_thigh, self.body) || is_contact(i.right_thigh, self.body){
			i.control.health-=5
			if i.control.health<=0{
				i.control.is_faint=true
			}
			break
		}
		else if is_contact(i.left_shank, self.body) || is_contact(i.right_shank, self.body){
			i.control.health-=3
			if i.control.health<=0{
				i.control.is_faint=true
			}
			break
		}
		else if is_contact(i.left_arm, self.body) || is_contact(i.right_arm, self.body){
			i.control.health-=4
			if i.control.health<=0{
				i.control.is_faint=true
			}
			break
		}
		else if is_contact(i.left_forearm, self.body) || is_contact(i.right_forearm, self.body){
			i.control.health-=2
			if i.control.health<=0{
				i.control.is_faint=true
			}
			break
		}
	}
	println("Sword attack!")
}

pub impl WeaponDestroy for Sword with destroy(self, world){
	world.destroyBody(self.body)
}

pub impl WeaponCreate for Gun with create( world, owner_id){
	let mut bodydef:@box2d.B2BodyDef=@map_loader.get_bodydef_from_raw(Some(gun_body), None) catch {
				_=> {
					println("Failed to create body definition for Gun")
					@box2d.b2BodyDef()
				}
		}
}

pub impl WeaponControl for Gun with attack(self){
	println("Gun attack!")
}

pub impl WeaponDestroy for Gun with destroy(self, world){
	world.destroyBody(self.body)
}

// pub struct Entity{
// 	mut id : Int
// 	mut body_list : Array[@box2d.B2Body]
// }

// pub struct Bullet{
// 	mut ent : Entity
// }