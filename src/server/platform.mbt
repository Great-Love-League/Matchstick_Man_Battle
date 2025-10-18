//Platform Entity
pub struct Platform{
	body : @box2d.B2Body
	index : Int
}
fn Game::create_platform(
	self:Self,
	position: (Double, Double),
	size: (Double, Double)
)-> Platform{
	platform_index.val+=1
	let body = self.create_static_box(position, size)
	let index = platform_index.val-1
	let tmp=Platform::{
		body,
		index
	}
	self.platform_list.push(tmp)
	tmp
}