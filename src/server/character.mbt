///| Character System
/// 角色系统实现

///| Global character list and counter
let character_index : Ref[Int] = Ref::new(0)
let character_list : Ref[Array[Character]] = Ref::new(Array::new())

///| Create default character control
/// 创建默认角色控制状态
fn create_character_control(
  walk_state? : Bool = false,
  walk_direction? : Double = 1.0,
  walk_cooldown? : Int = 0,
  jump_cooldown? : Int = -1,
  jump_state? : Bool = false,
  jump_frame_count? : Int = 0,
  health? : Int = 100,
  max_health? : Int = 100
) -> CharacterControl {
  CharacterControl::{
    walk_state,
    walk_direction,
    walk_cooldown,
    jump_cooldown,
    jump_state,
    jump_frame_count,
    health,
    max_health,
    is_faint: false,
    shield_angle: 40.0,
    shield_max_angle: 40.0,
    shield_min_angle: 5.0,
    shield_active: false,
    shield_direction: 0.0,
    weapon_slots: Array::new(),
    current_weapon: -1,
    speed_multiplier: 1.0,
    acceleration_modifier: (0.0, 0.0),
    jump_height_multiplier: 1.0,
    last_hit_direction: (0.0, 0.0),
    last_damage: 0,
    last_attack_time: 0,
  }
}

///| Create a new character
/// 创建新角色
pub fn create_character(
  world : @box2d.B2World,
  position : (Double, Double),
  skin_id? : Int = 0
) -> Character {
  character_index.val += 1
  
  // Create body parts
  let torso = create_dynamic_box(world, position, (0.25, 1.0), density=1.0, groupindex=-character_index.val)
  let head = create_dynamic_box(world, (position.0, position.1 + 1.5), (0.2, 0.25), density=1.0, groupindex=-character_index.val)
  let left_thigh = create_dynamic_box(world, (position.0, position.1 - 1.0), (0.15, 0.5), density=1.0, groupindex=-character_index.val)
  let right_thigh = create_dynamic_box(world, (position.0, position.1 - 1.0), (0.15, 0.5), density=1.0, groupindex=-character_index.val)
  let left_shank = create_dynamic_box(world, (position.0, position.1 - 2.0), (0.15, 0.5), density=1.0, groupindex=-character_index.val, friciton=0.2)
  let right_shank = create_dynamic_box(world, (position.0, position.1 - 2.0), (0.15, 0.5), density=1.0, groupindex=-character_index.val, friciton=0.2)
  let left_arm = create_dynamic_box(world, (position.0, position.1 + 0.5), (0.15, 0.5), density=1.0, groupindex=-character_index.val)
  let right_arm = create_dynamic_box(world, (position.0, position.1 + 0.5), (0.15, 0.5), density=1.0, groupindex=-character_index.val)
  let left_forearm = create_dynamic_box(world, (position.0, position.1 - 0.25), (0.15, 0.5), density=1.0, groupindex=-character_index.val)
  let right_forearm = create_dynamic_box(world, (position.0, position.1 - 0.25), (0.15, 0.5), density=1.0, groupindex=-character_index.val)
  
  // Create joints
  let neck_joint = create_joint(world, torso, head, (position.0, position.1 + 1.0), enable_limit=true, lower_angle=0.0, upper_angle=0.0)
  let thigh_left_joint = create_joint(world, torso, left_thigh, (position.0, position.1 - 0.5), enable_limit=true, lower_angle=-1.0, upper_angle=1.0)
  let thigh_right_joint = create_joint(world, torso, right_thigh, (position.0, position.1 - 0.5), enable_limit=true, lower_angle=-1.0, upper_angle=1.0)
  let knee_left_joint = create_joint(world, left_thigh, left_shank, (position.0, position.1 - 1.5), enable_limit=true, lower_angle=-1.3, upper_angle=1.3)
  let knee_right_joint = create_joint(world, right_thigh, right_shank, (position.0, position.1 - 1.5), enable_limit=true, lower_angle=-1.3, upper_angle=1.3)
  let arm_left_joint = create_joint(world, torso, left_arm, (position.0, position.1 + 1.0), enable_limit=true, lower_angle=-1.0, upper_angle=1.0)
  let arm_right_joint = create_joint(world, torso, right_arm, (position.0, position.1 + 1.0), enable_limit=true, lower_angle=-1.0, upper_angle=1.0)
  let forearm_left_joint = create_joint(world, left_arm, left_forearm, (position.0, position.1), enable_limit=true, lower_angle=-1.3, upper_angle=1.3)
  let forearm_right_joint = create_joint(world, right_arm, right_forearm, (position.0, position.1), enable_limit=true, lower_angle=-1.3, upper_angle=1.3)
  
  let index = character_index.val - 1
  let character = Character::{
    torso,
    head,
    left_thigh,
    right_thigh,
    left_shank,
    right_shank,
    left_arm,
    right_arm,
    left_forearm,
    right_forearm,
    thigh_left_joint,
    thigh_right_joint,
    knee_left_joint,
    knee_right_joint,
    neck_joint,
    arm_left_joint,
    arm_right_joint,
    forearm_left_joint,
    forearm_right_joint,
    index,
    skin_id,
    control: create_character_control(),
  }
  
  character_list.val.push(character)
  character
}

