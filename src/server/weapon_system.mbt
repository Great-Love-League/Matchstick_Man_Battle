///| Weapon System - Unified weapon implementation
/// 武器系统 - 统一的武器实现

///|
/// Global weapon list and counter
let weapon_index : Ref[Int] = Ref::new(0)

///|
let weapon_list : Ref[Array[Weapon]] = Ref::new(Array::new())

///|
/// Create a new weapon
/// 创建新武器
pub fn create_weapon(
  world : @box2d.B2World,
  position : (Double, Double),
  weapon_type : WeaponType,
  owner_id? : Int = -1,
) -> Weapon {
  weapon_index.val += 1

  // Create weapon body (rectangle)
  let box_def = @box2d.b2BoxDef()
  box_def.setExtents(@box2d.b2Vec2(0.15, 0.5))
  box_def.setDensity(0.5)
  box_def.setFriction(0.3)
  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(box_def.getBase())
  body_def.setAllowSleep(false)
  let body = world.createBody(body_def)

  // Set weapon stats based on type
  let (ammo, speed, recoil, interval, auto, range, weight) = match weapon_type {
    Melee => (-1, 0.0, 0.0, 30, false, 1.5, 3.0) // 近战武器
    Gun => (30, 50.0, 5.0, 10, false, 0.0, 5.0) // 手枪
    Grenade => (5, 30.0, 10.0, 60, false, 0.0, 8.0) // 榴弹发射器
    Laser => (-1, 100.0, 0.0, 1, true, 50.0, 6.0) // 激光枪
  }
  let weapon = Weapon::{
    id: weapon_index.val - 1,
    owner_id,
    weapon_type,
    body,
    ammo_count: ammo,
    initial_bullet_speed: speed,
    recoil,
    min_attack_interval: interval,
    is_automatic: auto,
    attack_range: range,
    weight,
    last_fire_time: 0,
    direction: 0.0,
  }
  weapon_list.val.push(weapon)
  weapon
}

///|
/// Update weapon position to follow owner
/// 更新武器位置跟随持有者 (using physics forces)
pub fn update_weapon_position(weapon : Weapon, character : Character) -> Unit {
  if weapon.owner_id != character.index {
    return
  }

  // Position weapon at character's right forearm using forces
  let forearm_pos = character.right_forearm.getCenterPosition()
  let forearm_rotation = character.right_forearm.getRotation()

  // Calculate target position
  let offset_x = @cmath.cos(forearm_rotation) * 0.3
  let offset_y = @cmath.sin(forearm_rotation) * 0.3
  let target_x = forearm_pos.getX() + offset_x
  let target_y = forearm_pos.getY() + offset_y

  // Apply position maintaining force
  maintain_position(weapon.body, (target_x, target_y), kp=500.0, kd=20.0)
  maintain_rotation(weapon.body, forearm_rotation, kp=100.0, kd=10.0)
}

///|
/// Update weapon direction
/// 更新武器朝向
pub fn update_weapon_direction(
  weapon : Weapon,
  mouse_x : Double,
  mouse_y : Double,
  character : Character,
) -> Unit {
  let char_pos = character.torso.getCenterPosition()
  let dx = mouse_x - char_pos.getX()
  let dy = mouse_y - char_pos.getY()
  weapon.direction = @cmath.atan2(dy, dx)
}

///|
/// Attack with weapon
/// 使用武器攻击
pub fn weapon_attack(
  weapon : Weapon,
  character : Character,
  world : @box2d.B2World,
  current_frame : Int,
  all_characters : Array[Character],
) -> Bool {
  // Check cooldown
  if current_frame - weapon.last_fire_time < weapon.min_attack_interval {
    return false
  }

  // Check ammo (except for melee and laser which are infinite)
  if weapon.ammo_count == 0 {
    return false
  }
  weapon.last_fire_time = current_frame
  match weapon.weapon_type {
    Melee => weapon_attack_melee(weapon, character, all_characters)
    Gun => weapon_attack_gun(weapon, character, world, BulletType::Normal)
    Grenade =>
      weapon_attack_gun(weapon, character, world, BulletType::Explosive)
    Laser => weapon_attack_laser(weapon, character, all_characters)
  }

  // Consume ammo
  if weapon.ammo_count > 0 {
    weapon.ammo_count -= 1
  }

  // Apply recoil to character
  let recoil_x = -@cmath.cos(weapon.direction) * weapon.recoil
  let recoil_y = -@cmath.sin(weapon.direction) * weapon.recoil
  let recoil_force = @box2d.b2Vec2(recoil_x, recoil_y)
  character.torso.applyImpulse(
    recoil_force,
    character.torso.getCenterPosition(),
  )
  true
}

