pub struct Weapon{
	mut id : Int
	mut handheld : @box2d.B2Vec2
}

pub struct Sword{
	mut id : Int
	mut art: Weapon
	mut body : @box2d.B2Body
}
pub struct Gun{
	mut id : Int
	mut art: Weapon
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
	let s:String="123".to_string();

	let mut bodydef:@box2d.B2BodyDef=match @map_loader.get_bodydef_from_raw(Some(s), None) {
        Ok(b) => b,
        None => {
            // 处理错误情况
            panic("Failed to get bodydef")
        }
    }
}

// pub struct Entity{
// 	mut id : Int
// 	mut body_list : Array[@box2d.B2Body]
// }

// pub struct Bullet{
// 	mut ent : Entity
// }