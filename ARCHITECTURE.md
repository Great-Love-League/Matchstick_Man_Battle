# Matchstick Man Battle - Game Architecture Documentation

## 项目概述 (Project Overview)

这是一个基于 MoonBit 语言开发的火柴人对战游戏，使用 Box2D 物理引擎和 P5.js 进行渲染。


## 游戏主循环 (Game Loop)

游戏采用经典的三阶段循环:
1. **输入处理 (Process Input)** - 接收玩家输入
2. **状态更新 (Update Game State)** - 更新所有游戏对象
3. **渲染 (Render)** - 绘制游戏画面

## 文件结构 (File Structure)

### 核心系统文件 (Core System Files)

```
src/server/
├── game_types.mbt       # 游戏类型定义
├── game_loop.mbt        # 主游戏循环
├── character.mbt        # 角色系统
├── bullet.mbt           # 子弹系统
├── weapon_system.mbt    # 武器系统
├── item.mbt             # 物品拾取系统
├── adapter.mbt          # 兼容性适配器
├── method.mbt           # 物理辅助方法
├── variable.mbt         # 全局变量
├── main.mbt             # 主入口和渲染
├── particle.mbt         # 火柴人定义(兼容旧代码)
├── action_part.mbt      # 动作控制
├── create_part.mbt      # 创建角色
├── platform.mbt         # 平台定义
└── weapon.mbt           # 旧武器系统(已废弃)
```

## 游戏元素 (Game Elements)

### 1. 角色系统 (Character System)

**文件**: `character.mbt`, `game_types.mbt`

**角色属性** (Character Properties):
- **生命值** (Health): 当前HP和最大HP
- **护盾** (Shield): 
  - 角度范围: 5°-40°
  - 恢复速度: (3 + velocity × 0.1)°/frame
  - 指向鼠标位置
- **武器槽** (Weapon Slots): 最多2个武器
- **物理属性** (Physics):
  - 速度倍数 (Speed Multiplier)
  - 加速度修正 (Acceleration Modifier)
  - 跳跃高度倍数 (Jump Height Multiplier)

**角色操作** (Character Actions):
- 移动 (Walk/Stand)
- 跳跃 (Jump)
- 使用武器 (Attack)
- 防御 (Shield)
- 拾取/丢弃/投掷武器 (Pickup/Drop/Throw Weapon)

### 2. 武器系统 (Weapon System)

**文件**: `weapon_system.mbt`

**武器类型** (Weapon Types):
1. **近战** (Melee): 刀剑，无限使用，范围1.5单位
2. **枪械** (Gun): 普通子弹，30发弹药
3. **榴弹** (Grenade): 爆炸伤害，5发弹药
4. **激光** (Laser): 持续伤害，无限使用，50单位射程

**武器属性** (Weapon Properties):
- 子弹数量 (Ammo Count)
- 子弹初速 (Initial Bullet Speed)
- 后坐力 (Recoil)
- 最小攻击间隔 (Min Attack Interval)
- 是否自动连发 (Is Automatic)
- 重量 (Weight)

### 3. 子弹系统 (Bullet System)

**文件**: `bullet.mbt`

**子弹类型** (Bullet Types):
- 普通子弹 (Normal)
- 爆炸物 (Explosive): 2单位爆炸半径
- 穿透 (Piercing)
- 特殊效果 (Special): 可影响目标速度/加速度/跳跃

**伤害系统** (Damage System):
- 头部命中: 2倍伤害
- 躯干命中: 1倍伤害
- 四肢命中: 0.5倍伤害
- 爆炸伤害随距离衰减
- 护盾可阻挡伤害

### 4. 物品系统 (Item System)

**文件**: `item.mbt`

**物品类型** (Item Types):
1. **武器拾取** (Weapon Pickup): 拾取新武器
2. **血包** (Health Pack): 恢复生命值
3. **弹药箱** (Ammo Box): 补充弹药

### 5. 平台/环境 (Platform/Environment)

**文件**: `platform.mbt`

**环境属性** (Environment Properties):
- 耐久度 (Health): -1表示不可破坏
- 摩擦力 (Friction)
- 速度/加速度 (Velocity/Acceleration): 支持移动平台

## API 使用示例 (API Usage Examples)

### 初始化游戏 (Initialize Game)

