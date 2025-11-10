fn load_custom_functions(game:@server.Game) -> Unit {

  /// 昏迷功能
  game.register_custom_function(
    @server.GameCustomFunction::new(
      @server.GameRunning,
      fn(game: @server.Game, p5: &@p5js.P5JS) {
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
    @server.GameCustomFunction::new(
      @server.GameRunning,
      fn(game: @server.Game, p: &@p5js.P5JS) {
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
          game.create_shotgun(0, Some("src/assets/gun2.png"))
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
    @server.GameCustomFunction::new(
      @server.GameRunning,
      fn(game: @server.Game, p5: &@p5js.P5JS) {
        if(p5.keyIsDown(KeyK)){
          let particle_pos = game.particle_list[0].torso.getCenterPosition()
          game.spawn_health_pack((particle_pos.getX() + 3.0, particle_pos.getY()))
        }
      }
    )
  )

  /// 鼠标射击功能 - 左键点击朝鼠标方向射击（支持自动瞄准）
  game.register_custom_function(
    @server.GameCustomFunction::new(
      @server.GameRunning,
      fn(game: @server.Game, p5: &@p5js.P5JS) {
        // 检查是否按下鼠标左键
        if p5.mouseIsPressed() {
          let player_id = 0
          
          // 先检查是否启用自动瞄准
          let angle = match game.get_auto_aim_config(player_id) {
            Some(config) => match game.get_auto_aim_angle(player_id, config) {
              Some(auto_angle) => auto_angle  // 使用自动瞄准角度
              None => {
                // 没有自动瞄准目标，使用鼠标位置
                let mouse_x = p5.getMouseX().to_double()
                let mouse_y = p5.getMouseY().to_double()
                let world_coords = @server.screen_to_world(mouse_x, mouse_y)
                let player_pos = game.particle_list[player_id].torso.getCenterPosition()
                let dx = world_coords.0 - player_pos.getX()
                let dy = world_coords.1 - player_pos.getY()
                @cmath.atan2(dy, dx)
              }
            }
            None => {
              // 没有配置自动瞄准，使用鼠标位置
              let mouse_x = p5.getMouseX().to_double()
              let mouse_y = p5.getMouseY().to_double()
              let world_coords = @server.screen_to_world(mouse_x, mouse_y)
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

  /// 添加血量输出
  game.register_custom_function(
    @server.GameCustomFunction::new(
      @server.GameRunning,
      fn(game: @server.Game, p5: &@p5js.P5JS) {
        p5 |> ignore
        // 每100帧输出一次血量
        if game.frame_count % 100 == 0 {
          for particle in game.particle_list {
            println("玩家 \{particle.index} 血量: \{particle.control.health}")
          }
        }
      }
    )
  )

}

fn main {
  let game = @server.create_game()
  @server.load_map(game, 2) |> ignore
	@server.Gun::create(game,0,Some("src/assets/gun1.png"))
	@server.Gun::create(game,1,Some("pistol"))

  load_custom_functions(game)
  
  @server.register_control(game)
  
  @server.register_auto_aim(game)

  @server.register_hp_show(game)

  @server.register_show_mouse_screen_coords(game)

  game.start_run()

}