pub struct Weapon{
	mut id : Int
	mut handheld : @box2d.B2Vec2
}

pub struct Sword{
	mut id : Int
	mut art:Weapon
	mut body : @box2d.B2Body
}

pub(open) trait WeaponCreate {
	create(Self, world:@box2d.B2World, position:(Double, Double)) -> Unit
}

pub(open) trait WeaponControl {
	attack(Self) -> Unit
}

pub(open) trait WeaponDestroy {
	destroy(Self, world:@box2d.B2World) -> Unit
}

pub impl WeaponCreate for Sword with create(self, world, position){
	let mut body_def = @box2d.B2BodyDef()
	body_def.s
	self.body=world.val.createBody
}

pub struct Entity{
	mut id : Int
	mut body_list : Array[@box2d.B2Body]
}

pub struct Bullet{
	mut ent : Entity
}