```moonbit
fn main {
  // 创建物理世界
  let world = create_world(gravity=(0.0, -9.8))
  
  // 初始化游戏状态
  let game_state = init_game_state(world)
  
  // 创建角色
  let character1 = create_character(world.val, (0.0, 10.0), skin_id=0)
  let character2 = create_character(world.val, (5.0, 10.0), skin_id=1)
  
  // 创建平台
  create_platform(world.val, (0.0, 0.0), (10.0, 1.0)) |> ignore
  
  // 启动游戏循环
  let p5_instance = getP5Instance(fn(p) {
    game_loop(p, game_state)
  }, width=1000.0, height=1000.0)
}
```

### 创建武器 (Create Weapon)

```moonbit
// 创建枪械
let gun = create_weapon(world, (5.0, 5.0), WeaponType::Gun)

// 角色拾取武器
character_pickup_weapon(character, gun.id)

// 使用武器攻击
weapon_attack(gun, character, world, frame_count, all_characters)
```

### 生成物品 (Spawn Items)

```moonbit
// 生成血包
spawn_health_pack(world, (3.0, 5.0), heal_amount=50)

// 生成弹药箱
spawn_ammo_box(world, (4.0, 5.0), ammo_amount=30)

// 生成武器掉落
spawn_weapon_drop(world, (5.0, 5.0), WeaponType::Gun)
```

## 输入控制 (Input Controls)

### 玩家1 (Player 1)
- **WASD**: 移动和跳跃
- **鼠标左键**: 攻击
- **鼠标右键**: 护盾
- **Q**: 丢弃武器
- **E**: 投掷武器
- **R**: 切换武器

### 玩家2 (Player 2)
- **方向键**: 移动和跳跃
- 其他控制同玩家1

## 物理系统 (Physics System)

**坐标系** (Coordinate System):
- Canvas原点: 左上角
- Box2D原点: 画布中心底部
- PPM (Pixels Per Meter): 20.0

**单位转换函数** (Conversion Functions):
- `world_to_screen()`: 物理坐标 → 屏幕坐标
- `screen_to_world()`: 屏幕坐标 → 物理坐标

## 碰撞检测 (Collision Detection)

系统使用 Box2D 的接触检测:
- `is_contact(body1, body2)`: 检查两个物体是否接触
- 子弹与角色的碰撞检测
- 角色与物品的拾取检测
- 武器攻击范围检测

## 兼容性说明 (Compatibility Notes)

`adapter.mbt` 提供了新旧系统的兼容层:
- `character_walk()`: Character版本的行走
- `character_stand()`: Character版本的站立
- `character_jump()`: Character版本的跳跃

这些函数将新的`Character`结构转换为旧的`Particle`结构以使用现有的动作控制代码。

## 开发工具 (Development Tools)

```bash
# 格式化代码
moon fmt

# 检查代码
moon check

# 运行测试
moon test

# 更新测试快照
moon test --update

# 代码覆盖率分析
moon coverage analyze > uncovered.log
```

## 注意事项 (Important Notes)

1. **Box2D FFI限制**: 当前Box2D FFI不支持wasm-gc后端，需要使用js后端
2. **性能优化**: 子弹和物品列表会定期清理不活跃对象
3. **坐标转换**: 所有鼠标输入需要从屏幕坐标转换为物理坐标
4. **帧率**: 游戏运行在60 FPS (delta_time = 1/60)

## 扩展性 (Extensibility)

系统设计支持以下扩展:
- 添加新的武器类型 (修改`WeaponType` enum)
- 添加新的子弹效果 (扩展`BulletType` enum)
- 添加新的物品类型 (扩展`ItemType` enum)
- 自定义角色皮肤 (通过`skin_id`)
- 新的游戏模式 (修改`GameState`)

## 已知问题 (Known Issues)

1. 存在重复的结构定义 (`ParticleControl` in `entity.mbt` and `particle.mbt`)
2. Box2D Body无法直接设置位置，只能通过力和冲量移动
3. 某些旧代码文件需要清理 (`weapon.mbt`, `entity.mbt`, `action_arti.mbt`, `create_arti.mbt`)

## 待实现功能 (TODO)

- [ ] 环境破坏系统
- [ ] 特殊道具系统
- [ ] 多人网络对战
- [ ] AI对手
- [ ] 关卡系统
- [ ] 音效和粒子效果
- [ ] 护盾可视化
- [ ] 伤害数字显示
- [ ] 更多武器类型

---

## 联系方式 (Contact)

Repository: Great-Love-League/Matchstick_Man_Battle  
Branch: bug
