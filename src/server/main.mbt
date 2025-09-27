fn main {
  @system.App::new(@canvas.CanvasBackend::new())
  .with_canvas_width(VIEWPORT_WIDTH)
  .with_canvas_height(VIEWPORT_HEIGHT)
  .with_image_smooth(false)
  .with_zoom(1)
  .with_fps(60)
  .add_plugin(@plugins.default_plugin)
  // .add_plugin(@plugins.debug_plugin)
  .add_system(game_start, schedule=Startup)
  .add_system(game_main_loop)
  .run()
}

fn box2d_init(world: @box2d.B2World) ->Unit{
  create_platform(
    world,
    (-1.0,3.0),
    (10.0,100.0)
  ) |> ignore

  // particles.val.push(create_particle(world, (0.0,10.0)))

  create_static_box(
    world,
    (1.0,1.0),
    (1.0,0.5)
  ) |> ignore

}

fn draw_box2d(world: @box2d.B2World) -> Unit {

  // update try to add new entity for each body in the world
  body_entity_list.clear()

  println("Bodies in world: \{world.getBodyList().length()}")

  for body in world.getBodyList() {

    let entity = @system.Entity::new()
    body_entity_list.push(entity)

    // let position = body.getCenterPosition()

    let local_vertices : Array[(Double, Double)] = Array::new()

    println("Body Position: \{body.getCenterPosition().getX()} , \{body.getCenterPosition().getY()}")
    println("Body Angle: \{body.getRotation()}")
    println("Body Shape Count: \{body.getShapeList().length()}")

    for shape in body.getShapeList() {
      // 目前只支持box形状
      let box : @box2d.B2PolygonShape  = shape.toPolygonShape()

      let vertices = box.getVertices()

      println("Box Vertices Count: \{box.getVertexCount()}")

      for vertex in vertices {

        let position = box.getPosition()
        let angle = box.getRotationMatrix()

        // 计算顶点在body坐标系下的位置
        let global_x = angle.getCol1().getX() * vertex.getX() + angle.getCol2().getX() * vertex.getY() + position.getX()
        let global_y = angle.getCol1().getY() * vertex.getX() + angle.getCol2().getY() * vertex.getY() + position.getY()

        let local_vertex = @box2d.b2Vec2(global_x, global_y)

        println("Vertex: \{local_vertex.getX()} \{local_vertex.getY()}")

        local_vertices.push((local_vertex.getX(), local_vertex.getY()))

      }

    }

    println("Local Vertices: \{local_vertices}")
    if local_vertices.length() != 4 {
      continue
    }

    fn sqrt(x : Double) -> Double {
      // 使用二分法计算平方根
      if x < 0.0 {
        return 0.0
      }

      let mut low = 0.0
      let mut high = if x < 1.0 { 1.0 } else { x }
      let mut mid = (low + high) / 2.0

      while (high - low).abs() > 0.00000000001 {
        if mid * mid > x {
          high = mid
        } else {
          low = mid
        }
        mid = (low + high) / 2.0
      }
      mid
    }

    fn get_distance(a: (Double, Double), b: (Double, Double)) -> Double {
      sqrt((a.0 - b.0)*(a.0 - b.0) + (a.1 - b.1)*(a.1 - b.1))
    }

    let entity = @system.Entity::new()
    // 创建一个黑色的矩形作为精灵
    let rectangle = @sprite.ColorRect::new(@math.Vec2D(
      PPM*(get_distance(local_vertices[0], local_vertices[2])),
      PPM*(get_distance(local_vertices[1], local_vertices[3]))
    ), "black")

    let sprite = @sprite.Sprite::from_color_rect(rectangle, 0)

    @sprite.sprites.set(entity, sprite)

    let image_pos = world_to_screen((body.getCenterPosition()).getX(), (body.getCenterPosition()).getY())
    

    @position.positions.set(entity, @math.Vec2D(
      image_pos.0,
      image_pos.1
    ))
  }


}

fn game_start(backend : &@system.Backend, _dt: Double) -> Unit {
  // 添加背景
  let background = @system.Entity::new()
  let background_sprite = @sprite.Sprite::from_picture(
    @sprite.Picture::new(@math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT), "assets/Background/Gray.png", repeat=Repeat),
    0,
  )
  @sprite.sprites.set(background, background_sprite)
  @position.positions.set(background, @math.Vec2D(0, 0))

  box2d_init(world.val)

}

fn game_main_loop(backend : &@system.Backend, dt: Double) -> Unit {

  world.val.step(dt, 4)
  draw_box2d(world.val)

  if @system.is_pressed(KeyA){
    // walk(particles.val[0], -1.0)
  }
  if @system.is_pressed(KeyD){
    // walk(particles.val[0], 1.0)
  }

}