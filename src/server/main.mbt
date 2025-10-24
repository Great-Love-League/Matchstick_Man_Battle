const Width: Double = 1000.0
const Height: Double = 1000.0
pub const PPM = 20.0

extern "js" fn getP5Instance(
  drawww : (@p5js.P5Instance) -> Unit,
  width~ : Double = 400,
  height~ : Double = 400
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

extern "js" fn getCanvasWidth(self : &@p5js.P5JS) -> Double =
  #| (self) => self.width

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
fn world_to_screen(world_width: Double, world_height: Double, x: Double, y: Double, ppm : Double) -> (Double, Double) {
  let screen_x_pixle_num = world_width
  let screen_y_pixle_num = world_height
  //println("Canvas Width: \{screen_x_pixle_num}, Height: \{screen_y_pixle_num}")
  return (screen_x_pixle_num/2.0 + x * ppm, screen_y_pixle_num - y * ppm)
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
fn screen_to_world(world_width: Double, world_height: Double, x: Double, y: Double, ppm : Double) -> (Double, Double) {
  let screen_x_pixle_num = world_width
  let screen_y_pixle_num = world_height
  return ((x - screen_x_pixle_num/2.0) / ppm, (screen_y_pixle_num - y) / ppm)
}

fn screen_to_world_size(size: Double, ppm : Double) -> Double {
  return size / ppm
}

fn world_to_screen_size(size: Double, ppm : Double) -> Double {
  return size * ppm
}


fn drawPolygon(p: &@p5js.P5JS, shape: @box2d.B2PolygonShape) -> Unit {
  // 获取顶点
  let vertices = shape.getVertices()
  let global_position : Array[@box2d.B2Vec2] = Array::new()
  for vertex in vertices{
    let gvec = shape.getBody().getWorldPoint(vertex)
    global_position.push(gvec)
  }
  // 转换为屏幕坐标
  let screen_position : Array[(Double, Double)] = Array::new()
  for gvec in global_position {
    let screen_coords = world_to_screen(Width, Height, gvec.getX(), gvec.getY(), PPM)
    screen_position.push(screen_coords)
  }
  // 绘制多边形
  p.beginShape(None)
  for i in 0..<screen_position.length() {
    let (x, y) = screen_position[i]
    p.vertex(x, y, None, None, None)
  }
  p.endShape(Some("close"), None)  // "close" 表示闭合多边形
}

fn drawCircle(p: &@p5js.P5JS, shape: @box2d.B2CircleShape) -> Unit{
  let position = shape.getBody().getWorldPoint(shape.getLocalPosition())
  let radius = shape.getRadius()
  let screen_pos = world_to_screen(Width, Height, position.getX(), position.getY(), PPM)
  let screen_radius = world_to_screen_size(radius, PPM)
//   println("Circle Position: \{position.getX()} , \{position.getY()}")
//   println("Circle Screen Position: \{screen_pos.0} , \{screen_pos.1}")
//   println("Circle Radius: \{radius}")
  p.fillColorPara(200, Some(0.0), Some(0.0), None)
  p.circle(screen_pos.0, screen_pos.1, screen_radius * 2.0)

}


fn draw_world(p: &@p5js.P5JS, world: @box2d.B2World) -> Unit {
  p.background(255.0, Some(204.0), Some(0.0), None)
  for body in world.getBodyList() {
    for shape in body.getShapeList() {
      match shape.getType() {
        PolygonShape => drawPolygon(p, shape.toPolygonShape())
        BoxShape => drawPolygon(p, shape.toPolygonShape())
        CircleShape => drawCircle(p, shape.toCircleShape())
        UnknownShape => {
          println("Unknown Shape")
        }
      }
    }
  }
}

// -------------------- 绘画相关 结束 ---------------------
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

fn box2d_init(game:Game) ->Unit{
  // game.create_platform(
  //   (0.0,0.0),
  //   (10.0,1.0)
  // ) |> ignore

  // 平台2的位置: (-5.77, 8.9)，大小: 10x1
  // 平台顶部: y = 8.9 + 0.5 = 9.4
  // 人物高度约3.5米，所以放在 y = 9.4 + 2.0 = 11.4
  // x坐标在平台范围内: -5.77 ± 5 = (-10.77, -0.77)
  // 选择平台中心偏左: x = -3.0
  game.create_particle((-3.0, 12.0)) |> ignore
	
	
	
  //create_particle(world, (5.0,10.0)) |> ignore

  // let static_box = game.create_static_box(
  //   (1.0,10.0),
  //   (1.0,0.1)
  // )
  // static_box.setAngularVelocity(0.5)
	
	
	Gun::create(game,0)
}

fn main {
	
	let game = create_game()
	
	
  box2d_init(game)
	
	create_rotatable_platform(game,(0,30),(5,1),10.0) |> ignore

  // 创建敌人，放在平台2的右侧
  // 平台2范围: x ∈ (-10.77, -0.77)
  // 将敌人放在右侧: x = -1.0
  create_box_enemy(game, (-1.0, 12.0)) |> ignore
  let rander = @random.Rand::new()

  let p5_instance = getP5Instance(fn(p : @p5js.P5Instance) -> Unit {
    game.update(p)
    draw_world(p, game.world)
  }, width=Width, height=Height)

  //p5_instance |> ignore
}