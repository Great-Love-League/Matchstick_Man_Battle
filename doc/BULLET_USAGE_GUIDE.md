# 子弹系统使用指南

本文档解释如何在游戏中使用子弹系统，包括如何射击子弹、如何集成到武器系统中。

---

## 📋 目录

1. [核心概念](#核心概念)
2. [目标过滤系统](#目标过滤系统)
3. [快速开始：在游戏循环中射击](#快速开始在游戏循环中射击)
4. [集成到武器系统](#集成到武器系统)
5. [5种预设射击方法](#5种预设射击方法)
6. [高级：自定义子弹](#高级自定义子弹)
7. [完整示例](#完整示例)

---

## 🎯 核心概念

### 子弹结构
每颗子弹包含以下关键属性：
- **id**: 唯一标识符
- **owner_id**: 发射者的粒子ID
- **damage**: 基础伤害值
- **target_types**: 目标过滤列表（决定谁会受伤）
- **penetration**: 穿透次数（可以击中多个目标）
- **hit_targets**: 已命中目标ID列表（防止重复伤害）

### 游戏循环要求
子弹系统需要在 `Game::update` 中调用：

```moonbit
fn Game::update(self : Self) -> Unit {
  // ... 其他更新代码 ...
  
  // 更新所有子弹（每帧调用）
  self.update_all_bullets()
  
  // 定期清理非活跃子弹（建议每60帧）
  if self.frame_count % 60 == 0 {
    self.cleanup_bullets()
  }
  
  self.frame_count += 1
}
```

---

## 🎯 目标过滤系统

### TargetType 枚举

子弹系统支持三种目标类型：

```moonbit
enum TargetType {
  Player         // 只伤害玩家
  Enemy          // 只伤害敌人
  AllCharacters  // 伤害所有角色（友军伤害）
}
```

### 过滤规则

- **target_types = [Player]**: 子弹只对玩家造成伤害，穿过敌人
- **target_types = [Enemy]**: 子弹只对敌人造成伤害，穿过玩家
- **target_types = [AllCharacters]**: 子弹对所有角色造成伤害（爆炸、陷阱等）
- **target_types = [Player, Enemy]**: 等同于 AllCharacters
- **target_types = []**: 子弹不伤害任何人（装饰弹）

### 使用场景

| 目标类型 | 适用场景 | 示例武器 |
|---------|---------|---------|
| `[Player]` | PVP模式、玩家误伤 | 手枪、步枪 |
| `[Enemy]` | PVE模式、打怪 | 弓箭、魔法 |
| `[AllCharacters]` | 爆炸、陷阱 | 手榴弹、地雷 |
| `[]` | 视觉效果 | 烟花、信号弹 |

---

## 🚀 快速开始：在游戏循环中射击

### 方法1：键盘控制射击

在 `Game::update` 中添加键盘检测：

```moonbit
fn Game::update(self : Self) -> Unit {
  // 检测玩家输入
  let player_index = 0  // 玩家1
  
  // 按下S键发射普通子弹
  if @p5js.keyIsDown('S') && self.frame_count % 10 == 0 {  // 10帧冷却
    let direction = if self.particle_list[player_index].control.face_right {
      1.0
    } else {
      -1.0
    }
    self.shoot_bullet(player_index, direction)
  }
  
  // 按下D键发射穿透子弹
  if @p5js.keyIsDown('D') && self.frame_count % 30 == 0 {  // 30帧冷却
    let direction = if self.particle_list[player_index].control.face_right {
      1.0
    } else {
      -1.0
    }
    self.shoot_penetrating_bullet(player_index, direction, penetration=3)
  }
  
  // 更新子弹
  self.update_all_bullets()
  
  // 定期清理
  if self.frame_count % 60 == 0 {
    self.cleanup_bullets()
  }
  
  self.frame_count += 1
}
```

### 方法2：定时自动射击（测试用）

```moonbit
fn Game::update(self : Self) -> Unit {
  // 每60帧自动发射一次
  if self.frame_count % 60 == 0 {
    let player_index = 0
    let direction = 1.0  // 向右
    self.shoot_bullet(player_index, direction)
  }
  
  self.update_all_bullets()
  self.frame_count += 1
}
```

---

## 🔫 集成到武器系统

### 步骤1：在武器结构中添加子弹配置

修改 `weapon.mbt` 中的武器结构：

```moonbit
struct Gun {
  // ... 现有字段 ...
  
  // 子弹配置
  bullet_damage : Double       // 子弹伤害
  bullet_speed : Double        // 子弹速度
  bullet_penetration : Int     // 穿透次数
  bullet_targets : Array[TargetType]  // 目标类型
  
  // 射击控制
  fire_rate : Int              // 射速（帧间隔）
  last_fire_frame : Int        // 上次射击帧
}
```

### 步骤2：实现 attack 方法调用子弹系统

```moonbit
// 在 weapon.mbt 中
pub impl WeaponControl for Gun with attack(self, game) {
  // 检查冷却
  if game.frame_count - self.last_fire_frame < self.fire_rate {
    return  // 还在冷却中
  }
  
  // 获取持有者信息
  let holder = game.particle_list[self.holder_id]
  let direction = if holder.control.face_right { 1.0 } else { -1.0 }
  
  // 根据武器类型选择射击方式
  match self {
    // 普通手枪
    Gun { bullet_penetration: 0, .. } => {
      game.shoot_bullet(self.holder_id, direction)
    }
    
    // 穿透武器
    Gun { bullet_penetration: pen, .. } if pen > 0 => {
      game.shoot_penetrating_bullet(
        self.holder_id, 
        direction, 
        penetration=pen
      )
    }
    
    // 霰弹枪
    Gun { fire_rate: rate, .. } if rate >= 30 => {
      game.shoot_shotgun(self.holder_id, direction)
    }
  }
  
  // 更新冷却
  self.last_fire_frame = game.frame_count
}
```

### 步骤3：在Game::update中触发武器射击

```moonbit
fn Game::update(self : Self) -> Unit {
  // 检测射击输入
  if @p5js.keyIsDown('S') {
    let player = self.particle_list[0]
    match player.control.weapon {
      Some(weapon) => weapon.attack(self)  // 触发武器射击
      None => ()
    }
  }
  
  // 更新子弹（必须！）
  self.update_all_bullets()
  
  self.frame_count += 1
}
```

---

## 🎮 5种预设射击方法

### 1. shoot_bullet - 基础射击

**特性**：
- 伤害：10
- 速度：20
- 目标：仅玩家 `[Player]`
- 穿透：无

**使用场景**：普通手枪、步枪

```moonbit
// 简单射击
self.shoot_bullet(player_index, direction)
```

---

### 2. shoot_penetrating_bullet - 穿透弹

**特性**：
- 伤害：15
- 速度：25
- 目标：仅玩家 `[Player]`
- **穿透：可自定义次数**

**使用场景**：穿甲弹、狙击枪、激光

```moonbit
// 穿透3个目标
self.shoot_penetrating_bullet(player_index, direction, penetration=3)

// 穿透5个目标（激光武器）
self.shoot_penetrating_bullet(player_index, direction, penetration=5)
```

**穿透机制**：
1. 子弹击中第1个目标 → 造成伤害 → penetration = 2
2. 子弹击中第2个目标 → 造成伤害 → penetration = 1
3. 子弹击中第3个目标 → 造成伤害 → penetration = 0 → 子弹消失
4. 已命中的目标不会再次受伤（通过 `hit_targets` 数组记录）

---

### 3. shoot_shotgun - 霰弹枪

**特性**：
- 伤害：6（每颗）
- 速度：18
- 目标：仅玩家 `[Player]`
- **发射5颗子弹，扇形散射**

**使用场景**：霰弹枪、近战武器

```moonbit
// 发射5颗散射子弹
self.shoot_shotgun(player_index, direction)
```

**散射角度**：
- 中心弹：0度
- 其他弹：±15度、±30度扩散

---

### 4. shoot_at_enemies - 打敌人

**特性**：
- 伤害：15
- 速度：20
- 目标：**仅敌人** `[Enemy]`
- 穿透：无

**使用场景**：PVE模式、打怪、自动炮塔

```moonbit
// 只伤害敌人，穿过玩家
self.shoot_at_enemies(player_index, direction)
```

**关键特性**：
- 玩家可以安全站在射线上
- 只有敌人会受伤
- 适合多人协作PVE

---

### 5. shoot_explosive_bullet - 爆炸弹

**特性**：
- 伤害：25
- 速度：15
- 目标：**所有角色** `[AllCharacters]`
- 穿透：无

**使用场景**：爆炸武器、友军伤害、陷阱

```moonbit
// 友军伤害：所有人都会受伤！
self.shoot_explosive_bullet(player_index, direction)
```

**⚠️ 警告**：此方法会造成友军伤害！发射者也可能受伤。

---

## 🔬 高级：自定义子弹

如果预设方法不满足需求，可以使用 `create_bullet` 完全自定义：

```moonbit
// 完整签名
fn Game::create_bullet(
  self : Self,
  owner_id : Int,                  // 发射者ID
  start_x : Double,                // 起始X
  start_y : Double,                // 起始Y
  velocity_x : Double,             // X速度
  velocity_y : Double,             // Y速度
  damage : Double,                 // 伤害
  target_types : Array[TargetType], // 目标过滤
  penetration? : Int               // 穿透（可选，默认0）
) -> Unit
```

### 示例1：垂直发射的火箭

```moonbit
let player = self.particle_list[player_index]
let pos = player.body.GetPosition()

self.create_bullet(
  player_index,
  pos.x, pos.y,
  velocity_x=0.0,    // 不横向移动
  velocity_y=-30.0,  // 向上发射
  damage=50.0,
  target_types=[AllCharacters],  // 爆炸伤害
  penetration=0
)
```

### 示例2：追踪导弹（需要额外逻辑）

```moonbit
// 创建慢速子弹
self.create_bullet(
  player_index,
  pos.x, pos.y,
  velocity_x=10.0,
  velocity_y=0.0,
  damage=30.0,
  target_types=[Enemy],
  penetration=0
)

// 在 update_all_bullets 中添加追踪逻辑：
// bullet.body.SetLinearVelocity(calculate_homing_velocity(bullet, target))
```

### 示例3：毒箭（持续伤害）

```moonbit
// 创建低伤害穿透弹
self.create_bullet(
  player_index,
  pos.x, pos.y,
  velocity_x=direction * 15.0,
  velocity_y=0.0,
  damage=5.0,  // 低初始伤害
  target_types=[Enemy],
  penetration=10  // 高穿透，持续触发
)

// 在 check_bullet_collision 中每次命中都会造成5点伤害
// 效果：子弹停在目标体内，持续造成伤害直到穿透次数耗尽
```

---

## 📝 完整示例

### 示例1：简单射击游戏

```moonbit
// 在 main.mbt 或 game.mbt 中
fn Game::update(self : Self) -> Unit {
  // 玩家1控制
  if @p5js.keyIsDown('S') && self.frame_count % 15 == 0 {
    let dir = if self.particle_list[0].control.face_right { 1.0 } else { -1.0 }
    self.shoot_bullet(0, dir)
  }
  
  // 玩家2控制（如果存在）
  if self.particle_list.length() > 1 {
    if @p5js.keyIsDown('L') && self.frame_count % 15 == 0 {
      let dir = if self.particle_list[1].control.face_right { 1.0 } else { -1.0 }
      self.shoot_bullet(1, dir)
    }
  }
  
  // 必须调用：更新子弹物理和碰撞
  self.update_all_bullets()
  
  // 定期清理
  if self.frame_count % 60 == 0 {
    self.cleanup_bullets()
  }
  
  self.frame_count += 1
}
```

---

### 示例2：武器系统集成

```moonbit
// weapon.mbt
struct Gun {
  holder_id : Int
  fire_rate : Int
  mut last_fire : Int
  weapon_type : WeaponType
}

enum WeaponType {
  Pistol      // 手枪
  Shotgun     // 霰弹枪
  Sniper      // 狙击枪
  LaserRifle  // 激光枪
}

pub impl WeaponControl for Gun with attack(self, game) {
  // 冷却检测
  if game.frame_count - self.last_fire < self.fire_rate {
    return
  }
  
  let holder = game.particle_list[self.holder_id]
  let dir = if holder.control.face_right { 1.0 } else { -1.0 }
  
  // 根据武器类型发射不同子弹
  match self.weapon_type {
    Pistol => game.shoot_bullet(self.holder_id, dir)
    Shotgun => game.shoot_shotgun(self.holder_id, dir)
    Sniper => game.shoot_penetrating_bullet(self.holder_id, dir, penetration=2)
    LaserRifle => game.shoot_penetrating_bullet(self.holder_id, dir, penetration=10)
  }
  
  self.last_fire = game.frame_count
}

// game.mbt 中调用
fn Game::update(self : Self) -> Unit {
  // 检测射击键
  if @p5js.keyIsDown('S') {
    match self.particle_list[0].control.weapon {
      Some(weapon) => weapon.attack(self)
      None => ()
    }
  }
  
  self.update_all_bullets()
  self.frame_count += 1
}
```

---

### 示例3：敌人自动射击（AI）

```moonbit
// enemy.mbt
pub impl EnemyTrait for BoxEnemy with update(self : BoxEnemy, game : Game) {
  // 检测玩家距离
  let enemy_pos = self.body.GetPosition()
  
  for i = 0; i < game.particle_list.length(); i = i + 1 {
    let player = game.particle_list[i]
    let player_pos = player.body.GetPosition()
    let distance = @cmath.sqrt(
      (player_pos.x - enemy_pos.x) * (player_pos.x - enemy_pos.x) +
      (player_pos.y - enemy_pos.y) * (player_pos.y - enemy_pos.y)
    )
    
    // 如果玩家在射程内（10米）且冷却结束
    if distance < 10.0 && game.frame_count % 120 == 0 {
      // 计算朝向玩家的方向
      let dir = if player_pos.x > enemy_pos.x { 1.0 } else { -1.0 }
      
      // 敌人射击：目标仅玩家
      game.shoot_at_enemies(self.enemy_id, dir)
      
      println("敌人 #\{self.enemy_id} 向玩家 #\{i} 射击!")
    }
  }
}
```

---

## ✅ 集成检查清单

在将子弹系统集成到游戏前，请确认：

- [ ] `Game` 结构中已添加 `mut bullet_list : Array[Bullet]`
- [ ] `Game` 结构中已添加 `mut frame_count : Int`
- [ ] `create_game()` 初始化了 `bullet_list: []` 和 `frame_count: 0`
- [ ] `Game::update()` 调用了 `self.update_all_bullets()`
- [ ] `Game::update()` 定期调用 `self.cleanup_bullets()`（建议每60帧）
- [ ] 武器 `attack()` 方法调用了对应的射击方法
- [ ] 测试过目标过滤（玩家不应受到 `shoot_at_enemies` 的伤害）
- [ ] 测试过穿透机制（穿透弹应能击中多个目标）
- [ ] 测试过友军伤害（`shoot_explosive_bullet` 应伤害所有人）

---

## 🐛 常见问题

### 问题1：子弹不移动
**原因**：忘记调用 `update_all_bullets()`  
**解决**：在 `Game::update()` 中添加 `self.update_all_bullets()`

### 问题2：子弹无限飞行
**原因**：忘记调用 `cleanup_bullets()`  
**解决**：定期调用清理：`if self.frame_count % 60 == 0 { self.cleanup_bullets() }`

### 问题3：友军不受伤
**原因**：使用了 `[Player]` 或 `[Enemy]` 目标类型  
**解决**：使用 `shoot_explosive_bullet()` 或设置 `target_types=[AllCharacters]`

### 问题4：穿透弹只击中一次
**原因**：`penetration` 参数设为 0 或未设置  
**解决**：使用 `shoot_penetrating_bullet(player_id, dir, penetration=3)`

### 问题5：编译错误 "bullet_list not found"
**原因**：`Game` 结构未添加 `bullet_list` 字段  
**解决**：在 `game.mbt` 中添加：
```moonbit
struct Game {
  // ... 现有字段 ...
  mut bullet_list : Array[Bullet]
  mut frame_count : Int
}
```

---

## 📚 相关文档

- `BULLET_ITEM_SUMMARY.md` - 子弹和物品系统总览
- `ITEM_SYSTEM_README.md` - 物品系统详细文档
- `bullet.mbt` - 子弹系统源代码
- `weapon.mbt` - 武器系统源代码

---

## 🎓 总结

### 快速回顾

1. **初始化**：在 `Game` 中添加 `bullet_list` 和 `frame_count`
2. **更新**：在 `Game::update()` 调用 `update_all_bullets()`
3. **清理**：定期调用 `cleanup_bullets()`
4. **射击**：根据需求选择5种预设方法之一
5. **目标过滤**：使用 `TargetType` 精确控制伤害对象

### 最简实现

```moonbit
// 在 Game::update 中
fn Game::update(self : Self) -> Unit {
  // 按S键射击
  if @p5js.keyIsDown('S') && self.frame_count % 10 == 0 {
    let dir = if self.particle_list[0].control.face_right { 1.0 } else { -1.0 }
    self.shoot_bullet(0, dir)
  }
  
  self.update_all_bullets()  // 必须！
  
  if self.frame_count % 60 == 0 {
    self.cleanup_bullets()  // 必须！
  }
  
  self.frame_count += 1
}
```

---

现在你已经掌握了子弹系统的完整用法！开始射击吧！🎯🔫
