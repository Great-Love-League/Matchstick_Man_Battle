pub(all) struct SampleAnimation {
  fun : (&@box2d.World, @p5js.P5Instance) -> AnimationState
}

pub fn SampleAnimation::new(fun: (&@box2d.World, @p5js.P5Instance) -> AnimationState) -> Self {
  SampleAnimation::{
    fun: fun
  }
}

pub impl Animation for SampleAnimation with update (self: SampleAnimation, world: &@box2d.World, p5: @p5js.P5Instance) -> AnimationState {
  (self.fun)(world, p5)
}
pub struct SmokeParticle {
  mut x: Double
  mut y: Double
  mut r: Double
  mut alpha: Double
  mut vx: Double
  mut vy: Double
  mut rot: Double
  mut life: Double
}

pub fn random_range(min: Double, max: Double) -> Double {
  let t = @random.Rand::new()
  let a = t.double()
  return (a * (max - min)) + min
}

fn register_smoke_animation(game: Game, base_x: Double, base_y: Double) -> Unit {
  let frame_counter = { val: 0 }
  let smokes: Ref[Array[SmokeParticle]] = Ref::new(Array::new())

  let animation = SampleAnimation::new(
    fn(world: &@box2d.World, p5: @p5js.P5Instance) -> AnimationState {
      world |> ignore
      frame_counter.val = frame_counter.val + 1

      // —— 第一次帧：环形爆发，产生集中气场 —— 
      if frame_counter.val == 1 {
        let burst_count = 24
        for i = 0; i < burst_count; i = i + 1 {
          let ang = (i.to_double() / burst_count.to_double()) * 2.0 * 3.14159265359 + random_range(-0.15, 0.15)
          let dist = random_range(2.0, 6.0)        // 初始分布更靠近中心
          let speed = random_range(0.6, 1.5)       // 扩散速度较小，更集中
          let p = SmokeParticle::{
            x: base_x + @cmath.cos(ang) * dist,
            y: base_y + @cmath.sin(ang) * dist * 0.6,  // y方向压缩，形成略椭圆形气场
            r: random_range(3.0, 7.0),
            alpha: random_range(180.0, 255.0),
            vx: @cmath.cos(ang) * speed * 0.5,  // 更轻的径向运动
            vy: random_range(-0.6, -0.25),
            rot: random_range(0.0, 6.28318530718),
            life: random_range(60.0, 90.0)
          }
          smokes.val.push(p)
        }
      }

      // —— 后续轻微补烟，脚下余气 —— 
      if frame_counter.val.mod(8) == 0 && frame_counter.val < 60 {
        let p = SmokeParticle::{
          x: base_x + random_range(-3.0, 3.0),
          y: base_y + random_range(-2.0, 2.0),
          r: random_range(2.0, 5.0),
          alpha: random_range(150.0, 220.0),
          vx: random_range(-0.3, 0.3),
          vy: random_range(-0.4, -0.1),
          rot: random_range(0.0, 6.28318530718),
          life: random_range(40.0, 70.0)
        }
        smokes.val.push(p)
      }

      // 绘制背景淡层（让气场更柔和）
      p5.noStroke()
      p5.fillColorPara(255.0, Some(255.0), Some(255.0), Some(15.0))

      let alive: Array[SmokeParticle] = []
      for s in smokes.val {
        let mut p = s

        // —— 运动更新 —— 
        p.x = p.x + p.vx + 0.08 * @cmath.sin(p.rot + frame_counter.val.to_double() * 0.07)
        p.y = p.y + p.vy + 0.05 * @cmath.cos(p.rot + frame_counter.val.to_double() * 0.05)
        p.r = p.r + 0.05
        p.alpha = p.alpha - (180.0 / (p.life + 5.0))
        p.rot = p.rot + 0.08
        p.life = p.life - 1.0

        // —— 绘制多层发光烟雾 —— 
        if p.alpha > 8.0 && p.life > 0.0 {
          let base_r = 210.0
          let base_g = 235.0
          let base_b = 255.0

          p5.noStroke()
          // 外层朦胧
          p5.fillColorPara(base_r, Some(base_g), Some(base_b), Some(p.alpha * 0.25))
          p5.ellipse(p.x, p.y, p.r * 2.0, p.r * 2.0)
          // 中层
          p5.fillColorPara(base_r, Some(base_g), Some(base_b), Some(p.alpha * 0.55))
          p5.ellipse(p.x, p.y, p.r * 1.2, p.r * 1.2)
          // 内层亮点
          p5.fillColorPara(255.0, Some(255.0), Some(255.0), Some(p.alpha * 0.8))
          p5.ellipse(p.x, p.y, p.r * 0.45, p.r * 0.45)

          alive.push(p)
        }
      }

      smokes.val.clear()
      for pp in alive {
        smokes.val.push(pp)
      }

      // 结束条件
      if smokes.val.length() == 0 && frame_counter.val > 100 {
        return AnimationState::Completed
      }

      AnimationState::InProgress
    }
  )

  game.add_animation(animation)
  println("踏空气场烟雾已注册在 (\{base_x}, \{base_y})")
}