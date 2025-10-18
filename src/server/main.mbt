///|
const Width : Double = 1000.0

///|
const Height : Double = 1000.0

///|
pub const PPM = 20.0

///|
extern "js" fn getP5Instance(
  drawww : (@p5js.P5Instance) -> Unit,
  width? : Double = 400,
  height? : Double = 400,
) -> @p5js.P5Instance =
  #| (drawww, width, height) => {
  #|   a = new p5((p)=>{
  #|  p.setup = function() {
  #|    p.createCanvas(width, height);
  #|  }
  #|  p.draw = function() {drawww(p)}
  #|})
  #|return a
  #|}

///|
extern "js" fn getCanvasWidth(self : &@p5js.P5JS) -> Double =
  #| (self) => self.width

///|
extern "js" fn getCanvasHeight(self : &@p5js.P5JS) -> Double =
  #| (self) => self.height

///|
/// 坐标转换函数，坐标系如下
/// -----------> x_canvas
/// |           ^ y_box2d
/// |           |
/// |           |
/// |           |
/// |           |
/// |           |
/// vy_canvas    -------------> x_box2d
/// canvas 的原点在画布左上角
/// box2d 的原点在画布宽度的二分之一处，画布高度的最下面
/// 首先通过 ppm 将单位进行转换，然后通过坐标系转换，最后进行平移
fn world_to_screen(
  world_width : Double,
  world_height : Double,
  x : Double,
  y : Double,
  ppm : Double,
) -> (Double, Double) {
  let screen_x_pixle_num = world_width
  let screen_y_pixle_num = world_height
  //println("Canvas Width: \{screen_x_pixle_num}, Height: \{screen_y_pixle_num}")
  return (screen_x_pixle_num / 2.0 + x * ppm, screen_y_pixle_num - y * ppm)
}

///|
/// 坐标转换函数，坐标系如下
/// -----------> x_canvas
/// |           ^ y_box2d
/// |           |
/// |           |
/// |           |
/// |           |
/// |           |
/// vy_canvas    -------------> x_box2d
/// canvas 的原点在画布左上角
/// box2d 的原点在画布宽度的二分之一处，画布高度的最下面
/// 首先通过 ppm 将单位进行转换，然后通过坐标系转换，最后进行平移
fn screen_to_world(
  world_width : Double,
  world_height : Double,
  x : Double,
  y : Double,
  ppm : Double,
) -> (Double, Double) {
  let screen_x_pixle_num = world_width
  let screen_y_pixle_num = world_height
  return ((x - screen_x_pixle_num / 2.0) / ppm, (screen_y_pixle_num - y) / ppm)
}

///|
fn screen_to_world_size(size : Double, ppm : Double) -> Double {
  return size / ppm
}

///|
fn world_to_screen_size(size : Double, ppm : Double) -> Double {
  return size * ppm
}

///|
fn drawPolygon(p : &@p5js.P5JS, shape : @box2d.B2PolygonShape) -> Unit {
  // 获取顶点
  let vertices = shape.getVertices()
  let global_position : Array[@box2d.B2Vec2] = Array::new()
  for vertex in vertices {
    let gvec = shape.getBody().getWorldPoint(vertex)
    global_position.push(gvec)
  }
  // 转换为屏幕坐标
  let screen_position : Array[(Double, Double)] = Array::new()
  for gvec in global_position {
    let screen_coords = world_to_screen(
      Width,
      Height,
      gvec.getX(),
      gvec.getY(),
      PPM,
    )
    screen_position.push(screen_coords)
  }
  // 绘制多边形
  p.beginShape(None)
  for i in 0..<screen_position.length() {
    let (x, y) = screen_position[i]
    p.vertex(x, y, None, None, None)
  }
  p.endShape(Some("close"), None) // "close" 表示闭合多边形
}

