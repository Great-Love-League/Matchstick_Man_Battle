///| 游戏主循环
/// 这是游戏的核心，负责协调所有游戏系统的更新

///|
/// 游戏状态枚举
pub enum GameState {
  Running // 游戏运行中
  Paused // 游戏暂停
  GameOver // 游戏结束
} derive(Eq)

///|
/// 游戏状态管理
pub struct GameManager {
  mut state : GameState
  mut frame_count : Int // 帧计数器
  mut cleanup_counter : Int // 清理计数器
}

///|
/// 全局游戏管理器
let game_manager : Ref[GameManager] = Ref::new(
  GameManager::{ state: Running, frame_count: 0, cleanup_counter: 0 },
)

///|
/// 处理玩家输入
/// @param p p5js实例
/// @param particle 玩家角色
pub fn process_player_input(p : @p5js.P5Instance, particle : Particle) -> Unit {
  // 如果玩家昏迷，不处理输入
  if particle.control.is_faint {
    return
  }

  // 移动输入处理
  if p.keyIsDown(KeyA) {
    particle_walk(particle, -1.0)
  } else if p.keyIsDown(KeyD) {
    particle_walk(particle, 1.0)
  } else if !particle.control.jump_state {
    particle_stand(particle)
  }

  // 跳跃输入处理
  if p.keyIsDown(KeyW) {
    if particle.control.jump_cooldown <= 0 {
      if !particle.control.jump_state {
        particle.control.jump_state = true
        particle.control.jump_frame_count = 0
        particle.control.jump_cooldown = j_dur_A + j_dur_B + j_dur_C
      }
    }
  }

  // 减少跳跃冷却
  if particle.control.jump_cooldown > 0 {
    particle.control.jump_cooldown -= 1
  }

  // 执行跳跃动作
  particle_jump(particle, 0.0)
}

///|
/// 更新所有人物
pub fn update_all_particles() -> Unit {
  for particle in particle_list.val {
    // 检查生命值
    if particle.control.health <= 0 && !particle.control.is_faint {
      particle.control.is_faint = true
      println("玩家 \{particle.index} 已昏迷!")
    }
  }
}

///|
/// 更新物理世界
/// @param world 物理世界
pub fn update_physics(world : @box2d.B2World) -> Unit {
  // Box2D 物理模拟步进
  // 使用与原始代码相同的参数: 1/60秒时间步长, 4次速度迭代
  world.step(1.0 / 60.0, 4)
}

///|
/// 执行清理工作
/// @param world 物理世界
pub fn perform_cleanup(world : @box2d.B2World) -> Unit {
  game_manager.val.cleanup_counter += 1

  // 每60帧（约1秒）执行一次清理
  if game_manager.val.cleanup_counter >= 60 {
    cleanup_bullets(world)
    cleanup_items(world)
    game_manager.val.cleanup_counter = 0
  }
}

///|
/// 游戏主更新循环
/// @param world 物理世界
/// 这是游戏状态更新的核心函数，按顺序调用所有子系统的更新
pub fn game_update(world : @box2d.B2World) -> Unit {
  // 检查游戏状态
  if game_manager.val.state != Running {
    return
  }

  // 1. 更新所有人物状态
  update_all_particles()

  // 2. 更新所有子弹
  update_all_bullets()

  // 3. 更新所有物品
  update_all_items()

  // 4. 更新物理世界（这会计算所有物体的新位置）
  update_physics(world)

  // 5. 执行清理工作（移除无效对象）
  perform_cleanup(world)

  // 6. 增加帧计数
  game_manager.val.frame_count += 1
}

///|
/// 游戏主循环
/// @param p p5js实例
/// @param world 物理世界
/// 这是每帧都会被调用的函数，包含完整的游戏循环逻辑
pub fn game_loop(p : @p5js.P5Instance, world : @box2d.B2World) -> Unit {
  // 第一步：处理输入
  if particle_list.val.length() > 0 {
    process_player_input(p, particle_list.val[0])
  }

  // 第二步：更新游戏状态
  game_update(world)
}

///|
/// 暂停游戏
pub fn pause_game() -> Unit {
  game_manager.val.state = Paused
  println("游戏已暂停")
}

///|
/// 恢复游戏
pub fn resume_game() -> Unit {
  game_manager.val.state = Running
  println("游戏继续")
}

///|
/// 结束游戏
pub fn end_game() -> Unit {
  game_manager.val.state = GameOver
  println("游戏结束")
}

///|
/// 重置游戏
pub fn reset_game(world : @box2d.B2World) -> Unit {
  // 清理所有子弹
  cleanup_bullets(world)

  // 清理所有物品
  cleanup_items(world)

  // 重置游戏管理器
  game_manager.val.state = Running
  game_manager.val.frame_count = 0
  game_manager.val.cleanup_counter = 0

  // 重置所有玩家状态
  for particle in particle_list.val {
    particle.control.health = 100
    particle.control.is_faint = false
    particle.control.walk_state = false
    particle.control.jump_state = false
    particle.control.jump_cooldown = -1
    particle.control.walk_cooldown = 0
  }
  println("游戏已重置")
}

///|
/// 获取当前游戏状态信息
pub fn get_game_info() -> String {
  let state_str = match game_manager.val.state {
    Running => "运行中"
    Paused => "已暂停"
    GameOver => "已结束"
  }
  "游戏状态: \{state_str}, 帧数: \{game_manager.val.frame_count}, 子弹数: \{get_active_bullet_count()}, 物品数: \{get_active_item_count()}"
}
