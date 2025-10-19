
let sword_shift:@box2d.B2Vec2=@box2d.b2Vec2(((-6.35)-(-7.07))/2, ((17.00)-(15.10))/2)
let gun_body_shift:@box2d.B2Vec2=@box2d.b2Vec2(0.0, 0.0)


pub struct WeaponManager{
	mut sword_index : Int
	sword_list : Array[Sword]
	mut gun_index : Int
	gun_list : Array[Gun]
}

fn create_weapon_manager() -> WeaponManager{
	let weapon_manager=WeaponManager::{
		sword_index:0,
		sword_list:Array::new(),
		gun_index:0,
		gun_list:Array::new()
	}
	weapon_manager
}

pub struct Sword{
	id : Int
	owner_id : Int
	body : @box2d.B2Body
}
pub struct Gun{
	id : Int
	owner_id : Int
	body : @box2d.B2Body
}

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
	
	game.weapon.sword_index+=1
	let aa:Sword=Sword::{
		id:game.weapon.sword_index,
		owner_id:owner_id,
		body:game.world.createBody(bodydef)
	}
	game.weapon.sword_list.push(aa)

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
	let bodydef:@box2d.B2BodyDef=@map_loader.get_bodydef_from_raw(Some(gun_body), None) catch {
				_=> {
					println("Failed to create body definition for Gun")
					@box2d.b2BodyDef()
				}
		}
	let centerpos=game.particle_list[owner_id].right_forearm.getCenterPosition()
	let rotate =game.particle_list[owner_id].right_forearm.getRotation()
	let handpos=@box2d.b2Vec2(-@cmath.sin(rotate)*0.25+centerpos.getX(),-@cmath.cos(rotate)*0.25+centerpos.getY())

	bodydef.setPosition(@box2d.b2Vec2(handpos.getX()+gun_body_shift.getX(), handpos.getY()+gun_body_shift.getY()))
	
	game.weapon.gun_index+=1
	let aa:Gun=Gun::{
		id:game.weapon.gun_index,
		owner_id:owner_id,
		body:game.world.createBody(bodydef)
	}
	game.weapon.gun_list.push(aa)

	game.create_joint(game.particle_list[owner_id].right_forearm, aa.body, (handpos.getX(),handpos.getY()), enable_limit=false)|> ignore
}

pub impl WeaponControl for Gun with attack(self,game){
	println("Gun attack!")
}

pub impl WeaponDestroy for Gun with destroy(self, game){
	game.world.destroyBody(self.body)
}