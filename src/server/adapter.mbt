///| Character-Particle Adapter
/// 角色与火柴人的适配器 - 为了兼容旧的动作函数

///|
/// Convert Character to Particle for compatibility
/// 将新的Character转换为旧的Particle以保持兼容性
fn character_to_particle(character : Character) -> Particle {
  Particle::{
    torso: character.torso,
    head: character.head,
    left_thigh: character.left_thigh,
    right_thigh: character.right_thigh,
    left_shank: character.left_shank,
    right_shank: character.right_shank,
    thigh_left_joint: character.thigh_left_joint,
    thigh_right_joint: character.thigh_right_joint,
    knee_left_joint: character.knee_left_joint,
    knee_right_joint: character.knee_right_joint,
    neck_joint: character.neck_joint,
    left_forearm: character.left_forearm,
    right_forearm: character.right_forearm,
    left_arm: character.left_arm,
    right_arm: character.right_arm,
    arm_left_joint: character.arm_left_joint,
    arm_right_joint: character.arm_right_joint,
    forearm_left_joint: character.forearm_left_joint,
    forearm_right_joint: character.forearm_right_joint,
    index: character.index,
    control: create_particle_control_from_character(character),
  }
}

///|
/// Create ParticleControl from Character
/// 从Character创建ParticleControl
fn create_particle_control_from_character(
  character : Character,
) -> ParticleControl {
  ParticleControl::{
    walk_state: character.control.walk_state,
    walk_direction: character.control.walk_direction,
    walk_cooldown: character.control.walk_cooldown,
    jump_cooldown: character.control.jump_cooldown,
    jump_state: character.control.jump_state,
    jump_frame_count: character.control.jump_frame_count,
    health: character.control.health,
    is_faint: character.control.is_faint,
  }
}

///|
/// Sync particle control back to character
/// 将Particle的控制状态同步回Character
fn sync_particle_to_character(
  particle : Particle,
  character : Character,
) -> Unit {
  character.control.walk_state = particle.control.walk_state
  character.control.walk_direction = particle.control.walk_direction
  character.control.walk_cooldown = particle.control.walk_cooldown
  character.control.jump_cooldown = particle.control.jump_cooldown
  character.control.jump_state = particle.control.jump_state
  character.control.jump_frame_count = particle.control.jump_frame_count
  character.control.health = particle.control.health
  character.control.is_faint = particle.control.is_faint
}

///|
/// Wrapper for particle_walk that works with Character
/// particle_walk的包装器，使其能与Character一起工作
pub fn character_walk(character : Character, direction : Double) -> Unit {
  let particle = character_to_particle(character)
  particle_walk(particle, direction)
  sync_particle_to_character(particle, character)
}

///|
/// Wrapper for particle_stand that works with Character
/// particle_stand的包装器，使其能与Character一起工作
pub fn character_stand(character : Character) -> Unit {
  let particle = character_to_particle(character)
  particle_stand(particle)
  sync_particle_to_character(particle, character)
}

///|
/// Wrapper for particle_jump that works with Character
/// particle_jump的包装器，使其能与Character一起工作
pub fn character_jump(character : Character, direction : Double) -> Unit {
  let particle = character_to_particle(character)
  particle_jump(particle, direction)
  sync_particle_to_character(particle, character)
}
