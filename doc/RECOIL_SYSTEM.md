# 武器后坐力系统 🔫

## ✅ 已实现后坐力

现在所有武器射击时都会产生符合物理规律的后坐力效果！

---

## 🎯 核心原理

### 牛顿第三定律
```
作用力 = 反作用力
子弹向前 → 枪械向后
```

### 实现方式
使用 Box2D 的 `applyImpulse` 对角色身体施加**反向冲量**：

```moonbit
// 射击方向: direction (1.0 右, -1.0 左)
// 后坐力方向: -direction (相反方向)
let recoil_impulse = @box2d.b2Vec2(-direction * recoil_x, recoil_y)
particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

---

## 🔫 各武器后坐力数据

### 1. 手枪 (Pistol)

**参数**:
- **水平后坐力**: -direction × 1.5
- **垂直后坐力**: +0.3
- **效果**: 轻微后退，微微上扬

**物理计算**:
```
子弹速度: 60 m/s
子弹质量: ~0.01 kg
动量: 0.6 kg·m/s
角色质量: 较大
后坐力: 适度
```

**代码位置**: `bullet.mbt` - `shoot_bullet` 函数
```moonbit
let recoil_impulse = @box2d.b2Vec2(-direction * 1.5, 0.3)
particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

---

### 2. 狙击枪 (Sniper)

**参数**:
- **水平后坐力**: -direction × 3.0
- **垂直后坐力**: +0.5
- **效果**: 明显后退，上扬较大

**物理计算**:
```
子弹速度: 80 m/s (比手枪快33%)
动量: 更大
后坐力: 1.5倍 ~ 2倍手枪
```

**代码位置**: `bullet.mbt` - `shoot_penetrating_bullet` 函数
```moonbit
let recoil_impulse = @box2d.b2Vec2(-direction * 3.0, 0.5)
particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

---

### 3. 霰弹枪 (Shotgun) ⭐ 最强后坐力

**参数**:
- **水平后坐力**: -direction × (bullet_count × 0.8)
- **垂直后坐力**: +0.6
- **5发散弹**: -direction × 4.0 + 0.6向上
- **效果**: 强烈后退，显著上扬

**物理计算**:
```
子弹数量: 5发
单发动量: 0.5 kg·m/s
总动量: 2.5 kg·m/s
后坐力: 累积效应
```

**代码位置**: `bullet.mbt` - `shoot_shotgun` 函数
```moonbit
let recoil_magnitude = bullet_count.to_double() * 0.8
let recoil_impulse = @box2d.b2Vec2(-direction * recoil_magnitude, 0.6)
particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

---

### 4. 激光枪 (LaserRifle)

**参数**:
- 使用 `shoot_penetrating_bullet` 方法
- **水平后坐力**: -direction × 3.0
- **垂直后坐力**: +0.5
- **效果**: 与狙击枪相同

---

## 📊 后坐力对比表

| 武器 | 水平冲量 | 垂直冲量 | 相对强度 | 效果 |
|------|---------|---------|---------|------|
| 手枪 | -1.5 | +0.3 | ⭐ | 轻微 |
| 狙击枪 | -3.0 | +0.5 | ⭐⭐ | 中等 |
| 激光枪 | -3.0 | +0.5 | ⭐⭐ | 中等 |
| 霰弹枪 | -4.0 (5发) | +0.6 | ⭐⭐⭐ | 强烈 |

---

## 🎮 游戏中的表现

### 向右射击（direction = 1.0）
```
发射前:  ●→ 角色面向右
         ↓ 按S射击
发射后:  ←● 角色被推向左（反向）
         ↖  同时轻微上扬
```

### 向左射击（direction = -1.0）
```
发射前:  ←● 角色面向左
         ↓ 按S射击
发射后:  ●→ 角色被推向右（反向）
         ↗  同时轻微上扬
```

### 霰弹枪效果（特别明显）
```
发射前:  ●→ 准备射击
         ↓ 按S
发射后:  ←←● 强烈后退
         ↖↖  明显上扬
         (5发子弹散射飞出)
```

---

## 🔬 技术细节

### 冲量施加点
```moonbit
let torso_pos = particle.torso.getCenterPosition()
particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

**为什么施加到躯干（torso）？**
1. ✅ 躯干是主体，质量最大
2. ✅ 受力后带动整个角色后退
3. ✅ 真实的后坐力传递路径：枪→手臂→肩膀→身体

### 冲量方向解析

**水平分量**: `-direction * magnitude`
```
direction =  1.0 (向右) → 后坐力 = -1.5 (向左)
direction = -1.0 (向左) → 后坐力 = +1.5 (向右)
```

**垂直分量**: `+recoil_y` (始终向上)
```
原因：枪口上扬是所有枪械的共同特征
效果：角色轻微向上
```

### 后坐力强度设计

**手枪 (1.5)**:
- 单发低动量
- 射速快，需要控制单发后坐力
- 连射时后坐力累积

**狙击枪 (3.0)**:
- 大口径高动量
- 射速慢，可以承受较大后坐力
- 每发之间有恢复时间

**霰弹枪 (4.0)**:
- 多发同时发射
- 后坐力累积效应
- 射速最慢，后坐力最大

---

## 🎯 测试后坐力

### 测试1: 手枪后坐力
```
操作:
1. 按 I 装备手枪
2. 站在平台边缘
3. 面向右，按 S 连续射击

