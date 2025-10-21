// drone 
pub struct Drone {
id : Int
hp : Double
hp_limit : Double
body : @box2d.B2Body
mut action_type : ActionType
// weapon : Gun?           // 默认能发射子弹
mut target_particle_id : Int // 追踪的玩家ID
field_of_view : Double   // 视野范围
attack_range : Double    // 攻击范围
mut move_direction : Double  // 移动方向：1.0 向右，-1.0 向左
x_move_speed : Double      // 水平移动速度
}

pub impl EnemyTrait for Drone with update(self : Drone, game: Game) -> Unit {
  // 更新操作
  self.update_doing(game)
  // 无论状态如何都执行移动行为
  self.move_behavior(game)
  
}

pub impl EnemyTrait for Drone with destroy(self : Drone, game: Game) -> Unit {

  // 销毁物理体
  game.world.destroyBody(self.body)
  
  // 从敌人列表中移除
  game.enemy_list[self.id] = None
}

pub impl EnemyTrait for Drone with is_dead(self : Drone) -> Bool {
  self.hp <= 0.0
}

pub impl EnemyTrait for Drone with get_hp(self : Drone) -> Double {
  self.hp
}

pub impl EnemyTrait for Drone with get_hp_limit(self : Drone) -> Double {
  self.hp_limit
}

fn Drone::update_doing(self : Drone, game : Game) -> Unit {
  // 找到最近的玩家瞄准
  let (distance, index) = self.find_nearest_target(game)

  if self.target_particle_id >= 0 && distance <= self.attack_range {
    self.action_type = Attack
  } else {
    self.action_type = Patrol
  }
  // 根据当前状态执行行为
  match self.action_type {
    // Patrol 状态下什么也不做
    Patrol => ()
    Attack => self.attack(game, index)
    Pursuit => ()  // Pursuit 状态暂不实现特殊行为
  }
}

// 检查当前目标是否有效
// fn Drone::is_target_valid(self : Drone, game : Game) -> Bool {
//   // 无效 ID
//   if self.target_particle_id < 0 || self.target_particle_id >= game.particle_list.length() {
//     return false
//   }
  
//   /// 从游戏的玩家列表中获取目标，并检查目标是否仍然存活（生命值大于0）。

//   let target = game.particle_list[self.target_particle_id]
//   target.control.health > 0
// }

// 计算到目标的距离
fn Drone::find_nearest_target(self : Drone, game : Game) -> (Double, Int) {
  let mut nearest_index : Int? = None
  let mut nearest_distance : Double = self.field_of_view + 1.0
  
  for particle in game.particle_list {
    let distance = self.get_distance_to_target(particle.index, game)

    if distance <= self.field_of_view && distance < nearest_distance && particle.control.health > 0 {
      nearest_distance = distance
      nearest_index = Some(particle.index)
    }
  }

  match nearest_index {
    Some(id) => self.target_particle_id = id
    None => self.target_particle_id = -1
  }

  (nearest_distance, self.target_particle_id)
}

// 计算到指定玩家的距离
fn Drone::get_distance_to_target(self : Drone, target_id : Int, game : Game) -> Double {
  let target = game.particle_list[target_id]
  let dx = target.torso.getCenterPosition().getX() - self.body.getCenterPosition().getX()
  let dy = target.torso.getCenterPosition().getY() - self.body.getCenterPosition().getY()
  @cmath.sqrt(dx * dx + dy * dy)
}

///|
/// 无人机攻击目标
/// 直接向目标发射子弹，不需要装备枪械
/// 
/// 参数：
/// - game: 游戏实例
/// - target_id: 目标玩家 ID
fn Drone::attack(self : Drone, game : Game, target_id : Int) -> Unit {
  if target_id < 0 || target_id >= game.particle_list.length() {
    return
  }
  
  let target = game.particle_list[target_id]
  
  // 跳过死亡目标
  if target.control.health <= 0 {
    return
  }
  
  // 获取无人机和目标位置
  let drone_pos = self.body.getCenterPosition()
  let target_pos = target.torso.getCenterPosition()
  
  // 计算方向和距离
  let dx = target_pos.getX() - drone_pos.getX()
  let dy = target_pos.getY() - drone_pos.getY()
  let distance = @cmath.sqrt(dx * dx + dy * dy)
  
  // 检查射击冷却（每 30 帧射击一次）
  if game.frame_count % 30 != 0 {
    return
  }
  
  // 归一化方向向量
  if distance < 0.1 {
    return  // 距离太近，不射击
  }
  
  let dir_x = dx / distance
  let dir_y = dy / distance
  
  // 计算子弹速度（朝向目标）
  let bullet_speed = 50.0
  let velocity = (dir_x * bullet_speed, dir_y * bullet_speed)
  
  // 发射位置：无人机中心向目标方向偏移一点
  let spawn_offset = 0.5
  let spawn_x = drone_pos.getX() + dir_x * spawn_offset
  let spawn_y = drone_pos.getY() + dir_y * spawn_offset
  let position = (spawn_x, spawn_y)
  
  // 创建子弹（直接使用 Game 的子弹系统）
  // create_bullet 需要按顺序传递：position, velocity, owner_id, 然后是可选参数
  game.create_bullet(
    position,                       // 位置
    velocity,                       // 速度
    self.id,                        // 无人机自己的 ID
    damage=8,                       // 无人机伤害较低
    max_distance=50.0,              // 中等射程
    target_types=[Player],          // 只攻击玩家
    penetration=0,                  // 不穿透
    gravity_compensation=0.92       // 轻微下坠
  ) |> ignore
  
  println("无人机 #\{self.id} 向玩家 #\{target_id} 射击!")
}