///| Update character state
/// 更新角色状态
pub fn update_character(character : Character, delta_time : Double) -> Unit {
  // Update shield recovery when not active
  if not(character.control.shield_active) {
    let recovery_rate = 3.0 + character.control.speed_multiplier * 0.1
    let new_angle = character.control.shield_angle + recovery_rate * delta_time
    character.control.shield_angle = if new_angle < character.control.shield_max_angle {
      new_angle
    } else {
      character.control.shield_max_angle
    }
  }
  
  // Decay special effects
  if character.control.speed_multiplier != 1.0 {
    character.control.speed_multiplier = character.control.speed_multiplier * 0.99 + 0.01
  }
  
  if character.control.acceleration_modifier.0 != 0.0 {
    character.control.acceleration_modifier = (
      character.control.acceleration_modifier.0 * 0.95,
      character.control.acceleration_modifier.1 * 0.95
    )
  }
  
  if character.control.jump_height_multiplier != 1.0 {
    character.control.jump_height_multiplier = character.control.jump_height_multiplier * 0.99 + 0.01
  }
}

///| Character picks up weapon
/// 角色拾取武器
pub fn character_pickup_weapon(character : Character, weapon_id : Int) -> Bool {
  // Check if inventory is full (max 2 weapons)
  if character.control.weapon_slots.length() >= 2 {
    return false
  }
  
  character.control.weapon_slots.push(weapon_id)
  
  // Set as current weapon if no weapon equipped
  if character.control.current_weapon == -1 {
    character.control.current_weapon = 0
  }
  
  true
}

///| Character drops current weapon
/// 角色丢弃当前武器
pub fn character_drop_weapon(character : Character) -> Int {
  if character.control.current_weapon == -1 {
    return -1
  }
  
  let weapon_id = character.control.weapon_slots[character.control.current_weapon]
  character.control.weapon_slots.remove(character.control.current_weapon) |> ignore
  
  // Adjust current weapon index
  if character.control.weapon_slots.length() == 0 {
    character.control.current_weapon = -1
  } else if character.control.current_weapon >= character.control.weapon_slots.length() {
    character.control.current_weapon = character.control.weapon_slots.length() - 1
  }
  
  weapon_id
}

///| Character switches weapon
/// 角色切换武器
pub fn character_switch_weapon(character : Character) -> Unit {
  if character.control.weapon_slots.length() <= 1 {
    return
  }
  
  character.control.current_weapon = (character.control.current_weapon + 1) % character.control.weapon_slots.length()
}

///| Get current weapon ID
/// 获取当前武器ID
pub fn character_get_current_weapon(character : Character) -> Int {
  if character.control.current_weapon == -1 {
    return -1
  }
  
  character.control.weapon_slots[character.control.current_weapon]
}

///| Activate shield
/// 激活护盾
pub fn character_activate_shield(character : Character, mouse_direction : (Double, Double)) -> Unit {
  if character.control.shield_angle < character.control.shield_min_angle {
    return
  }
  
  character.control.shield_active = true
  
  // Calculate shield direction
  let dx = mouse_direction.0
  let dy = mouse_direction.1
  let angle = @cmath.atan2(dy, dx)
  character.control.shield_direction = angle
}

///| Deactivate shield
/// 关闭护盾
pub fn character_deactivate_shield(character : Character) -> Unit {
  character.control.shield_active = false
}

///| Check if shield blocks damage from direction
/// 检查护盾是否能阻挡来自某方向的伤害
pub fn character_shield_blocks(character : Character, attack_direction : (Double, Double)) -> Bool {
  if not(character.control.shield_active) {
    return false
  }
  
  if character.control.shield_angle < character.control.shield_min_angle {
    return false
  }
  
  // Calculate attack angle
  let dx = attack_direction.0
  let dy = attack_direction.1
  let attack_angle = @cmath.atan2(dy, dx)
  
  // Check if attack is within shield arc
  let diff = attack_angle - character.control.shield_direction
  let angle_diff = if diff < 0.0 { -diff } else { diff }
  let half_shield_arc = character.control.shield_angle * 3.14159 / 180.0 / 2.0
  
  if angle_diff <= half_shield_arc {
    // Shield blocks, consume shield angle
    let new_shield = character.control.shield_angle - 5.0
    character.control.shield_angle = if new_shield > 0.0 {
      new_shield
    } else {
      0.0
    }
    return true
  }
  
  false
}

///| Clear all characters
/// 清空所有角色
pub fn clear_characters(world : @box2d.B2World) -> Unit {
  for character in character_list.val {
    world.destroyBody(character.torso)
    world.destroyBody(character.head)
    world.destroyBody(character.left_thigh)
    world.destroyBody(character.right_thigh)
    world.destroyBody(character.left_shank)
    world.destroyBody(character.right_shank)
    world.destroyBody(character.left_arm)
    world.destroyBody(character.right_arm)
    world.destroyBody(character.left_forearm)
    world.destroyBody(character.right_forearm)
  }
  character_list.val = Array::new()
  character_index.val = 0
}
