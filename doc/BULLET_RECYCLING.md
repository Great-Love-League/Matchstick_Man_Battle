# 子弹回收系统 (Bullet Recycling System)

## 概述

子弹回收系统确保子弹在以下情况下被正确回收（消失）：
1. **穿透次数用完**：子弹穿透了最大允许的人物层数后回收
2. **击中环境**：子弹击中环境（平台、墙壁等）后立即回收
3. **超出射程**：子弹飞行距离超过最大射程后回收
4. **离开视野**：子弹飞出游戏区域后回收

## 核心规则

### 1. 穿透规则

**只有人物可以被穿透，环境无法穿透**

| 目标类型 | 是否可穿透 | 说明 |
|---------|-----------|------|
| 玩家角色 | ✅ 可穿透 | 根据武器的 `penetration` 值决定穿透次数 |
| 敌人 | ✅ 可穿透 | 与玩家相同的穿透规则 |
| 平台 | ❌ 不可穿透 | 击中后立即回收子弹 |
| 墙壁 | ❌ 不可穿透 | 击中后立即回收子弹 |
| 静态物体 | ❌ 不可穿透 | 击中后立即回收子弹 |

### 2. 穿透次数消耗

```moonbit
// 初始穿透次数
bullet.penetration = 2  // 例如：狙击枪可穿透2个人物

// 击中第1个人物
bullet.penetration -= 1  // 剩余穿透次数: 1
bullet.hit_targets.push(player1_id)

// 击中第2个人物
bullet.penetration -= 1  // 剩余穿透次数: 0
bullet.hit_targets.push(player2_id)

// 再击中第3个人物
if bullet.penetration <= 0 {
  bullet.is_active = false  // 穿透次数用完，回收子弹
}
```

## 实现细节

### 1. 人物碰撞检测与穿透

**位置**：`src/server/bullet.mbt` - `check_bullet_collision` 函数

```moonbit
// 记录已命中目标
bullet.hit_targets.push(particle.index)

// 检查穿透：只有人物可以被穿透
if bullet.penetration <= 0 {
  // 穿透次数用完，回收子弹
  bullet.is_active = false
  println("子弹 #\{bullet.id} 穿透次数用完，回收子弹")
  break
} else {
  bullet.penetration -= 1
  println("子弹 #\{bullet.id} 穿透! 剩余穿透次数: \{bullet.penetration}")
}
```

**关键点**：
- 每击中一个人物，`penetration` 减1
- 当 `penetration <= 0` 时，即使再击中目标也会立即回收
- 使用 `hit_targets` 数组防止重复命中同一目标

### 2. 环境碰撞检测

**位置**：`src/server/bullet.mbt` - `check_bullet_environment_collision` 函数

```moonbit
fn Game::check_bullet_environment_collision(self : Self, bullet : Bullet) -> Unit {
  // 1. 检查与所有平台的碰撞
  for platform in self.platform_list {
    if self.is_contact(platform.body, bullet.body) {
      bullet.is_active = false
      println("子弹 #\{bullet.id} 击中环境（平台 #\{platform.index}），回收子弹")
      return
    }
  }
  
  // 2. 检查与世界中其他静态物体的碰撞
  let contact_list = self.world.getContactList()
  for contact in contact_list {
    // 识别子弹与静态物体的接触
    // 静态物体特征：mass == 0.0 且不是角色部位
    if other_body.getMass() == 0.0 && !is_character_part {
      bullet.is_active = false
      println("子弹 #\{bullet.id} 击中环境（静态物体），回收子弹")
      return
    }
  }
}
```

**检测流程**：
1. 首先检查与已知平台的碰撞（快速路径）
2. 然后检查 Box2D 接触列表中的所有静态物体
3. 排除角色身体部位（避免误判）
4. 击中任何环境物体后立即回收子弹

### 3. 其他回收条件

**位置**：`src/server/bullet.mbt` - `update_bullet` 函数

```moonbit
// 超出射程
if bullet.traveled_distance >= bullet.max_distance {
  bullet.is_active = false
  return
}

// 离开视野
if x < -half_width || x > half_width || y < 0.0 || y > half_height * 2.0 {
  bullet.is_active = false
  return
}
```

## 武器穿透配置

| 武器类型 | 穿透次数 | 回收条件 |
|---------|---------|---------|
| **手枪** | 0 | 击中第1个人物或环境后回收 |
| **霰弹枪** | 0 | 5发子弹各自击中第1个人物或环境后回收 |
| **狙击枪** | 2 | 击中第3个人物或任意环境后回收 |
| **激光枪** | 5 | 击中第6个人物或任意环境后回收 |

## 测试场景

### 场景1：手枪射击（无穿透）

```
[玩家] → 子弹 → [敌人] ✓ 击中回收
[玩家] → 子弹 → [平台] ✓ 击中回收
[玩家] → 子弹 → [敌人] → [敌人] ✓ 击中第1个后回收
```

