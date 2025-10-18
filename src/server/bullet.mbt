///| 子弹系统
/// 管理所有子弹的创建、更新和销毁

///|
/// 子弹结构体
pub struct Bullet {
  id : Int
  owner_id : Int
  body : @box2d.B2Body
  damage : Int
  max_distance : Double
  mut traveled_distance : Double
  start_position : (Double, Double)
  mut is_active : Bool
}

///|
/// 子弹列表和计数器
let bullet_list : Ref[Array[Bullet]] = Ref::new(Array::new())

///|
let bullet_index : Ref[Int] = Ref::new(0)

///|
/// 创建子弹
pub fn create_bullet(
  world : @box2d.B2World,
  position : (Double, Double),
  velocity : (Double, Double),
  owner_id : Int,
  damage? : Int = 10,
  max_distance? : Double = 50.0,
) -> Bullet {
  bullet_index.val += 1
  let circle_def = @box2d.b2CircleDef()
  circle_def.setRadius(0.1)
  circle_def.setDensity(0.5)
  circle_def.setFriction(0.1)
  circle_def.setLocalPosition(@box2d.b2Vec2(0.0, 0.0))
  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(circle_def.getBase())
  let body = world.createBody(body_def)
  body.setLinearVelocity(@box2d.b2Vec2(velocity.0, velocity.1))
  let bullet = Bullet::{
    id: bullet_index.val,
    owner_id,
    body,
    damage,
    max_distance,
    traveled_distance: 0.0,
    start_position: position,
    is_active: true,
  }
  bullet_list.val.push(bullet)
  bullet
}

///|
/// 更新单个子弹
fn update_bullet(bullet : Bullet) -> Unit {
  if not(bullet.is_active) {
    return
  }
  let current_pos = bullet.body.getCenterPosition()
  let dx = current_pos.getX() - bullet.start_position.0
  let dy = current_pos.getY() - bullet.start_position.1
  bullet.traveled_distance = @cmath.sqrt(dx * dx + dy * dy)
  if bullet.traveled_distance >= bullet.max_distance {
    bullet.is_active = false
    return
  }
  let x = current_pos.getX()
  let y = current_pos.getY()
  let half_width = VIEWPORT_WIDTH / PPM / 2.0
  let half_height = VIEWPORT_HEIGHT / PPM / 2.0
  if x < -half_width || x > half_width || y < 0.0 || y > half_height * 2.0 {
    bullet.is_active = false
    return
  }
  check_bullet_collision(bullet)
}

///|
/// 检测子弹与人物的碰撞
fn check_bullet_collision(bullet : Bullet) -> Unit {
  for particle in particle_list.val {
    if particle.index == bullet.owner_id {
      continue
    }
    if particle.control.is_faint {
      continue
    }
    let mut hit = false
    let mut damage = 0
    if is_contact(particle.head, bullet.body) {
      damage = bullet.damage * 2
      hit = true
    } else if is_contact(particle.torso, bullet.body) {
      damage = bullet.damage
      hit = true
    } else if is_contact(particle.left_thigh, bullet.body) ||
      is_contact(particle.right_thigh, bullet.body) {
      damage = bullet.damage / 2
      hit = true
    } else if is_contact(particle.left_shank, bullet.body) ||
      is_contact(particle.right_shank, bullet.body) {
      damage = bullet.damage / 3
      hit = true
    } else if is_contact(particle.left_arm, bullet.body) ||
      is_contact(particle.right_arm, bullet.body) {
      damage = bullet.damage / 2
      hit = true
    } else if is_contact(particle.left_forearm, bullet.body) ||
      is_contact(particle.right_forearm, bullet.body) {
      damage = bullet.damage / 3
      hit = true
    }
    if hit {
      particle.control.health -= damage
      if particle.control.health <= 0 {
        particle.control.is_faint = true
      }
      bullet.is_active = false
      break
    }
  }
}

///|
/// 更新所有子弹
pub fn update_all_bullets() -> Unit {
  for bullet in bullet_list.val {
    if bullet.is_active {
      update_bullet(bullet)
    }
  }
}

///|
/// 清理所有非活跃的子弹
pub fn cleanup_bullets(world : @box2d.B2World) -> Unit {
  let active_bullets : Array[Bullet] = Array::new()
  for bullet in bullet_list.val {
    if bullet.is_active {
      active_bullets.push(bullet)
    } else {
      world.destroyBody(bullet.body)
    }
  }
  bullet_list.val = active_bullets
}

///|
/// 获取活跃子弹数量
pub fn get_active_bullet_count() -> Int {
  let mut count = 0
  for bullet in bullet_list.val {
    if bullet.is_active {
      count += 1
    }
  }
  count
}
