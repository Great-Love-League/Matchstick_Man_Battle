///| 物品系统
/// 管理所有可拾取物品的创建、更新和拾取逻辑

///|
/// 物品类型枚举
pub enum ItemType {
  HealthPack // 血包
  AmmoPack // 弹药包
  WeaponUpgrade // 武器升级
  SpeedBoost // 速度提升
}

///|
/// 物品结构体
pub struct Item {
  id : Int
  body : @box2d.B2Body
  item_type : ItemType
  value : Int
  mut is_active : Bool
  position : (Double, Double)
}

///|
/// 物品列表和计数器
let item_list : Ref[Array[Item]] = Ref::new(Array::new())
let item_index : Ref[Int] = Ref::new(0)

///|
/// 创建物品
pub fn create_item(
  world : @box2d.B2World,
  position : (Double, Double),
  item_type : ItemType,
  value? : Int = 20
) -> Item {
  item_index.val += 1

  // 创建物品物理体（小方块）
  let box_def = @box2d.b2BoxDef()
  box_def.setExtents(@box2d.b2Vec2(0.3, 0.3))
  box_def.setDensity(0.0) // 静态物体

  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(box_def.getBase())

  let body = world.createBody(body_def)

  let item = Item::{
    id: item_index.val,
    body,
    item_type,
    value,
    is_active: true,
    position,
  }

  item_list.val.push(item)
  item
}

///|
/// 检测物品拾取
fn check_item_pickup(item : Item) -> Unit {
  if !item.is_active {
    return
  }

  for particle in particle_list.val {
    // 如果人物已昏迷，无法拾取
    if particle.control.is_faint {
      continue
    }

    // 检查碰撞（检查人物的身体中心部分）
    if is_contact(particle.torso, item.body) || is_contact(particle.head, item.body) {
      // 执行拾取逻辑
      apply_item_effect(particle, item)

      // 标记物品为非活跃
      item.is_active = false
      break
    }
  }
}

///|
/// 应用物品效果
fn apply_item_effect(particle : Particle, item : Item) -> Unit {
  match item.item_type {
    HealthPack => {
      // 增加血量，但不超过最大值100
      particle.control.health += item.value
      if particle.control.health > 100 {
        particle.control.health = 100
      }
      println("玩家 \{particle.index} 拾取了血包，当前血量: \{particle.control.health}")
    }
    AmmoPack => {
      // TODO: 增加弹药（需要在ParticleControl中添加弹药字段）
      println("玩家 \{particle.index} 拾取了弹药包")
    }
    WeaponUpgrade => {
      // TODO: 升级武器（需要武器系统支持）
      println("玩家 \{particle.index} 拾取了武器升级")
    }
    SpeedBoost => {
      // TODO: 增加速度（需要在ParticleControl中添加速度加成字段）
      println("玩家 \{particle.index} 拾取了速度提升")
    }
  }
}

///|
/// 更新所有物品
pub fn update_all_items() -> Unit {
  for item in item_list.val {
    if item.is_active {
      check_item_pickup(item)
    }
  }
}

///|
/// 清理所有非活跃的物品
pub fn cleanup_items(world : @box2d.B2World) -> Unit {
  let active_items : Array[Item] = Array::new()

  for item in item_list.val {
    if item.is_active {
      active_items.push(item)
    } else {
      world.destroyBody(item.body)
    }
  }

  item_list.val = active_items
}

///|
/// 获取活跃物品数量
pub fn get_active_item_count() -> Int {
  let mut count = 0
  for item in item_list.val {
    if item.is_active {
      count += 1
    }
  }
  count
}

///|
/// 在随机位置生成物品
pub fn spawn_random_item(
  world : @box2d.B2World,
  x_range : (Double, Double),
  y_position : Double
) -> Unit {
  // TODO: 实现随机位置生成（需要随机数生成器）
  // 暂时在固定位置生成
  let position = ((x_range.0 + x_range.1) / 2.0, y_position)
  create_item(world, position, HealthPack, value=20) |> ignore
}
