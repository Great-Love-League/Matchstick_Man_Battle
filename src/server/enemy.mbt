

///|
/// 敌人行动状态枚举
/// - Patrol: 巡逻模式，敌人在区域内随机移动
/// - Pursuit: 追击模式，敌人发现并追逐目标
/// - Attack: 攻击模式，敌人在攻击范围内对目标发起攻击
enum ActionType{
	// 巡逻
	Patrol
	// 追击
	Pursuit
	// 攻击
	Attack
}

///|
/// 敌人通用接口 trait
/// 所有敌人类型都需要实现这个 trait 来提供统一的行为
pub(open) trait EnemyTrait{
	// create(Self,game:Game,position:(Double,Double)) -> Bool
	/// 销毁敌人及其关联的物理体和关节
	destroy(Self, game:Game) -> Unit
	/// 每帧更新敌人的 AI 逻辑和行为
	update(Self, game:Game) -> Unit
	/// 检查敌人是否死亡
	is_dead(Self) -> Bool
	/// 获取当前生命值
	get_hp(Self) -> Double
	/// 获取生命值上限
	get_hp_limit(Self) -> Double
}

///|
/// 方块敌人结构体
/// 这是一个基础的地面敌人，使用 Box2D 物理体
struct BoxEnemy {
	id : Int                              // 敌人唯一标识符
	
	// === 生命值相关 ===
	hp : Double                           // 当前生命值
	hp_limit : Double                     // 生命值上限
	damage_scale : Double                 // 伤害倍率（用于难度调整）
	
	// === 移动相关 ===
	acceleration: @box2d.B2Vec2           // 移动加速度向量
	max_speed : Double                    // 最大移动速度
	jump_force : Double                   // 跳跃力度
	action_type : ActionType              // 当前行动状态
	
	// === AI 相关 ===
	field_of_view : Double                // 视野范围（检测玩家的距离）
	weapon : &WeaponControl?              // 装备的武器（可选）
	
	// === 物理相关 ===
	bodies : Array[@box2d.B2Body]         // Box2D 物理体数组
	joints : Array[@box2d.B2Joint]        // Box2D 关节数组
	mut target_particle_id : Int          // 当前追踪的目标玩家 ID（-1 表示无目标）
}

///|
/// 检查 BoxEnemy 是否死亡
pub impl EnemyTrait for BoxEnemy with is_dead(self : BoxEnemy) -> Bool {
	return self.hp <= 0.0
}

///|
/// 获取 BoxEnemy 当前生命值
pub impl EnemyTrait for BoxEnemy with get_hp(self : BoxEnemy) -> Double {
	return self.hp
}

///|
/// 获取 BoxEnemy 生命值上限
pub impl EnemyTrait for BoxEnemy with get_hp_limit(self : BoxEnemy) -> Double {
	return self.hp_limit
}

///|
/// 销毁 BoxEnemy 及其所有物理组件
/// 会清理所有关联的物理体、关节，并从游戏的敌人列表中移除
pub impl EnemyTrait for BoxEnemy with destroy(self : BoxEnemy, game:Game) -> Unit {
	// 销毁所有物理体
	for body in self.bodies {
		game.world.destroyBody(body)
	}
	
	// 销毁所有关节
	for joint in self.joints {
		game.world.destroyJoint(joint)
	}

	// 从敌人列表中移除
	game.enemy_list[self.id] = None
}

///|
/// 创建方块敌人
/// 
/// 参数：
/// - game: 游戏实例
/// - position: 生成位置 (x, y)
/// 
/// 返回：创建是否成功
fn create_box_enemy(game:Game, position:(Double,Double)) -> Bool {
	// 从资源文件加载物理体定义
	let body = @map_loader.get_bodydef_from_raw(Some(@assets.BOXENEMY_BOX2D_DEFINITION), None) catch {
		_ => {
			println("Error loading BoxEnemy body definition")
			return false
		}
	}
	
	// 设置生成位置
	body.setPosition(@box2d.b2Vec2(position.0, position.1))
	let box_enemy_body = game.world.createBody(body)

	// 在敌人列表中预留位置
	game.enemy_list.push(None)

	// 创建物理体数组
	let bodies = Array::new()
	bodies.push(box_enemy_body)

	// 创建敌人实例
	let box_enemy = BoxEnemy::{
		id: game.enemy_list.length() - 1,    // 使用列表索引作为 ID
		hp:100.0,                             // 初始生命值
		hp_limit:100.0,                       // 生命值上限
		damage_scale:1.0,                     // 伤害倍率
		acceleration:@box2d.b2Vec2(10.0,0.0), // 水平加速度
		max_speed:5.0,                        // 最大速度
		jump_force:15.0,                      // 跳跃力
		action_type:ActionType::Patrol,       // 初始状态为巡逻
		field_of_view:10.0,                   // 视野范围
		weapon: None,                         // 初始无武器
		bodies: bodies,                       // 物理体列表
		joints:Array::new(),                  // 关节列表（初始为空）
		target_particle_id:-1                 // 初始无目标
	}

	// 将敌人添加到游戏列表
	game.enemy_list[box_enemy.id] = Some(box_enemy)

	return true
}

///|
/// 每帧更新 BoxEnemy 的行为
/// 
/// TODO: 当前仅实现了基础物理移动
/// 待实现的功能：
/// 1. 根据 action_type 切换不同行为
/// 2. 巡逻模式：在区域内随机移动
/// 3. 追击模式：检测视野范围内的玩家并追击
/// 4. 攻击模式：在攻击范围内使用武器攻击
/// 5. 碰撞检测和受伤判定
pub impl EnemyTrait for BoxEnemy with update(self : BoxEnemy, game:Game) {
	// 当前仅应用基础的移动力
	// TODO: 需要根据 action_type 实现完整的 AI 逻辑
	self.bodies[0].applyForce(self.acceleration, self.bodies[0].getCenterPosition())
}