///|
/// Platform/Environment Entity
/// 平台/环境实体
pub struct Platform {
  body : @box2d.B2Body
  index : Int

  // Environmental properties
  mut health : Int // 耐久度 (-1表示不可破坏)
  mut max_health : Int
  mut friction : Double // 摩擦力
  mut velocity : (Double, Double) // 速度 (可移动平台)
  mut acceleration : (Double, Double) // 加速度
}
