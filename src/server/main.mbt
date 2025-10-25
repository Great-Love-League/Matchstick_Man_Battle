pub const PPM = 20.0
const Width: Double = 1000.0
const Height: Double = 1000.0

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
  game.create_particle((-10.0, 12.0)) |> ignore
	
	
	
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
	
	create_movable_platform(game,(5,1),(0,20),(0,40),1) |> ignore
	
	create_rotatable_platform(game,(5,1),(-15,20),1) |> ignore
	
	create_platform(game,(-20,5),(10,1)) |> ignore

  // 创建敌人，放在平台2的右侧
  // 平台2范围: x ∈ (-10.77, -0.77)
  // 将敌人放在右侧: x = -1.0
  //create_box_enemy(game, (-1.0, 12.0)) |> ignore
  let rander = @random.Rand::new()

  let p5_instance = getP5Instance(fn(p : @p5js.P5Instance) -> Unit {
    game.update(p)
    draw_world(p, game.world)
  }, width=Width, height=Height)

  //p5_instance |> ignore
}