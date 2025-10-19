# 物品系统使用文档

## 概述

物品系统为游戏提供了完整的道具拾取、效果应用和自动回收功能。

## 物品类型

### 1. **HealthPack** - 血包 🩹
- **效果**: 恢复生命值
- **默认值**: 30点生命值
- **特殊机制**: 如果角色昏迷且恢复到50血以上，会自动苏醒
- **生命周期**: 600帧（约10秒）

### 2. **AmmoPack** - 弹药包 🔫
- **效果**: 增加弹药（预留接口）
- **默认值**: 10发子弹
- **生命周期**: 600帧

### 3. **WeaponUpgrade** - 武器升级 ⚔️
- **效果**: 提升武器性能（预留接口）
- **生命周期**: 300帧（约5秒）

### 4. **SpeedBoost** - 速度提升 ⚡
- **效果**: 临时提升移动速度（预留接口）
- **默认持续**: 300帧
- **生命周期**: 600帧

## 核心API

### Item 结构体
```moonbit
pub struct Item {
  id : Int                        // 唯一ID
  body : @box2d.B2Body           // 物理刚体
  item_type : ItemType            // 物品类型
  value : Int                     // 效果值
  mut is_active : Bool           // 是否激活
  position : (Double, Double)     // 位置
  mut lifetime : Int              // 剩余生命（帧数）
}
```

### 创建物品
```moonbit
fn Game::create_item(
  self : Self,
  position : (Double, Double),
  item_type : ItemType,
  value? : Int = 20,
  lifetime? : Int = 600
) -> Item
```

### 快捷生成方法

#### 生成血包
```moonbit
self.spawn_health_pack((x, y), value=30)
```

#### 生成弹药包
```moonbit
self.spawn_ammo_pack((x, y), value=10)
```

#### 生成武器升级
```moonbit
self.spawn_weapon_upgrade((x, y))
```

#### 生成速度提升
```moonbit
self.spawn_speed_boost((x, y), duration=300)
```

#### 生成随机物品
```moonbit
let rng = @random.Rand::new()
self.spawn_random_item(rng)
```

## 系统集成

### 1. 在 Game 结构体中添加字段
```moonbit
struct Game {
  // ... 其他字段
  mut item_list : Array[Item]
}
```

### 2. 初始化
```moonbit
fn create_game() -> Game {
  Game::{
    // ...
    item_list : Array::new(),
  }
}
```

### 3. 在游戏循环中更新
```moonbit
fn Game::update(self : Self, p : @p5js.P5Instance) -> Unit {
  // ... 其他更新逻辑
  
  // 更新所有物品（检测拾取、减少生命周期）
  self.update_all_items()
  
  // 定期清理失效物品（建议每60帧）
  if self.frame_count % 60 == 0 {
    self.cleanup_items()
  }
  
  // 可选：定期生成随机物品
  if self.frame_count % 300 == 0 {  // 每5秒
    let rng = @random.Rand::new()
    self.spawn_random_item(rng)
  }
}
```

## 拾取机制

### 触发条件
玩家的以下身体部位接触物品时会拾取：
- 躯干 (torso)
- 头部 (head)  
- 左大腿 (left_thigh)
- 右大腿 (right_thigh)

### 拾取检测
```moonbit
fn Game::check_item_pickup(self : Self, item : Item) -> Bool
```
- 自动遍历所有玩家
- 跳过昏迷角色
- 使用 Box2D 碰撞检测
- 返回 true 表示物品被拾取

### 效果应用
```moonbit
fn Game::apply_item_effect(self : Self, particle : Particle, item : Item) -> Unit
```

## 生命周期管理

### 自动过期
- 每帧自动减少 `lifetime`
- `lifetime` 为 0 时自动失效
- `lifetime` 为 -1 表示永久存在

### 自动清理
```moonbit
fn Game::cleanup_items(self : Self) -> Unit
```
- 移除所有 `is_active = false` 的物品
- 销毁对应的 Box2D 刚体
- 释放内存
- 输出清理日志

## 调试功能

### 获取活跃物品数量
```moonbit
let count = self.get_active_item_count()
println("当前活跃物品: \{count}")
```

### 日志输出
系统会自动输出以下日志：
- ✅ 物品创建: `"Created HealthPack at (x, y)"`
- 🎁 物品拾取: `"玩家 0 拾取了血包! 恢复 30 点生命值 (当前: 80/100)"`
- ⏰ 物品过期: `"物品 HealthPack 已过期消失"`
- 🧹 批量清理: `"清理了 3 个物品"`

## 扩展示例

### 自定义物品效果
```moonbit
// 在 apply_item_effect 中添加新效果
match item.item_type {
  AmmoPack => {
    particle.control.ammo += item.value
    println("玩家 \{particle.index} 获得 \{item.value} 发子弹")
  }
  SpeedBoost => {
    particle.control.speed_multiplier = 1.5
    particle.control.speed_boost_duration = item.value
    println("玩家 \{particle.index} 获得速度提升!")
  }
}
```

### 定时生成物品
```moonbit
// 每 5 秒在随机位置生成血包
if self.frame_count % 300 == 0 {
  let x = (self.frame_count % 40) as Double - 20.0
  let y = 10.0
  self.spawn_health_pack((x, y))
}
```

## 物理参数

- **物品大小**: 0.3 x 0.3 (物理单位)
- **密度**: 0.0 (静态物品)
- **碰撞组**: -3 (独立碰撞组)
- **睡眠**: 禁用 (确保持续检测)

## 性能优化

1. **批量更新**: 一次遍历处理所有物品
2. **惰性清理**: 仅在需要时清理（建议每60帧）
3. **碰撞优化**: 使用独立碰撞组避免不必要的碰撞检测
4. **自动过期**: 避免物品无限累积

## 已知限制

1. ❌ AmmoPack、WeaponUpgrade、SpeedBoost 效果需要配合其他系统实现
2. ⚠️ 物品显示依赖 Box2D 的基础绘制，可能需要自定义渲染
3. 💡 随机生成需要传入 `@random.Rand` 实例

## 测试建议

```moonbit
// 在 box2d_init 中测试
fn box2d_init(game : Game) -> Unit {
  game.create_particle((0.0, 10.0)) |> ignore
  
  // 测试：在玩家周围生成各类物品
  game.spawn_health_pack((2.0, 10.0))
  game.spawn_ammo_pack((4.0, 10.0))
  game.spawn_weapon_upgrade((6.0, 10.0))
  game.spawn_speed_boost((8.0, 10.0))
}
```

---

**状态**: ✅ 完全实现并通过编译  
**版本**: 1.0  
**最后更新**: 2025-10-19