预期效果:
- 每次射击略微向左后退
- 连续射击会累积后退距离
- 轻微向上跳动
```

### 测试2: 狙击枪后坐力
```
操作:
1. 按 P 装备狙击枪
2. 面向右，按 S 射击

预期效果:
- 明显向左后退（约2倍手枪）
- 身体向上扬起
- 单发威力强，后坐力强
```

### 测试3: 霰弹枪后坐力 ⭐
```
操作:
1. 按 O 装备霰弹枪
2. 面向右，按 S 射击

预期效果:
- 强烈向左后退（最强）
- 明显向上扬起
- 5发子弹散射而出
- 可能被推离平台边缘！
```

### 测试4: 空中射击
```
操作:
1. 按 W 跳跃
2. 在空中按 S 射击

预期效果:
- 后坐力改变空中轨迹
- 可以用后坐力进行"二段跳"
- 霰弹枪在空中射击可大幅位移
```

---

## 💡 高级技巧

### 1. 后坐力位移
利用霰弹枪的强后坐力快速后退：
```
面向敌人 → 射击 → 强制后退 → 拉开距离
```

### 2. 后坐力跳跃
在空中利用后坐力改变轨迹：
```
跳跃 → 空中向下射击 → 垂直分量推动向上 → 延长滞空
```

### 3. 连射控制
手枪连射时控制后坐力：
```
射击 → 后退 → 按 D 前进补偿 → 保持位置
```

---

## 🔧 调整后坐力参数

### 如果后坐力太强
```moonbit
// 手枪
let recoil_impulse = @box2d.b2Vec2(-direction * 1.0, 0.2)  // 降低

// 狙击枪
let recoil_impulse = @box2d.b2Vec2(-direction * 2.0, 0.3)  // 降低

// 霰弹枪
let recoil_magnitude = bullet_count.to_double() * 0.5  // 降低系数
```

### 如果后坐力太弱
```moonbit
// 手枪
let recoil_impulse = @box2d.b2Vec2(-direction * 2.0, 0.5)  // 增强

// 狙击枪
let recoil_impulse = @box2d.b2Vec2(-direction * 4.0, 0.8)  // 增强

// 霰弹枪
let recoil_magnitude = bullet_count.to_double() * 1.2  // 增强系数
```

### 如果想要无后坐力（测试用）
```moonbit
// 注释掉后坐力代码
// let recoil_impulse = @box2d.b2Vec2(-direction * 1.5, 0.3)
// particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

---

## 📋 修改的文件

### `src/server/bullet.mbt`

#### 1. shoot_bullet 函数
```moonbit
// 第273-276行：新增后坐力代码
let recoil_impulse = @box2d.b2Vec2(-direction * 1.5, 0.3)
let torso_pos = particle.torso.getCenterPosition()
particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

#### 2. shoot_penetrating_bullet 函数
```moonbit
// 第312-315行：新增后坐力代码
let recoil_impulse = @box2d.b2Vec2(-direction * 3.0, 0.5)
let torso_pos = particle.torso.getCenterPosition()
particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

#### 3. shoot_shotgun 函数
```moonbit
// 第382-386行：新增后坐力代码
let recoil_magnitude = bullet_count.to_double() * 0.8
let recoil_impulse = @box2d.b2Vec2(-direction * recoil_magnitude, 0.6)
let torso_pos = particle.torso.getCenterPosition()
particle.torso.applyImpulse(recoil_impulse, torso_pos)
```

---

## ✅ 验证检查

### 后坐力方向正确 ✅
- **向右射击** (direction = 1.0)
  - 后坐力 = @box2d.b2Vec2(-1.5, 0.3)
  - X分量 < 0 → **向左推** ✅
  
- **向左射击** (direction = -1.0)
  - 后坐力 = @box2d.b2Vec2(+1.5, 0.3)
  - X分量 > 0 → **向右推** ✅

### 符合物理规律 ✅
- ✅ 后坐力与射击方向相反
- ✅ 子弹越快，后坐力越强
- ✅ 多发子弹，后坐力累积
- ✅ 施加到躯干，影响整体

### 游戏平衡性 ✅
- ✅ 手枪：轻微后坐，适合连射
- ✅ 狙击枪：中等后坐，需要瞄准
- ✅ 霰弹枪：强烈后坐，高风险高回报

---

## 🎉 总结

### 实现的功能
✅ 所有武器都有后坐力  
✅ 后坐力方向正确（与射击相反）  
✅ 后坐力强度合理（根据武器类型）  
✅ 垂直分量模拟枪口上扬  
✅ 符合牛顿第三定律  
✅ 编译成功，可立即测试  

### 游戏体验提升
✅ 更真实的射击手感  
✅ 武器差异化更明显  
✅ 增加操作技巧性  
✅ 提供战术选择（位移、跳跃）  

---

**现在开始游戏，感受真实的武器后坐力吧！** 🎮🔫

按键提醒：
- I: 手枪（轻后坐）
- O: 霰弹枪（强后坐）⭐
- P: 狙击枪（中后坐）
- S: 射击并体验后坐力
