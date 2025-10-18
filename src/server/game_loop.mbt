///| Game Loop - Main game loop implementation
/// 游戏主循环实现

///|
/// Create default input state
/// 创建默认输入状态
fn create_input_state() -> InputState {
  InputState::{
    move_left: false,
    move_right: false,
    jump: false,
    attack: false,
    shield: false,
    pickup: false,
    drop_weapon: false,
    throw_weapon: false,
    switch_weapon: false,
    mouse_x: 0.0,
    mouse_y: 0.0,
    mouse_pressed: false,
    mouse_right_pressed: false,
  }
}

///|
/// Initialize game state
/// 初始化游戏状态
pub fn init_game_state(world : Ref[@box2d.B2World]) -> GameState {
  GameState::{
    frame_count: 0,
    is_running: true,
    delta_time: 1.0 / 60.0,
    characters: character_list,
    weapons: weapon_list,
    bullets: bullet_list,
    items: item_list,
    platforms: platform_list,
    world,
    inputs: [create_input_state()],
  }
}

///|
/// Process input for a player
/// 处理玩家输入
pub fn process_input(
  p : &@p5js.P5JS,
  input_state : InputState,
  player_index : Int,
) -> Unit {
  // Movement keys (WASD for player 1, Arrow keys for player 2)
  if player_index == 0 {
    input_state.move_left = p.keyIsDown(KeyA)
    input_state.move_right = p.keyIsDown(KeyD)
    input_state.jump = p.keyIsDown(KeyW)
  } else {
    input_state.move_left = p.keyIsDown(ArrowLeft)
    input_state.move_right = p.keyIsDown(ArrowRight)
    input_state.jump = p.keyIsDown(ArrowUp)
  }

  // Action keys
  input_state.attack = p.mouseIsPressed()
  input_state.shield = false // TODO: Right mouse button
  input_state.drop_weapon = p.keyIsDown(KeyQ)
  input_state.throw_weapon = p.keyIsDown(KeyE)
  input_state.switch_weapon = p.keyIsDown(KeyR)

  // Mouse position (convert from screen to world coordinates)
  input_state.mouse_x = p.getMouseX().to_double()
  input_state.mouse_y = p.getMouseY().to_double()
}

///|
/// Update game state
/// 更新游戏状态
pub fn update_game_state(game_state : GameState) -> Unit {
  let world = game_state.world.val
  let characters = game_state.characters.val
  let weapons = game_state.weapons.val

  // Update frame count
  game_state.frame_count += 1

  // Process each character
  for i = 0; i < characters.length(); i = i + 1 {
    let character = characters[i]
    let input = if i < game_state.inputs.length() {
      game_state.inputs[i]
    } else {
      create_input_state()
    }

    // Skip if character is fainted
    if character.control.is_faint {
      continue
    }

    // Handle movement
    if input.move_left {
      character_walk(character, -1.0)
    } else if input.move_right {
      character_walk(character, 1.0)
    } else if not(character.control.jump_state) {
      character_stand(character)
    }

    // Handle jump
    if input.jump {
      if character.control.jump_cooldown <= 0 {
        if not(character.control.jump_state) {
          character.control.jump_state = true
          character.control.jump_frame_count = 0
          character.control.jump_cooldown = j_dur_A + j_dur_B + j_dur_C
        }
      }
    }
    if character.control.jump_cooldown > 0 {
      character.control.jump_cooldown -= 1
    }
    character_jump(character, 0.0)

    // Handle shield
    if input.shield {
      let mouse_world = screen_to_world(
        Width,
        Height,
        input.mouse_x,
        input.mouse_y,
        PPM,
      )
      let char_pos = character.torso.getCenterPosition()
      let direction = (
        mouse_world.0 - char_pos.getX(),
        mouse_world.1 - char_pos.getY(),
      )
      character_activate_shield(character, direction)
    } else {
      character_deactivate_shield(character)
    }

    // Handle weapon actions
    let current_weapon_id = character_get_current_weapon(character)
    if current_weapon_id >= 0 {
      // Find weapon
      for weapon in weapons {
        if weapon.id == current_weapon_id {
          // Update weapon position and direction
          update_weapon_position(weapon, character)
          let mouse_world = screen_to_world(
            Width,
            Height,
            input.mouse_x,
            input.mouse_y,
            PPM,
          )
          update_weapon_direction(
            weapon,
            mouse_world.0,
            mouse_world.1,
            character,
          )

          // Handle attack
          if input.attack {
            weapon_attack(
              weapon,
              character,
              world,
              game_state.frame_count,
              characters,
            )
            |> ignore
          }
          break
        }
      }

      // Handle drop weapon
      if input.drop_weapon {
        let dropped_weapon_id = character_drop_weapon(character)
        if dropped_weapon_id >= 0 {
          for weapon in weapons {
            if weapon.id == dropped_weapon_id {
              weapon_drop(weapon, character, world)
              break
            }
          }
        }
      }

      // Handle throw weapon
      if input.throw_weapon {
        let thrown_weapon_id = character_drop_weapon(character)
        if thrown_weapon_id >= 0 {
          for weapon in weapons {
            if weapon.id == thrown_weapon_id {
              let mouse_world = screen_to_world(
                Width,
                Height,
                input.mouse_x,
                input.mouse_y,
                PPM,
              )
              let char_pos = character.torso.getCenterPosition()
              let direction = (
                mouse_world.0 - char_pos.getX(),
                mouse_world.1 - char_pos.getY(),
              )
              weapon_throw(weapon, character, direction)
              break
            }
          }
        }
      }

      // Handle switch weapon
      if input.switch_weapon {
        character_switch_weapon(character)
      }
    }

    // Update character state
    update_character(character, game_state.delta_time)
  }

  // Update bullets
  update_bullets(world, characters)

  // Update items
  update_items(world, characters)

  // Step physics world
  world.step(game_state.delta_time, 4)
}

///|
/// Main game loop
/// 主游戏循环
pub fn game_loop(p : &@p5js.P5JS, game_state : GameState) -> Unit {
  if not(game_state.is_running) {
    return
  }

  // Phase 1: Process Input
  for i = 0; i < game_state.inputs.length(); i = i + 1 {
    process_input(p, game_state.inputs[i], i)
  }

  // Phase 2: Update Game State
  update_game_state(game_state)

  // Phase 3: Render
  draw_world(p, game_state.world.val)
}
