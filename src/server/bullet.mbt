///| Bullet System
/// 子弹系统实现

///|
/// Global bullet list and counter
let bullet_index : Ref[Int] = Ref::new(0)

///|
let bullet_list : Ref[Array[Bullet]] = Ref::new(Array::new())

///|
/// Create a new bullet
/// 创建新子弹
pub fn create_bullet(
  world : @box2d.B2World,
  owner_id : Int,
  position : (Double, Double),
  direction : (Double, Double), // 方向向量 (会被归一化)
  speed : Double,
  damage : Int,
  bullet_type : BulletType,
  lifetime : Int,
) -> Bullet {
  bullet_index.val += 1

  // Normalize direction
  let dx = direction.0
  let dy = direction.1
  let mag = @cmath.sqrt(dx * dx + dy * dy)
  let norm_dx = if mag > 0.0001 { dx / mag } else { 1.0 }
  let norm_dy = if mag > 0.0001 { dy / mag } else { 0.0 }

  // Create bullet body (small circle)
  let circle_def = @box2d.b2CircleDef()
  circle_def.setRadius(0.1)
  circle_def.setDensity(0.1)
  circle_def.setFriction(0.0)
  circle_def.setRestitution(0.3)
  circle_def.setLocalPosition(@box2d.b2Vec2(0.0, 0.0))
  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(circle_def.getBase())
  body_def.setAllowSleep(false)
  let body = world.createBody(body_def)

  // Set initial velocity
  let velocity = @box2d.b2Vec2(norm_dx * speed, norm_dy * speed)
  body.setLinearVelocity(velocity)

  // Determine explosion radius based on type
  let explosion_radius = match bullet_type {
    Explosive => 2.0
    _ => 0.0
  }
  let bullet = Bullet::{
    id: bullet_index.val - 1,
    owner_id,
    bullet_type,
    body,
    damage,
    explosion_radius,
    speed,
    acceleration: (0.0, 0.0),
    lifetime,
    max_lifetime: lifetime,
    speed_effect: 1.0,
    acceleration_effect: (0.0, 0.0),
    jump_effect: 1.0,
    is_active: true,
  }
  bullet_list.val.push(bullet)
  bullet
}

///|
/// Update all bullets
/// 更新所有子弹
pub fn update_bullets(
  world : @box2d.B2World,
  characters : Array[Character],
) -> Unit {
  let mut to_remove : Array[Int] = Array::new()
  for i = 0; i < bullet_list.val.length(); i = i + 1 {
    let bullet = bullet_list.val[i]
    if not(bullet.is_active) {
      to_remove.push(i)
      continue
    }

    // Update lifetime
    bullet.lifetime -= 1
    if bullet.lifetime <= 0 {
      bullet.is_active = false
      to_remove.push(i)
      continue
    }

    // Apply acceleration
    let current_vel = bullet.body.getLinearVelocity()
    let new_vel = @box2d.b2Vec2(
      current_vel.getX() + bullet.acceleration.0,
      current_vel.getY() + bullet.acceleration.1,
    )
    bullet.body.setLinearVelocity(new_vel)

    // Check bounds (remove if out of bounds)
    let pos = bullet.body.getCenterPosition()
    if pos.getX() < -100.0 ||
      pos.getX() > 100.0 ||
      pos.getY() < -100.0 ||
      pos.getY() > 100.0 {
      bullet.is_active = false
      to_remove.push(i)
      continue
    }

    // Check collision with characters
    check_bullet_character_collision(bullet, characters)
  }

  // Remove inactive bullets (reverse order to maintain indices)
  for i = to_remove.length() - 1; i >= 0; i = i - 1 {
    let idx = to_remove[i]
    let bullet = bullet_list.val[idx]
    world.destroyBody(bullet.body)
    bullet_list.val.remove(idx) |> ignore
  }
}