///|
/// 无人机移动行为
/// 左右来回巡逻，碰到边界或障碍物就反向
fn Drone::move_behavior(self : Drone, game : Game) -> Unit {
  // 获取当前位置
  let pos = self.body.getCenterPosition()
  let x = pos.getX()
  let y = pos.getY()
  
  // 抵消重力（让无人机能够悬停）
  // Box2D 重力加速度是 9.8 m/s²
  let mass = self.body.getMass()
  let anti_gravity = @box2d.b2Vec2(0.0, mass * 9.8)
  self.body.applyForce(anti_gravity, pos)
  
  // 计算世界边界（从像素转换到物理单位）
  let ppm = 20.0  // PPM 常量
  let half_width = VIEWPORT_WIDTH / ppm / 4.0   // 世界宽度的一半
  
  // 设置边界留白（避免紧贴边缘）
  let margin = 0.2
  let left_boundary = -half_width + margin
  let right_boundary = half_width - margin
  
  // 检测碰撞边界，反向移动
  if x <= left_boundary && self.move_direction < 0.0 {
    // 碰到左边界，向右移动
    self.move_direction = 1.0
  } else if x >= right_boundary && self.move_direction > 0.0 {
    // 碰到右边界，向左移动
    self.move_direction = -1.0
  }
  
  // 检测与平台的碰撞
  for platform in game.platform_list {
    if game.is_contact(self.body, platform.body) {
      // 碰到平台，立即反向并推开
      self.move_direction = -self.move_direction
      break
    }
  }
  
  // 保留垂直速度，只改变水平速度
  let current_vel = self.body.getLinearVelocity()
  let target_vx = self.move_direction * self.x_move_speed
  let vy = current_vel.getY()
  // 直接设置为目标速度（匀速）
  self.body.setLinearVelocity(@box2d.b2Vec2(target_vx, vy))
}

///|
/// 创建无人机
/// 
/// 参数：
/// - game: 游戏实例
/// - position: 生成位置 (x, y)，默认为屏幕中央上方
/// 
/// 返回：创建是否成功
pub fn Game::create_drone(
  self : Game,
  position? : (Double, Double) = (0.0, 20.0)
) -> Bool {
  // 创建圆形物理体定义（无人机的形状）
  let circle_def = @box2d.b2CircleDef()
  circle_def.setRadius(0.3)          // 半径 1 米
  circle_def.setDensity(0.3)         // 较轻（飞行器）
  circle_def.setFriction(0.1)        // 低摩擦
  circle_def.setRestitution(0.3)     // 中等弹性
  circle_def.setGroupIndex(-3)       // 独立碰撞组
  circle_def.setLocalPosition(@box2d.b2Vec2(0.0, 0.0))
  
  // 创建 body 定义
  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(circle_def.getBase())
  body_def.setAllowSleep(false)      // 不休眠，始终保持活跃
  body_def.setLinearDamping(0.2)     // 轻微阻尼（模拟空气阻力）
  body_def.setAngularDamping(0.5)    // 角阻尼
  
  let body = self.world.createBody(body_def)
  
  // 在敌人列表中预留位置
  self.enemy_list.push(None)
  let drone_id = self.enemy_list.length() - 1
  
  // 创建无人机实例
  let drone = Drone::{
    id: drone_id,
    hp: 80.0,
    hp_limit: 80.0,
    body: body,
    action_type: Patrol,
    target_particle_id: -1,
    field_of_view: 30.0,      // 视野范围 30 米
    attack_range: 20.0,       // 攻击范围 20 米
    move_direction: 1.0,      // 初始向右移动
    x_move_speed: 5.0.abs()      // 移动速度始终为正值
  }
  
  // 添加到敌人列表
  self.enemy_list[drone_id] = Some(drone)
  
  println("无人机创建成功！ID: \{drone_id}, 位置: (\{position.0}, \{position.1})")
  true
}

///|
/// 更新所有无人机
/// 在游戏主循环中调用
pub fn Game::update_drones(self : Game) -> Unit {
  for i = 0; i < self.enemy_list.length(); i = i + 1 {
    match self.enemy_list[i] {
      Some(enemy) => {
        // 检查是否是 Drone 类型并更新
        enemy.update(self)
        
        // 如果死亡，销毁
        if enemy.is_dead() {
          enemy.destroy(self)
        }
      }
      None => ()
    }
  }
}