### 场景2：狙击枪射击（穿透2次）

```
[玩家] → 子弹 → [敌人1] → [敌人2] → [敌人3] ✓ 击中第3个后回收
[玩家] → 子弹 → [敌人1] → [平台] ✓ 击中平台立即回收（即使还有穿透次数）
[玩家] → 子弹 → [平台] ✓ 直接击中平台立即回收
[玩家] → 子弹 → [敌人1] → [敌人2] ✓ 穿透2次后停留（下次碰撞回收）
```

### 场景3：激光枪射击（穿透5次）

```
[玩家] → 子弹 → [敌1] → [敌2] → [敌3] → [敌4] → [敌5] → [敌6] ✓ 击中第6个后回收
[玩家] → 子弹 → [敌1] → [墙壁] ✓ 击中墙壁立即回收（即使只穿透1次）
```

## 回收时机总结

```moonbit
// 1. 人物碰撞后穿透检查
if hit_character && bullet.penetration <= 0 {
  bullet.is_active = false  // 穿透次数用完
}

// 2. 环境碰撞立即回收
if hit_environment {
  bullet.is_active = false  // 环境无法穿透
}

// 3. 超出射程
if bullet.traveled_distance >= bullet.max_distance {
  bullet.is_active = false
}

// 4. 离开视野
if out_of_bounds {
  bullet.is_active = false
}
```

## 性能优化

### 回收清理机制

**位置**：`src/server/bullet.mbt` - `cleanup_bullets` 函数

```moonbit
fn Game::cleanup_bullets(self : Self) -> Unit {
  let active_bullets : Array[Bullet] = Array::new()
  
  for bullet in self.bullet_list {
    if bullet.is_active {
      active_bullets.push(bullet)
    } else {
      self.world.destroyBody(bullet.body)  // 销毁 Box2D 物理体
    }
  }
  
  self.bullet_list = active_bullets  // 更新为仅包含活跃子弹的列表
}
```

**调用时机**：
- 每帧更新后调用 `cleanup_bullets()`
- 及时销毁非活跃子弹的物理体
- 防止内存泄漏和性能下降

## 调试信息

系统在关键时刻输出日志：

```
创建子弹 #0: 位置(-2.2, 12.0), 伤害10, 目标[Player]
子弹 #0 击中玩家 1, 伤害 10 (剩余血量: 90)
子弹 #0 穿透次数用完，回收子弹

创建子弹 #1: 位置(-2.2, 12.0), 伤害30, 目标[Player]
子弹 #1 击中玩家 1, 伤害 30 (剩余血量: 60)
子弹 #1 穿透! 剩余穿透次数: 1
子弹 #1 击中环境（平台 #2），回收子弹
```

## 游戏内测试

### 测试步骤

1. **启动游戏**
   ```powershell
   moon build --target js
   npx serve .
   ```
   访问 `http://localhost:3000`

2. **测试无穿透武器（手枪）**
   - 按 `1` 装备手枪
   - 按 `Z` 向敌人射击
   - 观察子弹击中后立即消失

3. **测试穿透武器（狙击枪）**
   - 按 `3` 装备狙击枪
   - 让多个敌人站成一排
   - 按 `Z` 射击，观察子弹穿透效果
   - 观察子弹穿透2个目标后消失

4. **测试环境碰撞**
   - 装备任意武器
   - 向平台或墙壁射击
   - 观察子弹击中环境后立即消失

5. **检查控制台日志**
   - 打开浏览器开发者工具（F12）
   - 查看子弹回收的日志输出
   - 验证回收逻辑是否正确触发

### 预期结果

| 测试项 | 预期结果 |
|-------|---------|
| 手枪击中人物 | ✅ 立即消失 |
| 手枪击中平台 | ✅ 立即消失 |
| 狙击枪穿透2个人物 | ✅ 可穿透，第3个人物击中后消失 |
| 狙击枪击中平台 | ✅ 立即消失（即使还有穿透次数） |
| 激光枪穿透5个人物 | ✅ 可穿透，第6个人物击中后消失 |
| 激光枪击中墙壁 | ✅ 立即消失 |
| 子弹超出射程 | ✅ 自动消失 |
| 子弹飞出边界 | ✅ 自动消失 |

## 相关文档

- **WEAPON_DEMO_GUIDE.md**：武器系统详细说明
- **BULLET_PHYSICS_OPTIMIZATION.md**：子弹物理效果优化
- **RECOIL_SYSTEM.md**：后坐力系统
- **MUZZLE_LIMITER.md**：枪口限位系统

## 版本历史

- **v1.0 (2025-10-19)**：初始实现
  - 添加穿透次数用完后的回收逻辑
  - 添加环境碰撞检测与立即回收
  - 优化回收时的调试信息输出

---

**状态**：✅ 已实现并通过编译测试  
**影响范围**：所有武器的子弹行为  
**核心改进**：环境无法穿透，穿透次数用完后自动回收
