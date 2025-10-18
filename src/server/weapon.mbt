
let sword_shift:@box2d.B2Vec2=@box2d.b2Vec2(((-6.35)-(-7.07))/2, ((17.00)-(15.10))/2)
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
	create(game:Game,owner_id:Int) -> Unit
}

pub(open) trait WeaponControl {
	attack(Self, game:Game) -> Unit
  get_attack_field(Self) -> Double = _
}

pub(open) trait WeaponDestroy {
	destroy(Self, game:Game) -> Unit
}

impl WeaponControl with get_attack_field(self) -> Double {
	return 1.0
}

pub impl WeaponCreate for Sword with create(game, owner_id){
	let bodydef=@map_loader.get_bodydef_from_raw(Some(sword_body), None) catch {
        _=> {
					println("Failed to create body definition for Sword")
					@box2d.b2BodyDef()
				}
    }
	let centerpos=game.particle_list[owner_id].right_forearm.getCenterPosition()
	let rotate =game.particle_list[owner_id].right_forearm.getRotation()
	let handpos=@box2d.b2Vec2(-@cmath.sin(rotate)*0.25+centerpos.getX(),-@cmath.cos(rotate)*0.25+centerpos.getY())

	bodydef.setPosition(@box2d.b2Vec2(handpos.getX()+sword_shift.getX(), handpos.getY()+sword_shift.getY()))
	
	sword_index.val+=1
	let aa:Sword=Sword::{
		id:sword_index.val,
		owner_id:owner_id,
		body:game.world.createBody(bodydef)
	}
	sword_list.val.push(aa)

	game.create_joint(game.particle_list[owner_id].right_forearm, aa.body, (handpos.getX(),handpos.getY()), enable_limit=false)|> ignore
}

pub impl WeaponControl for Sword with attack(self,game){
	for i in game.particle_list {
		if i.index==self.owner_id{
			continue
		}
		if game.is_contact(i.torso, self.body) || game.is_contact(i.head, self.body){
			i.control.health-=10
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
		else if game.is_contact(i.left_thigh, self.body) || game.is_contact(i.right_thigh, self.body){
			i.control.health-=5
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
		else if game.is_contact(i.left_shank, self.body) || game.is_contact(i.right_shank, self.body){
			i.control.health-=3
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
		else if game.is_contact(i.left_arm, self.body) || game.is_contact(i.right_arm, self.body){
			i.control.health-=4
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
		else if game.is_contact(i.left_forearm, self.body) || game.is_contact(i.right_forearm, self.body){
			i.control.health-=2
			if i.control.health<=0{
				i.control.faint_state=true
			}
			break
		}
	}
	println("Sword attack!")
}

pub impl WeaponDestroy for Sword with destroy(self, game){
	game.world.destroyBody(self.body)
}

pub impl WeaponCreate for Gun with create( game, owner_id){
	let mut bodydef:@box2d.B2BodyDef=@map_loader.get_bodydef_from_raw(Some(gun_body), None) catch {
				_=> {
					println("Failed to create body definition for Gun")
					@box2d.b2BodyDef()
				}
		}
}

pub impl WeaponControl for Gun with attack(self,game){
	println("Gun attack!")
}

pub impl WeaponDestroy for Gun with destroy(self, game){
	game.world.destroyBody(self.body)
}

// pub struct Entity{
// 	mut id : Int
// 	mut body_list : Array[@box2d.B2Body]
// }

// pub struct Bullet{
// 	mut ent : Entity
// }