///|
fn drawCircle(p : &@p5js.P5JS, shape : @box2d.B2CircleShape) -> Unit {
  let position = shape.getBody().getWorldPoint(shape.getLocalPosition())
  let radius = shape.getRadius()
  let screen_pos = world_to_screen(
    Width,
    Height,
    position.getX(),
    position.getY(),
    PPM,
  )
  let screen_radius = world_to_screen_size(radius, PPM)
  //   println("Circle Position: \{position.getX()} , \{position.getY()}")
  //   println("Circle Screen Position: \{screen_pos.0} , \{screen_pos.1}")
  //   println("Circle Radius: \{radius}")
  p.fillColorPara(200, Some(0.0), Some(0.0), None)
  p.circle(screen_pos.0, screen_pos.1, screen_radius * 2.0)
}

///|
fn draw_world(p : &@p5js.P5JS, world : @box2d.B2World) -> Unit {
  p.background(255.0, Some(204.0), Some(0.0), None)
  for body in world.getBodyList() {
    for shape in body.getShapeList() {
      match shape.getType() {
        PolygonShape => drawPolygon(p, shape.toPolygonShape())
        BoxShape => drawPolygon(p, shape.toPolygonShape())
        CircleShape => drawCircle(p, shape.toCircleShape())
        UnknownShape => println("Unknown Shape")
      }
    }
  }
}

// -------------------- 绘画相关 结束 ---------------------

///|
/// 绘画样例阐述
/// Width Height 用于控制画布的宽高
/// PPM 用于控制物理世界单位与屏幕像素的转换比例，1个物理单位等于多少像素
/// 具体坐标系问题请查看 world_to_screen 的注释
/// 使用的时候，请先 使用 getP5Instance 创建 p5js 对象，然后在回调中游戏逻辑
/// 
/// let p5_instance = getP5Instance(fn(p : @p5js.P5Instance) -> Unit {
///   world.step(1.0/60.0, 4)
///   draw_world(p, world)
/// }, width=Width, height=Height)
/// 
/// 
/// 绘画只需要调用 draw_world 即可，注意要step world!!!!!!!!
fn box2d_init(world : @box2d.B2World) -> Unit {
  create_platform(world, (0.0, 0.0), (10.0, 1.0)) |> ignore
  create_particle(world, (0.0, 10.0)) |> ignore
  //create_particle(world, (5.0,10.0)) |> ignore

  let static_box = create_static_box(world, (1.0, 10.0), (1.0, 0.1))
  static_box.setAngularVelocity(0.5)
  //   let circledef = @box2d.b2CircleDef()
  //   circledef.setRadius(0.5)
  //   circledef.setDensity(1.0)
  //   circledef.setFriction(0.3)
  //   circledef.setLocalPosition(@box2d.b2Vec2(0.0,0.0))

  //   let circlebodyDef = @box2d.b2BodyDef()
  //   circlebodyDef.setPosition(@box2d.b2Vec2(0.0, 4.0))
  //   circlebodyDef.addShape(circledef.getBase())
  //   world.createBody(circlebodyDef) |> ignore

}

///|
/// Test weapon
let test_weapon : Ref[Weapon?] = Ref::new(None)

///|
/// Frame counter
let frame_counter : Ref[Int] = Ref::new(0)

///|
/// Check if weapon can be picked up
fn can_pickup_weapon(particle : Particle, weapon : Weapon) -> Bool {
  if weapon.owner_id != -1 {
    return false // Already owned
  }
  let particle_pos = particle.torso.getCenterPosition()
  let weapon_pos = weapon.body.getCenterPosition()
  let dx = weapon_pos.getX() - particle_pos.getX()
  let dy = weapon_pos.getY() - particle_pos.getY()
  let distance = @cmath.sqrt(dx * dx + dy * dy)
  distance < 2.0 // Within 2 units
}

///|
/// Pickup weapon and attach to character
fn pickup_weapon(particle : Particle, weapon : Weapon) -> Unit {
  weapon.owner_id = particle.index
  println("Picked up weapon! Owner: \{weapon.owner_id}")
}

///|
/// Drop weapon
fn drop_weapon(weapon : Weapon) -> Unit {
  weapon.owner_id = -1
  // Give weapon a small velocity away from player
  weapon.body.setLinearVelocity(@box2d.b2Vec2(0.0, 2.0))
  println("Dropped weapon!")
}

