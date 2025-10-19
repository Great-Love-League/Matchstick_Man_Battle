///| Bullet System - 子弹系统
/// 管理子弹创建、更新、碰撞检测和销毁
/// 支持受击对象列表，精确控制哪些实体会受到伤害

///|
/// 受击目标类型枚举
pub enum TargetType {
  Player      // 玩家角色
  Enemy       // 敌人
  AllCharacters  // 所有角色（玩家+敌人）
} derive(Show, Eq)

///|
/// 子弹结构体
pub struct Bullet {
  id : Int                        // 子弹唯一ID
  owner_id : Int                  // 发射者ID（避免自伤）
  body : @box2d.B2Body           // Box2D物理刚体
  damage : Int                    // 基础伤害值
  max_distance : Double           // 最大射程
  mut traveled_distance : Double  // 已飞行距离
  start_position : (Double, Double) // 起始位置
  mut is_active : Bool           // 是否激活
  target_types : Array[TargetType] // 受击目标列表
  mut hit_targets : Array[Int]   // 已命中的目标ID（防止穿透时重复伤害）
  mut penetration : Int           // 剩余穿透次数（0表示不穿透）
}

///|
/// 创建子弹
/// 
/// @param position 子弹起始位置 (x, y)
/// @param velocity 子弹速度向量 (vx, vy)
/// @param owner_id 发射者ID，用于避免自伤
/// @param damage 基础伤害值，默认10
/// @param max_distance 最大射程，默认50.0
/// @param target_types 受击目标列表，默认[Player]，即只伤害其他玩家
/// @param penetration 穿透次数，默认0（不穿透）
/// @return 创建的子弹对象
fn Game::create_bullet(
  self : Self,
  position : (Double, Double),
  velocity : (Double, Double),
  owner_id : Int,
  damage? : Int = 10,
  max_distance? : Double = 50.0,
  target_types? : Array[TargetType] = [Player],
  penetration? : Int = 0,
) -> Bullet {
  // 创建圆形子弹物理体
  let circle_def = @box2d.b2CircleDef()
  circle_def.setRadius(0.1)
  circle_def.setDensity(0.5)
  circle_def.setFriction(0.1)
  circle_def.setGroupIndex(-2)  // 独立碰撞组
  circle_def.setLocalPosition(@box2d.b2Vec2(0.0, 0.0))
  
  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(circle_def.getBase())
  body_def.setAllowSleep(false)
  
  let body = self.world.createBody(body_def)
  body.setLinearVelocity(@box2d.b2Vec2(velocity.0, velocity.1))
  
  let bullet_id = self.bullet_list.length()
  let bullet = Bullet::{
    id: bullet_id,
    owner_id,
    body,
    damage,
    max_distance,
    traveled_distance: 0.0,
    start_position: position,
    is_active: true,
    target_types,
    hit_targets: Array::new(),
    penetration,
  }
  
  self.bullet_list.push(bullet)
  println("创建子弹 #\{bullet_id}: 位置(\{position.0}, \{position.1}), 伤害\{damage}, 目标\{target_types}")
  bullet
}

fn Game::update_bullet(self : Self, bullet : Bullet) -> Unit {
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
  
  self.check_bullet_collision(bullet)
}

