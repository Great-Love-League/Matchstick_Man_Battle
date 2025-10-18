///| Game Types - Core game entity definitions
/// 定义游戏的核心类型和数据结构

///| Character/Player State
/// 角色控制状态
pub struct CharacterControl {
  // Movement state
  mut walk_state : Bool
  mut walk_direction : Double
  mut walk_cooldown : Int
  mut jump_cooldown : Int
  mut jump_state : Bool
  mut jump_frame_count : Int
  
  // Health state
  mut health : Int
  mut max_health : Int
  mut is_faint : Bool // 是否昏厥
  
  // Shield state
  mut shield_angle : Double // 当前护盾角度 (degrees)
  mut shield_max_angle : Double // 最大护盾角度
  mut shield_min_angle : Double // 最小护盾角度
  mut shield_active : Bool // 护盾是否激活
  mut shield_direction : Double // 护盾朝向 (radians, 指向鼠标)
  
  // Equipment
  mut weapon_slots : Array[Int] // 武器ID列表
  mut current_weapon : Int // 当前武器索引 (-1表示无武器)
  
  // Physics modifiers
  mut speed_multiplier : Double // 速度倍数
  mut acceleration_modifier : (Double, Double) // 加速度修正
  mut jump_height_multiplier : Double // 跳跃高度倍数
  
  // Combat state
  mut last_hit_direction : (Double, Double) // 受击方向
  mut last_damage : Int // 受击伤害
  mut last_attack_time : Int // 上次攻击时间 (帧数)
}

///| Character/Player Entity
/// 火柴人角色实体
pub struct Character {
  // Body parts
  torso : @box2d.B2Body
  head : @box2d.B2Body
  left_thigh : @box2d.B2Body
  right_thigh : @box2d.B2Body
  left_shank : @box2d.B2Body
  right_shank : @box2d.B2Body
  left_arm : @box2d.B2Body
  right_arm : @box2d.B2Body
  left_forearm : @box2d.B2Body
  right_forearm : @box2d.B2Body
  
  // Joints
  thigh_left_joint : @box2d.B2Joint
  thigh_right_joint : @box2d.B2Joint
  knee_left_joint : @box2d.B2Joint
  knee_right_joint : @box2d.B2Joint
  neck_joint : @box2d.B2Joint
  arm_left_joint : @box2d.B2Joint
  arm_right_joint : @box2d.B2Joint
  forearm_left_joint : @box2d.B2Joint
  forearm_right_joint : @box2d.B2Joint
  
  // Identification
  index : Int
  mut skin_id : Int // 皮肤ID
  
  // Control state
  control : CharacterControl
}

///| Weapon Types
pub enum WeaponType {
  Melee // 近战武器 (刀剑)
  Gun // 常规枪械
  Grenade // 榴弹
  Laser // 激光
}

///| Weapon Entity
/// 武器实体
pub struct Weapon {
  mut id : Int
  mut owner_id : Int // -1表示掉落在地上
  mut weapon_type : WeaponType
  mut body : @box2d.B2Body
  
  // Weapon stats
  mut ammo_count : Int // 子弹数量 (-1表示无限)
  mut initial_bullet_speed : Double // 子弹初速
  mut recoil : Double // 后坐力
  mut min_attack_interval : Int // 最小攻击间隔 (帧数)
  mut is_automatic : Bool // 是否自动连发
  mut attack_range : Double // 攻击范围 (近战/激光)
  mut weight : Double // 重量
  
  // State
  mut last_fire_time : Int // 上次开火时间
  mut direction : Double // 武器指向 (radians)
}

///| Bullet Types
pub enum BulletType {
  Normal // 普通子弹
  Explosive // 爆炸物
  Piercing // 穿透
  Special // 特殊效果 (减速等)
}

///| Bullet Entity
/// 子弹实体
pub struct Bullet {
  mut id : Int
  mut owner_id : Int // 发射者ID
  mut bullet_type : BulletType
  mut body : @box2d.B2Body
  
  // Bullet stats
  mut damage : Int // 伤害值
  mut explosion_radius : Double // 爆炸半径 (0表示无爆炸)
  mut speed : Double // 移动速度
  mut acceleration : (Double, Double) // 加速度
  mut lifetime : Int // 剩余生命周期 (帧数)
  mut max_lifetime : Int // 最大生命周期
  
  // Special effects
  mut speed_effect : Double // 对目标速度的影响 (倍数)
  mut acceleration_effect : (Double, Double) // 对目标加速度的影响
  mut jump_effect : Double // 对跳跃的影响
  
  // State
  mut is_active : Bool // 是否活跃
}

///| Item Types
pub enum ItemType {
  WeaponPickup(Int) // 武器拾取 (weapon_id)
  HealthPack(Int) // 血包 (heal_amount)
  AmmoBox(Int) // 弹药箱 (ammo_amount)
}

///| Item Entity
/// 拾取物品实体
pub struct Item {
  mut id : Int
  mut item_type : ItemType
  mut body : @box2d.B2Body
  mut is_collected : Bool // 是否已被拾取
}

///| Platform/Environment Entity
/// 平台/环境实体
pub struct Platform {
  body : @box2d.B2Body
  index : Int
  
  // Environmental properties
  mut health : Int // 耐久度 (-1表示不可破坏)
  mut max_health : Int
  mut friction : Double // 摩擦力
  mut velocity : (Double, Double) // 速度 (可移动平台)
  mut acceleration : (Double, Double) // 加速度
}

///| Input State
/// 输入状态
pub struct InputState {
  // Movement
  mut move_left : Bool
  mut move_right : Bool
  mut jump : Bool
  
  // Actions
  mut attack : Bool
  mut shield : Bool
  mut pickup : Bool
  mut drop_weapon : Bool
  mut throw_weapon : Bool
  mut switch_weapon : Bool
  
  // Mouse
  mut mouse_x : Double
  mut mouse_y : Double
  mut mouse_pressed : Bool
  mut mouse_right_pressed : Bool
}

///| Game State
/// 游戏状态
pub struct GameState {
  mut frame_count : Int // 总帧数
  mut is_running : Bool // 游戏是否运行中
  mut delta_time : Double // 帧时间间隔
  
  // Entity lists
  characters : Ref[Array[Character]]
  weapons : Ref[Array[Weapon]]
  bullets : Ref[Array[Bullet]]
  items : Ref[Array[Item]]
  platforms : Ref[Array[Platform]]
  
  // Physics world
  world : Ref[@box2d.B2World]
  
  // Input
  inputs : Array[InputState] // 每个玩家的输入
}
