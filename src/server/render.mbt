extern "js" fn getP5Instance(
  drawww : (@p5js.P5Instance) -> Unit,
  width~ : Double = Width,
  height~ : Double = Height
) -> @p5js.P5Instance = 
  #| (drawww, width, height) => {
  #|   a = new p5((p)=>{
  #|  p.setup = function() {
  #|    p.createCanvas(width, height);
  #|  }
  #|  p.draw = function() {
  #|    drawww(p);
  #|  }
  #|})
  #|return a
  #|}

// extern "js" fn getCanvasWidth(self : &@p5js.P5JS) -> Double =
//   #| (self) => self.width

// extern "js" fn getCanvasHeight(self : &@p5js.P5JS) -> Double =
//   #| (self) => self.height

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
pub fn world_to_screen(world_width~: Double = Width, world_height~: Double = Height, x: Double, y: Double, ppm~: Double = PPM) -> (Double, Double) {
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
pub fn screen_to_world(world_width~: Double = Width, world_height~: Double = Height, x: Double, y: Double, ppm~: Double = PPM) -> (Double, Double) {
  let screen_x_pixle_num = world_width
  let screen_y_pixle_num = world_height
  return ((x - screen_x_pixle_num/2.0) / ppm, (screen_y_pixle_num - y) / ppm)
}

pub fn screen_to_world_size(size: Double, ppm : Double) -> Double {
  return size / ppm
}

pub fn world_to_screen_size(size: Double, ppm : Double) -> Double {
  return size * ppm
}


pub fn drawPolygon(p: &@p5js.P5JS, shape: @box2d.B2PolygonShape) -> Unit {
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
    let screen_coords = world_to_screen(gvec.getX(), gvec.getY())
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

pub fn drawCircle(p: &@p5js.P5JS, shape: @box2d.B2CircleShape) -> Unit{
  let position = shape.getBody().getWorldPoint(shape.getLocalPosition())
  let radius = shape.getRadius()
  let screen_pos = world_to_screen(position.getX(), position.getY())
  let screen_radius = world_to_screen_size(radius, PPM)
//   println("Circle Position: \{position.getX()} , \{position.getY()}")
//   println("Circle Screen Position: \{screen_pos.0} , \{screen_pos.1}")
//   println("Circle Radius: \{radius}")
  // p.fillColorPara(200, Some(0.0), Some(0.0), None) //子弹射出后全部物体变红bug
  p.circle(screen_pos.0, screen_pos.1, screen_radius * 2.0)

}


pub fn DefaultRenderable::draw_world(self: DefaultRenderable, p: &@p5js.P5JS, world: &@box2d.World) -> Unit {
  // p.background(255.0, Some(204.0), Some(0.0), None)
  self |> ignore
  for body in world.getBodyList() {
    for shape in body.getShapeList() {
      // 填充颜色
      p.fillColorPara(127.0, Some(127.0), Some(127.0), Some(200.0))
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

pub fn DefaultRenderable::clear_screen(self: DefaultRenderable, p: &@p5js.P5JS) -> Unit {
  self |> ignore
  p.background(255.0, Some(204.0), Some(0.0), None)
}
pub(all) struct DefaultRenderable {}

pub impl Renderable for DefaultRenderable with render(self: DefaultRenderable, world: &@box2d.World, p: &@p5js.P5JS) -> Unit {
  self.draw_world(p, world)
}

pub impl Renderable for DefaultRenderable with clear_screen(self: DefaultRenderable, world: &@box2d.World, p: &@p5js.P5JS) -> Unit {
  world |> ignore 
  self.clear_screen(p)
}

pub trait Renderable {

  // 绘画函数，在所有更新逻辑之后调用，用于绘画物理世界，但是不包含特效等
  render(self: Self, world: &@box2d.World, p: &@p5js.P5JS) -> Unit

  // 在每次绘画前清屏
  clear_screen(self: Self, world: &@box2d.World, p: &@p5js.P5JS) -> Unit 
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