///|
/// 检测子弹与角色的碰撞
/// 根据受击对象列表过滤目标
fn Game::check_bullet_collision(self : Self, bullet : Bullet) -> Unit {
  // 检查玩家角色（如果目标包含Player或AllCharacters）
  let mut should_hit_players = false
  for target_type in bullet.target_types {
    if target_type == Player || target_type == AllCharacters {
      should_hit_players = true
      break
    }
  }
  
  if should_hit_players {
    for particle in self.particle_list {
      // 跳过发射者
      if particle.index == bullet.owner_id {
        continue
      }
      
      // 跳过已经命中的目标（穿透时）
      let mut already_hit = false
      for hit_id in bullet.hit_targets {
        if hit_id == particle.index {
          already_hit = true
          break
        }
      }
      if already_hit {
        continue
      }
      
      // 跳过昏迷的角色
      if particle.control.faint_state {
        continue
      }
      
      let mut hit = false
      let mut damage = 0
      
      // 根据命中部位计算伤害倍率
      if self.is_contact(particle.head, bullet.body) {
        damage = bullet.damage * 2  // 头部 2.0x
        hit = true
      } else if self.is_contact(particle.torso, bullet.body) {
        damage = bullet.damage  // 躯干 1.0x
        hit = true
      } else if self.is_contact(particle.left_thigh, bullet.body) ||
                self.is_contact(particle.right_thigh, bullet.body) {
        damage = bullet.damage / 2  // 大腿 0.5x
        hit = true
      } else if self.is_contact(particle.left_shank, bullet.body) ||
                self.is_contact(particle.right_shank, bullet.body) {
        damage = bullet.damage / 3  // 小腿 0.33x
        hit = true
      } else if self.is_contact(particle.left_arm, bullet.body) ||
                self.is_contact(particle.right_arm, bullet.body) {
        damage = bullet.damage / 2  // 大臂 0.5x
        hit = true
      } else if self.is_contact(particle.left_forearm, bullet.body) ||
                self.is_contact(particle.right_forearm, bullet.body) {
        damage = bullet.damage / 3  // 前臂 0.33x
        hit = true
      }
      
      if hit {
        // 应用伤害
        particle.control.health -= damage
        println("子弹 #\{bullet.id} 击中玩家 \{particle.index}, 伤害 \{damage} (剩余血量: \{particle.control.health})")
        
        if particle.control.health <= 0 {
          particle.control.faint_state = true
          println("玩家 \{particle.index} 被击倒!")
        }
        
        // 记录已命中目标
        bullet.hit_targets.push(particle.index)
        
        // 检查穿透
        if bullet.penetration <= 0 {
          bullet.is_active = false
          break
        } else {
          bullet.penetration -= 1
          println("子弹 #\{bullet.id} 穿透! 剩余穿透次数: \{bullet.penetration}")
        }
      }
    }
  }
  
  // TODO: 检查敌人（如果目标包含Enemy或AllCharacters）
  // let mut should_hit_enemies = false
  // for target_type in bullet.target_types {
  //   if target_type == Enemy || target_type == AllCharacters {
  //     should_hit_enemies = true
  //     break
  //   }
  // }
  // if should_hit_enemies {
  //   for enemy in self.enemy_list {
  //     // 类似玩家的碰撞检测逻辑
  //   }
  // }
}

fn Game::update_all_bullets(self : Self) -> Unit {
  for bullet in self.bullet_list {
    if bullet.is_active {
      self.update_bullet(bullet)
    }
  }
}

fn Game::cleanup_bullets(self : Self) -> Unit {
  let active_bullets : Array[Bullet] = Array::new()
  
  for bullet in self.bullet_list {
    if bullet.is_active {
      active_bullets.push(bullet)
    } else {
      self.world.destroyBody(bullet.body)
    }
  }
  
  self.bullet_list = active_bullets
}

///|
/// 从玩家位置射击子弹（快捷方法）
/// 
/// @param player_index 玩家索引
/// @param direction 射击方向（-1.0 左，1.0 右）
fn Game::shoot_bullet(self : Self, player_index : Int, direction : Double) -> Unit {
  if player_index >= self.particle_list.length() {
    return
  }
  
  let particle = self.particle_list[player_index]
  
  // 从右前臂位置发射
  let hand_pos = particle.right_forearm.getCenterPosition()
  let position = (hand_pos.getX(), hand_pos.getY())
  
  // 计算速度
  let speed = 20.0
  let velocity = (direction * speed, 0.0)
  
  // 创建普通子弹：伤害10，射程50，只打其他玩家
  self.create_bullet(
    position, 
    velocity, 
    player_index, 
    damage=10, 
    max_distance=50.0,
    target_types=[Player],
    penetration=0
  ) |> ignore
  
  println("玩家 \{player_index} 发射了普通子弹")
}

