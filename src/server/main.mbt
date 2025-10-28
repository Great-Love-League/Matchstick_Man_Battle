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

  game.create_particle((-5.0, 12.0)) |> ignore
	
	
	
  //create_particle(world, (5.0,10.0)) |> ignore

  // let static_box = game.create_static_box(
  //   (1.0,10.0),
  //   (1.0,0.1)
  // )
  // static_box.setAngularVelocity(0.5)
	
	
	Gun::create(game,0)
	Gun::create(game,1)
}

fn load_custom_functions(game:Game) -> Unit {

  /// 昏迷功能
  game.register_custom_function(
    GameCustomFunction::new(
      GameRunning,
      fn(game: Game, p5: @p5js.P5Instance) {
        if(game.particle_list[0].control.faint_state){
          if(game.particle_list[0].control.faint_resistance<300){
            game.particle_list[0].control.faint_resistance+=1
          }
          else{
            game.particle_list[0].control.faint_state=false
            game.particle_list[0].control.health=100
            game.particle_list[0].control.faint_resistance=0
          }
          return
        }
        if(p5.keyIsDown(KeyJ)){
          game.particle_list[0].control.faint_state=true
        }
      }
    )
  )

  /// 武器切换功能
  game.register_custom_function(
    GameCustomFunction::new(
      GameRunning,
      fn(game: Game, p: @p5js.P5Instance) {
        if(p.keyIsDown(Digit1)){
          // 销毁旧武器
          for gun in game.weapon.gun_list {
            if gun.owner_id == 0 {
              gun.destroy(game)
            }
          }
          game.weapon.gun_list.clear()
          // 创建手枪
          game.create_pistol(0)
          println("装备手枪!")
        }
        if(p.keyIsDown(Digit2)){
          // 销毁旧武器
          for gun in game.weapon.gun_list {
            if gun.owner_id == 0 {
              gun.destroy(game)
            }
          }
          game.weapon.gun_list.clear()
          // 创建霰弹枪
          game.create_shotgun(0)
          println("装备霰弹枪!")
        }
        if(p.keyIsDown(Digit3)){
          // 销毁旧武器
          for gun in game.weapon.gun_list {
            if gun.owner_id == 0 {
              gun.destroy(game)
            }
          }
          game.weapon.gun_list.clear()
          // 创建狙击枪
          game.create_sniper(0)
          println("装备狙击枪!")
        }
        if(p.keyIsDown(Digit4)){
          // 销毁旧武器
          for gun in game.weapon.gun_list {
            if gun.owner_id == 0 {
              gun.destroy(game)
            }
          }
          game.weapon.gun_list.clear()
          // 创建激光枪
          game.create_laser_rifle(0)
          println("装备激光枪!")
        }
      }
    )
  )

  /// 测试生成物品 - K键在角色前方生成生命包
  game.register_custom_function(
    GameCustomFunction::new(
      GameRunning,
      fn(game: Game, p5: @p5js.P5Instance) {
        if(p5.keyIsDown(KeyK)){
          let particle_pos = game.particle_list[0].torso.getCenterPosition()
          game.spawn_health_pack((particle_pos.getX() + 3.0, particle_pos.getY()))
        }
      }
    )
  )

  /// 鼠标射击功能 - 左键点击朝鼠标方向射击（支持自动瞄准）
  game.register_custom_function(
    GameCustomFunction::new(
      GameRunning,
      fn(game: Game, p5: @p5js.P5Instance) {
        // 检查是否按下鼠标左键
        if mouseIsPressed(p5) {
          let player_id = 0
          
          // 先检查是否启用自动瞄准
          let angle = match game.get_auto_aim_config(player_id) {
            Some(config) => match game.get_auto_aim_angle(player_id, config) {
              Some(auto_angle) => auto_angle  // 使用自动瞄准角度
              None => {
                // 没有自动瞄准目标，使用鼠标位置
                let mouse_x = getMouseX(p5)
                let mouse_y = getMouseY(p5)
                let world_coords = screen_to_world(Width, Height, mouse_x, mouse_y, PPM)
                let player_pos = game.particle_list[player_id].torso.getCenterPosition()
                let dx = world_coords.0 - player_pos.getX()
                let dy = world_coords.1 - player_pos.getY()
                @cmath.atan2(dy, dx)
              }
            }
            None => {
              // 没有配置自动瞄准，使用鼠标位置
              let mouse_x = getMouseX(p5)
              let mouse_y = getMouseY(p5)
              let world_coords = screen_to_world(Width, Height, mouse_x, mouse_y, PPM)
              let player_pos = game.particle_list[player_id].torso.getCenterPosition()
              let dx = world_coords.0 - player_pos.getX()
              let dy = world_coords.1 - player_pos.getY()
              @cmath.atan2(dy, dx)
            }
          }
          
          // 查找玩家的武器并发射
          for gun in game.weapon.gun_list {
            if gun.owner_id == player_id {
              gun.attack_at_angle(game, angle)
              break
            }
          }
        }
      }
    )
  )

  /// 自动瞄准切换功能 - T键切换自动瞄准
  game.register_custom_function(
    GameCustomFunction::new(
      GameRunning,
      fn(game: Game, p5: @p5js.P5Instance) {
        if p5.keyIsDown(KeyT) {
          // 使用cooldown避免重复触发
          let player_id = 0
          if game.frame_count % 30 == 0 {  // 每半秒最多切换一次
            game.toggle_auto_aim(player_id)
            match game.get_auto_aim_config(player_id) {
              Some(config) => {
                if config.enabled {
                  println("玩家 \{player_id}: 自动瞄准已启用")
                } else {
                  println("玩家 \{player_id}: 自动瞄准已禁用")
                }
              }
              None => ()
            }
          }
        }
      }
    )
  )

}