///|
/// Melee weapon attack
/// 近战武器攻击
fn weapon_attack_melee(
  weapon : Weapon,
  _character : Character,
  all_characters : Array[Character],
) -> Unit {
  let weapon_pos = weapon.body.getCenterPosition()
  for target in all_characters {
    if target.index == weapon.owner_id {
      continue
    }

    // Check distance
    let target_pos = target.torso.getCenterPosition()
    let dx = target_pos.getX() - weapon_pos.getX()
    let dy = target_pos.getY() - weapon_pos.getY()
    let distance = @cmath.sqrt(dx * dx + dy * dy)
    if distance > weapon.attack_range {
      continue
    }

    // Check if target is in front of weapon
    let angle_to_target = @cmath.atan2(dy, dx)
    let diff = angle_to_target - weapon.direction
    let angle_diff = if diff < 0.0 { -diff } else { diff }
    if angle_diff > 0.785 { // ~45 degrees
      continue
    }

    // Check shield
    if character_shield_blocks(target, (dx, dy)) {
      continue
    }

    // Deal damage based on body part hit
    let mut damage = 0
    if is_contact(weapon.body, target.head) {
      damage = 40
    } else if is_contact(weapon.body, target.torso) {
      damage = 30
    } else if is_contact(weapon.body, target.left_arm) ||
      is_contact(weapon.body, target.right_arm) ||
      is_contact(weapon.body, target.left_thigh) ||
      is_contact(weapon.body, target.right_thigh) {
      damage = 20
    } else if is_contact(weapon.body, target.left_shank) ||
      is_contact(weapon.body, target.right_shank) ||
      is_contact(weapon.body, target.left_forearm) ||
      is_contact(weapon.body, target.right_forearm) {
      damage = 15
    }
    if damage > 0 {
      target.control.health -= damage
      target.control.last_damage = damage
      target.control.last_hit_direction = (dx, dy)

      // Knockback
      let knockback = @box2d.b2Vec2(dx * 10.0, dy * 10.0)
      target.torso.applyImpulse(knockback, target.torso.getCenterPosition())
      if target.control.health <= 0 {
        target.control.is_faint = true
      }
    }
  }
}

///|
/// Gun weapon attack (spawns bullet)
/// 枪械武器攻击 (生成子弹)
fn weapon_attack_gun(
  weapon : Weapon,
  _character : Character,
  world : @box2d.B2World,
  bullet_type : BulletType,
) -> Unit {
  let weapon_pos = weapon.body.getCenterPosition()

  // Calculate bullet spawn position (in front of weapon)
  let spawn_offset = 0.6
  let spawn_x = weapon_pos.getX() + @cmath.cos(weapon.direction) * spawn_offset
  let spawn_y = weapon_pos.getY() + @cmath.sin(weapon.direction) * spawn_offset

  // Calculate bullet direction
  let dir_x = @cmath.cos(weapon.direction)
  let dir_y = @cmath.sin(weapon.direction)

  // Create bullet
  let damage = match bullet_type {
    Explosive => 50
    _ => 20
  }
  let lifetime = 180 // 3 seconds at 60fps
  create_bullet(
    world,
    weapon.owner_id,
    (spawn_x, spawn_y),
    (dir_x, dir_y),
    weapon.initial_bullet_speed,
    damage,
    bullet_type,
    lifetime,
  )
  |> ignore
}

///|
/// Laser weapon attack (instant hit)
/// 激光武器攻击 (即时命中)
fn weapon_attack_laser(
  weapon : Weapon,
  _character : Character,
  all_characters : Array[Character],
) -> Unit {
  let weapon_pos = weapon.body.getCenterPosition()

  // Find first target in line of sight
  let mut closest_target : Int = -1
  let mut closest_distance = weapon.attack_range
  for i = 0; i < all_characters.length(); i = i + 1 {
    let target = all_characters[i]
    if target.index == weapon.owner_id {
      continue
    }
    let target_pos = target.torso.getCenterPosition()
    let dx = target_pos.getX() - weapon_pos.getX()
    let dy = target_pos.getY() - weapon_pos.getY()
    let distance = @cmath.sqrt(dx * dx + dy * dy)
    if distance > weapon.attack_range {
      continue
    }

    // Check if target is in line of sight
    let angle_to_target = @cmath.atan2(dy, dx)
    let diff = angle_to_target - weapon.direction
    let angle_diff = if diff < 0.0 { -diff } else { diff }
    if angle_diff < 0.1 && distance < closest_distance {
      closest_target = i
      closest_distance = distance
    }
  }

  // Apply damage to closest target
  if closest_target >= 0 {
    let target = all_characters[closest_target]
    let target_pos = target.torso.getCenterPosition()
    let dx = target_pos.getX() - weapon_pos.getX()
    let dy = target_pos.getY() - weapon_pos.getY()

    // Check shield
    if not(character_shield_blocks(target, (dx, dy))) {
      target.control.health -= 5 // Laser does continuous low damage
      target.control.last_damage = 5
      target.control.last_hit_direction = (dx, dy)
      if target.control.health <= 0 {
        target.control.is_faint = true
      }
    }
  }
}

///|
/// Drop weapon to ground
/// 将武器丢到地上
pub fn weapon_drop(
  weapon : Weapon,
  _character : Character,
  _world : @box2d.B2World,
) -> Unit {
  weapon.owner_id = -1

  // Weapon will fall due to gravity
  weapon.body.setLinearVelocity(@box2d.b2Vec2(0.0, 0.0))
}

///|
/// Throw weapon
/// 扔出武器
pub fn weapon_throw(
  weapon : Weapon,
  _character : Character,
  direction : (Double, Double),
) -> Unit {
  weapon.owner_id = -1

  // Apply throwing force
  let dx = direction.0
  let dy = direction.1
  let mag = @cmath.sqrt(dx * dx + dy * dy)
  let norm_dx = if mag > 0.0001 { dx / mag } else { 1.0 }
  let norm_dy = if mag > 0.0001 { dy / mag } else { 0.0 }
  let throw_force = 20.0
  let throw_vel = @box2d.b2Vec2(norm_dx * throw_force, norm_dy * throw_force)
  weapon.body.setLinearVelocity(throw_vel)
}

///|
/// Clear all weapons
/// 清空所有武器
pub fn clear_weapons(world : @box2d.B2World) -> Unit {
  for weapon in weapon_list.val {
    world.destroyBody(weapon.body)
  }
  weapon_list.val = Array::new()
  weapon_index.val = 0
}