///|
/// Check bullet collision with characters
/// 检查子弹与角色的碰撞
fn check_bullet_character_collision(
  bullet : Bullet,
  characters : Array[Character],
) -> Unit {
  for character in characters {
    // Don't hit the owner
    if character.index == bullet.owner_id {
      continue
    }

    // Check if bullet hits any body part
    let mut hit = false
    let mut damage_multiplier = 1.0

    // Head hit (2x damage)
    if is_contact(bullet.body, character.head) {
      hit = true
      damage_multiplier = 2.0
      // Torso hit (1x damage)
    } else if is_contact(bullet.body, character.torso) {
      hit = true
      damage_multiplier = 1.0
      // Limb hits (0.5x damage)
    } else if is_contact(bullet.body, character.left_arm) ||
      is_contact(bullet.body, character.right_arm) ||
      is_contact(bullet.body, character.left_thigh) ||
      is_contact(bullet.body, character.right_thigh) ||
      is_contact(bullet.body, character.left_shank) ||
      is_contact(bullet.body, character.right_shank) ||
      is_contact(bullet.body, character.left_forearm) ||
      is_contact(bullet.body, character.right_forearm) {
      hit = true
      damage_multiplier = 0.5
    }
    if hit {
      // Apply damage
      let final_damage = (bullet.damage.to_double() * damage_multiplier).to_int()
      apply_damage_to_character(character, final_damage, bullet)

      // Handle explosion
      if bullet.explosion_radius > 0.0 {
        handle_explosion(bullet, characters)
      }

      // Deactivate bullet
      bullet.is_active = false
      break
    }
  }
}

///|
/// Apply damage to character
/// 对角色施加伤害
fn apply_damage_to_character(
  character : Character,
  damage : Int,
  bullet : Bullet,
) -> Unit {
  character.control.health -= damage
  character.control.last_damage = damage

  // Calculate hit direction
  let bullet_pos = bullet.body.getCenterPosition()
  let char_pos = character.torso.getCenterPosition()
  let dx = char_pos.getX() - bullet_pos.getX()
  let dy = char_pos.getY() - bullet_pos.getY()
  character.control.last_hit_direction = (dx, dy)

  // Apply knockback
  let knockback = @box2d.b2Vec2(dx * 5.0, dy * 5.0)
  character.torso.applyImpulse(knockback, character.torso.getCenterPosition())

  // Apply special effects
  if bullet.speed_effect != 1.0 {
    character.control.speed_multiplier *= bullet.speed_effect
  }
  if bullet.acceleration_effect.0 != 0.0 || bullet.acceleration_effect.1 != 0.0 {
    character.control.acceleration_modifier = (
      character.control.acceleration_modifier.0 + bullet.acceleration_effect.0,
      character.control.acceleration_modifier.1 + bullet.acceleration_effect.1,
    )
  }
  if bullet.jump_effect != 1.0 {
    character.control.jump_height_multiplier *= bullet.jump_effect
  }

  // Check if character is knocked out
  if character.control.health <= 0 {
    character.control.is_faint = true
  }
}

///|
/// Handle explosion damage
/// 处理爆炸伤害
fn handle_explosion(bullet : Bullet, characters : Array[Character]) -> Unit {
  let explosion_pos = bullet.body.getCenterPosition()
  for character in characters {
    let char_pos = character.torso.getCenterPosition()
    let dx = char_pos.getX() - explosion_pos.getX()
    let dy = char_pos.getY() - explosion_pos.getY()
    let distance = @cmath.sqrt(dx * dx + dy * dy)
    if distance < bullet.explosion_radius {
      // Damage falls off with distance
      let damage_ratio = 1.0 - distance / bullet.explosion_radius
      let explosion_damage = (bullet.damage.to_double() * damage_ratio * 0.5).to_int()
      if explosion_damage > 0 {
        character.control.health -= explosion_damage

        // Apply explosion knockback
        let knockback_force = 200.0 * damage_ratio
        let knockback = @box2d.b2Vec2(
          dx * knockback_force,
          dy * knockback_force,
        )
        character.torso.applyImpulse(
          knockback,
          character.torso.getCenterPosition(),
        )
        if character.control.health <= 0 {
          character.control.is_faint = true
        }
      }
    }
  }
}

///|
/// Clear all bullets
/// 清空所有子弹
pub fn clear_bullets(world : @box2d.B2World) -> Unit {
  for bullet in bullet_list.val {
    world.destroyBody(bullet.body)
  }
  bullet_list.val = Array::new()
  bullet_index.val = 0
}