///|
/// 创建穿透子弹（高级用法）
/// 
/// @param player_index 玩家索引
/// @param direction 射击方向
/// @param penetration_count 穿透次数
fn Game::shoot_penetrating_bullet(
  self : Self, 
  player_index : Int, 
  direction : Double,
  penetration_count : Int
) -> Unit {
  if player_index >= self.particle_list.length() {
    return
  }
  
  let particle = self.particle_list[player_index]
  let hand_pos = particle.right_forearm.getCenterPosition()
  let position = (hand_pos.getX(), hand_pos.getY())
  
  let speed = 25.0  // 穿透弹速度更快
  let velocity = (direction * speed, 0.0)
  
  self.create_bullet(
    position, 
    velocity, 
    player_index, 
    damage=15,  // 穿透弹伤害更高
    max_distance=60.0,
    target_types=[Player],
    penetration=penetration_count
  ) |> ignore
  
  println("玩家 \{player_index} 发射了穿透子弹 (穿透\{penetration_count}次)")
}

///|
/// 创建散弹（多发子弹）
/// 
/// @param player_index 玩家索引
/// @param direction 主要射击方向
/// @param bullet_count 子弹数量
/// @param spread_angle 散射角度（弧度）
fn Game::shoot_shotgun(
  self : Self,
  player_index : Int,
  direction : Double,
  bullet_count : Int,
  spread_angle : Double
) -> Unit {
  if player_index >= self.particle_list.length() {
    return
  }
  
  let particle = self.particle_list[player_index]
  let hand_pos = particle.right_forearm.getCenterPosition()
  let position = (hand_pos.getX(), hand_pos.getY())
  
  let base_speed = 18.0
  
  // 生成多发子弹
  for i in 0..<bullet_count {
    // 计算散射角度
    let angle_offset = if bullet_count == 1 {
      0.0
    } else {
      spread_angle * (i.to_double() / (bullet_count - 1).to_double() - 0.5)
    }
    
    // 计算速度向量
    let vx = direction * base_speed * @cmath.cos(angle_offset)
    let vy = base_speed * @cmath.sin(angle_offset)
    let velocity = (vx, vy)
    
    self.create_bullet(
      position,
      velocity,
      player_index,
      damage=6,  // 散弹单发伤害较低
      max_distance=30.0,  // 射程较短
      target_types=[Player],
      penetration=0
    ) |> ignore
  }
  
  println("玩家 \{player_index} 发射了散弹 (\{bullet_count}发)")
}

///|
/// 创建针对敌人的子弹
/// 
/// @param player_index 玩家索引
/// @param direction 射击方向
fn Game::shoot_at_enemies(self : Self, player_index : Int, direction : Double) -> Unit {
  if player_index >= self.particle_list.length() {
    return
  }
  
  let particle = self.particle_list[player_index]
  let hand_pos = particle.right_forearm.getCenterPosition()
  let position = (hand_pos.getX(), hand_pos.getY())
  
  let speed = 20.0
  let velocity = (direction * speed, 0.0)
  
  // 创建只打敌人的子弹
  self.create_bullet(
    position,
    velocity,
    player_index,
    damage=15,
    max_distance=50.0,
    target_types=[Enemy],  // 只打敌人
    penetration=0
  ) |> ignore
  
  println("玩家 \{player_index} 发射了反敌子弹")
}

///|
/// 创建全伤害子弹（玩家+敌人都受伤）
/// 
/// @param player_index 玩家索引
/// @param direction 射击方向
fn Game::shoot_explosive_bullet(self : Self, player_index : Int, direction : Double) -> Unit {
  if player_index >= self.particle_list.length() {
    return
  }
  
  let particle = self.particle_list[player_index]
  let hand_pos = particle.right_forearm.getCenterPosition()
  let position = (hand_pos.getX(), hand_pos.getY())
  
  let speed = 15.0  // 爆炸弹速度较慢
  let velocity = (direction * speed, 0.0)
  
  // 创建伤害所有角色的子弹
  self.create_bullet(
    position,
    velocity,
    player_index,
    damage=25,  // 高伤害
    max_distance=40.0,
    target_types=[AllCharacters],  // 伤害所有人
    penetration=0
  ) |> ignore
  
  println("玩家 \{player_index} 发射了爆炸弹 (危险！伤害所有人)")
}