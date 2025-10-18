# 武器测试文档 (Weapon Test Documentation)

## 概述 (Overview)

这是一个简单的武器和子弹发射系统的测试实现。使用简单的多边形（矩形）代替复杂的武器模型，实现了基本的武器发射功能。

## 功能特性 (Features)

### 1. 武器系统 (Weapon System)
- **4种武器类型**：
  - `Melee` - 近战武器（刀剑）
  - `Gun` - 枪械（手枪）
  - `Grenade` - 榴弹发射器
  - `Laser` - 激光枪

- **武器属性**：
  - 弹药数量（Melee和Laser无限弹药）
  - 子弹初速
  - 后坐力
  - 攻击间隔
  - 攻击范围

### 2. 子弹系统 (Bullet System)
- **子弹类型**：
  - `Normal` - 普通子弹（黄色）
  - `Explosive` - 爆炸物（红色）
  - `Piercing` - 穿透弹
  - `Special` - 特殊效果

- **子弹特性**：
  - 使用Box2D物理引擎
  - 自动生命周期管理
  - 碰撞检测
  - 爆炸效果（榴弹）

### 3. 当前测试实现 (Current Test Implementation)

在 `main.mbt` 中已集成了一个简单的测试武器：

```moonbit
// 创建测试武器（Gun类型）
let weapon = create_weapon(world.val, (0.0, 20.0), WeaponType::Gun)
```

## 操作说明 (Controls)

### 键盘控制 (Keyboard Controls)

#### 角色移动 (Character Movement)
- **W 键** - 角色跳跃
- **A 键** - 角色向左移动
- **D 键** - 角色向右移动

#### 武器操作 (Weapon Controls)
- **E 键** - 拾取武器（靠近武器时按E键）
- **Q 键** - 丢弃武器（手持武器时按Q键）
- **S 键** - 发射武器（向鼠标方向，仅持有武器时）

### 鼠标控制 (Mouse Controls)

- **鼠标位置** - 武器瞄准方向（持有武器时）

### 拾取系统说明 (Pickup System)

1. **如何拾取武器**：
   - 走到武器附近（2个单位距离内）
   - 武器会显示为矩形多边形
   - 按 **E 键** 拾取
   - 控制台会显示 "Picked up weapon! Owner: X"

2. **如何使用武器**：
   - 拾取后武器会自动跟随角色的右手
   - 移动鼠标改变瞄准方向
   - 按 **S 键** 发射

3. **如何丢弃武器**：
   - 按 **Q 键** 丢弃当前武器
   - 武器会掉落在地上
   - 控制台会显示 "Dropped weapon!"

4. **武器状态判断**：
   - `owner_id = -1` : 武器在地上，可以拾取
   - `owner_id = 角色ID` : 武器被该角色持有

## 技术实现 (Technical Implementation)

### 武器创建 (Weapon Creation)
```moonbit
pub fn create_weapon(
  world : @box2d.B2World,
  position : (Double, Double),
  weapon_type : WeaponType,
  owner_id? : Int = -1,
) -> Weapon
```

### 子弹创建 (Bullet Creation)
```moonbit
pub fn create_bullet(
  world : @box2d.B2World,
  owner_id : Int,
  position : (Double, Double),
  direction : (Double, Double),
  speed : Double,
  damage : Int,
  bullet_type : BulletType,
  lifetime : Int,
) -> Bullet
```

### 子弹更新 (Bullet Update)
```moonbit
pub fn update_bullets(
  world : @box2d.B2World,
  characters : Array[Character],
) -> Unit
```

## 文件结构 (File Structure)

- `src/server/weapon_system.mbt` - 武器系统实现
- `src/server/bullet.mbt` - 子弹系统实现
- `src/server/game_types.mbt` - 类型定义
- `src/server/main.mbt` - 测试集成
- `src/server/weapon_test.mbt` - 测试辅助函数（部分未完成）

## 运行测试 (Running the Test)

### 编译项目 (Build Project)
```bash
moon build --target js --warn-list -A
```

### 启动服务器 (Start Server)
```bash
npx serve .
```

### 打开浏览器 (Open Browser)
访问 `http://localhost:3000`

## 当前状态 (Current Status)

✅ **已完成 (Completed)**:
- 武器系统核心实现
- 子弹系统核心实现
- **武器拾取功能（E键）**
- **武器丢弃功能（Q键）**
- **武器跟随角色手部**
- 基本的发射功能
- 子弹物理模拟
- 生命周期管理
- 距离检测拾取系统

⏳ **进行中 (In Progress)**:
- 武器切换功能（多武器携带）
- 完整的UI信息显示
- 子弹渲染优化

🔄 **待优化 (To Optimize)**:
- 添加更多武器类型
- 改进子弹碰撞检测
- 添加音效和粒子效果
- 添加伤害数字显示
- 武器拾取提示UI

## 调试信息 (Debug Information)

控制台会输出：
- `Picked up weapon! Owner: X` - 成功拾取武器，X为角色ID
- `Dropped weapon!` - 成功丢弃武器
- `Fired! Ammo: X` - 武器发射成功，剩余弹药数X
- 子弹碰撞和销毁信息

## 注意事项 (Notes)

1. 当前武器显示为简单的矩形多边形
2. 子弹显示为小圆圈（不同颜色表示不同类型）
3. 使用Box2D物理引擎进行所有碰撞检测
4. 需要使用 `--warn-list -A` 编译以忽略未使用变量的警告
5. **拾取距离为2个物理单位（约40像素）**
6. **武器会自动跟随角色的右前臂**
7. **只能拾取 owner_id=-1 的武器（地上的武器）**

## 下一步计划 (Next Steps)

1. 完善 `weapon_test.mbt` 中的辅助函数
2. 添加武器切换UI
3. 改进武器和子弹的视觉效果
4. 添加角色与子弹的碰撞检测
5. 实现完整的伤害系统

## 相关文档 (Related Documentation)

- [ARCHITECTURE.md](./ARCHITECTURE.md) - 完整系统架构
- [Agents.md](./Agents.md) - 项目开发指南
- [README.mbt.md](./README.mbt.md) - 项目说明

---

**创建日期**: 2025-10-18
**版本**: 1.0.0
**作者**: GitHub Copilot