fn register_control(game:Game) -> Unit{
  game.register_particle_control_config(
    ParticleControlConfig::new(
      0,
      left_key = Some(@p5js.KeyA),
      right_key = Some(@p5js.KeyD),
      jump_key = Some(@p5js.KeyW),
      shoot_key = Some(@p5js.KeyZ),
      from_internet = false,
    )
  ) catch {
    ParticleControlConfigError(e) =>{
      println("Error registering particle control config: \{e}")
    }
  }

  game.register_particle_control_config(
    ParticleControlConfig::new(
      1,
      left_key = Some(@p5js.ArrowLeft),
      right_key = Some(@p5js.ArrowRight),
      jump_key = Some(@p5js.ArrowUp),
      shoot_key = Some(@p5js.ArrowDown),
      from_internet = false,
    )
  ) catch {
    ParticleControlConfigError(e) =>{
      println("Error registering particle control config: \{e}")
    }
  }
}

fn register_auto_aim(game:Game) -> Unit {
  // 为玩家0注册自动瞄准配置
  // 默认禁用，可通过T键切换
  // 默认仅瞄准敌人，最大范围50米
  let config_player0 = AutoAimConfig::new(
    enabled=false,
    target_types=[EntityType::Enemy],
    max_range=50.0
  )
  game.register_auto_aim_config(0, config_player0)
  
  // 为玩家1注册自动瞄准配置
  let config_player1 = AutoAimConfig::new(
    enabled=false,
    target_types=[EntityType::Enemy],
    max_range=50.0
  )
  game.register_auto_aim_config(1, config_player1)
  
  println("自动瞄准系统已初始化")
  println("  - 按 T 键切换自动瞄准开关")
  println("  - 默认仅瞄准敌方AI实体")
  println("  - 最大瞄准距离: 50米")
}

fn main {
	
	let game = create_game()
	
	
  box2d_init(game)
	
	create_movable_platform(game,(5,1),(0,20),(0,40),1) |> ignore
	
	create_rotatable_platform(game,(10,1),(-15,20),0,initial_angle=0.5) |> ignore
	
	create_platform(game,(-20,5),(10,1)) |> ignore

  load_custom_functions(game)

  register_control(game)
  
  register_auto_aim(game)

  let p5_instance = getP5Instance(fn(p : @p5js.P5Instance) -> Unit {
    game.state_machine_update(p)
    draw_world(p, game.world)
  }, width=Width, height=Height)

  p5_instance |> ignore
}