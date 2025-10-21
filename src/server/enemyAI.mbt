// drone 
pub struct Drone {
id : Int
hp : Double
hp_limit : Double
body : @box2d.B2Body
action_type : ActionType
weapon : Gun?           // 无人机可以装备一把枪
target_particle_id : Int // 追踪的玩家ID
field_of_view : Double   // 视野范围
attack_range : Double    // 攻击范围
}

pub impl EnemyTrait for Drone with update(self : Drone, game: Game) -> Unit {
  // 1. 检查并更新目标
  self.update_target(game)
  
  // 2. 根据当前状态执行对应行为
  match self.action_type {
    Patrol => self.patrol_behavior(game)
    Pursuit => self.pursuit_behavior(game)
    Attack => self.attack_behavior(game)
  }
  
  // 3. 限制最大速度
  self.limit_velocity()
}

pub impl EnemyTrait for Drone with destroy(self : Drone, game: Game) -> Unit {
  match self.weapon {
    Some(gun) => gun.destroy(game)
    None => ()
  }
  
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

fn Drone::update_target(self : Drone, game : Game) -> Unit {
  // 检查当前目标是否有效
  if self.target_particle_id == -1 || not(self.is_target_valid(game)) {
    self.find_nearest_target(game)
  }
  
  // 根据目标距离切换状态
  if self.target_particle_id != -1 {
    let distance = self.get_distance_to_target(game)
    
    if distance <= self.attack_range {
      self.action_type = Attack
    } else if distance <= self.field_of_view {
      self.action_type = Pursuit
    } else {
      self.action_type = Patrol
      self.target_particle_id = -1
    }
  } else {
    self.action_type = Patrol
  }
}

// 检查当前目标是否有效
fn Drone::is_target_valid(self : Drone, game : Game) -> Bool {
  // 无效 ID
  if self.target_particle_id < 0 || self.target_particle_id >= game.particle_list.length() {
    return false
  }
  
  /// 从游戏的粒子列表中获取目标粒子，并检查目标是否仍然存活（生命值大于0）。

  let target = game.particle_list[self.target_particle_id]
  target.control.health > 0
}