///|
fn main {
  box2d_init(world.val)

  // Create a test weapon (Gun) on the ground
  let weapon = create_weapon(world.val, (2.0, 5.0), WeaponType::Gun)
  test_weapon.val = Some(weapon)
  let p5_instance = getP5Instance(
    fn(p : @p5js.P5Instance) -> Unit {
      frame_counter.val += 1

      // Pickup weapon with E key
      match test_weapon.val {
        Some(weapon) => {
          if p.keyIsDown(KeyE) {
            if can_pickup_weapon(particle_list.val[0], weapon) {
              pickup_weapon(particle_list.val[0], weapon)
            }
          }

          // Drop weapon with Q key
          if p.keyIsDown(KeyQ) {
            if weapon.owner_id == particle_list.val[0].index {
              drop_weapon(weapon)
            }
          }

          // Update weapon position if owned
          if weapon.owner_id == particle_list.val[0].index {
            let forearm_pos = particle_list.val[0].right_forearm.getCenterPosition()
            let forearm_rotation = particle_list.val[0].right_forearm.getRotation()
            let offset_x = @cmath.cos(forearm_rotation) * 0.3
            let offset_y = @cmath.sin(forearm_rotation) * 0.3
            let target_x = forearm_pos.getX() + offset_x
            let target_y = forearm_pos.getY() + offset_y
            maintain_position(weapon.body, (target_x, target_y), kp=500.0, kd=20.0)
            maintain_rotation(weapon.body, forearm_rotation, kp=100.0, kd=10.0)
          }

          // Fire weapon with S key (only if owned)
          if weapon.owner_id == particle_list.val[0].index && p.keyIsDown(KeyS) {
            // Fire weapon toward mouse
            let mouse_world_x = (p.getMouseX().to_double() - Width / 2.0) / PPM
            let mouse_world_y = (Height - p.getMouseY().to_double()) / PPM
            let weapon_pos = weapon.body.getCenterPosition()
            let dx = mouse_world_x - weapon_pos.getX()
            let dy = mouse_world_y - weapon_pos.getY()
            let angle = @cmath.atan2(dy, dx)
            weapon.direction = angle

            // Try to fire
            if frame_counter.val - weapon.last_fire_time >=
              weapon.min_attack_interval &&
              weapon.ammo_count != 0 {
              weapon.last_fire_time = frame_counter.val

              // Create bullet
              let spawn_x = weapon_pos.getX() + @cmath.cos(angle) * 0.6
              let spawn_y = weapon_pos.getY() + @cmath.sin(angle) * 0.6
              create_bullet(
                world.val,
                0,
                (spawn_x, spawn_y),
                (@cmath.cos(angle), @cmath.sin(angle)),
                weapon.initial_bullet_speed,
                20,
                BulletType::Normal,
                180,
              )
              |> ignore
              if weapon.ammo_count > 0 {
                weapon.ammo_count -= 1
              }
              println("Fired! Ammo: \{weapon.ammo_count}")
            }
          }
        }
        None => ()
      }

      // Update bullets
      update_bullets(world.val, Array::new())

      // Character control (original code)
      if p.keyIsDown(KeyA) {
        particle_walk(particle_list.val[0], -1)
      } else if p.keyIsDown(KeyD) {
        particle_walk(particle_list.val[0], 1)
      } else if !particle_list.val[0].control.jump_state {
        particle_stand(particle_list.val[0])
      }
      if p.keyIsDown(KeyW) {
        if particle_list.val[0].control.jump_cooldown <= 0 {
          if !particle_list.val[0].control.jump_state { // 如果不在跳跃状态，则开始跳跃
            particle_list.val[0].control.jump_state = true
            particle_list.val[0].control.jump_frame_count = 0 // 重置跳跃帧计数
            particle_list.val[0].control.jump_cooldown = j_dur_A +
              j_dur_B +
              j_dur_C // 总共跳跃帧数
          }
        }
      }
      if particle_list.val[0].control.jump_cooldown > 0 {
        particle_list.val[0].control.jump_cooldown -= 1
      }
      particle_jump(particle_list.val[0], 0)

      // Physics step
      world.val.step(1.0 / 60.0, 4)

      // Render
      draw_world(p, world.val)
    },
    width=Width,
    height=Height,
  )

  //p5_instance |> ignore
}
