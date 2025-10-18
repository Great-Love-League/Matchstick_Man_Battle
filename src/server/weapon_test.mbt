///| Weapon Test - Simple weapon instance with bullet firing
/// 武器测试 - 简单的武器实例和子弹发射测试

///|
/// Create test weapon instance
/// 创建测试武器实例
pub fn create_test_weapon(
  world : @box2d.B2World,
  weapon_type : WeaponType,
) -> Weapon {
  // Create weapon at center-left of screen
  let weapon = create_weapon(world, (-5.0, 15.0), weapon_type)
  weapon
}

///|
/// Update test weapon to follow mouse
/// 更新测试武器跟随鼠标
pub fn update_test_weapon_follow_mouse(
  weapon : Weapon,
  mouse_x : Double,
  mouse_y : Double,
  world_width : Double,
  world_height : Double,
  ppm : Double,
) -> Unit {
  // Convert mouse position to world coordinates
  let world_pos = screen_to_world(
    world_width, world_height, mouse_x, mouse_y, ppm,
  )

  // Update weapon position using forces
  maintain_position(weapon.body, world_pos, kp=500.0, kd=30.0)

  // Calculate direction from weapon to mouse
  let weapon_pos = weapon.body.getCenterPosition()
  let dx = world_pos.0 - weapon_pos.getX()
  let dy = world_pos.1 - weapon_pos.getY()
  let angle = @cmath.atan2(dy, dx)
  weapon.direction = angle

  // Update weapon rotation
  maintain_rotation(weapon.body, angle, kp=100.0, kd=10.0)
}

///|
/// Test weapon firing with keyboard
/// 测试武器发射 (键盘控制)
pub fn test_weapon_fire(
  weapon : Weapon,
  p : @p5js.P5Instance,
  world : @box2d.B2World,
  frame_count : Int,
) -> Unit {
  // Press Space to fire
  if p.keyIsDown(KeySpace) {
    let success = weapon_attack(
      weapon,
      weapon,
      world,
      frame_count,
      Array::new(),
    )
    if success {
      println("Weapon fired! Ammo left: \{weapon.ammo_count}")
    }
  }
}

///|
/// Show weapon info on screen
/// 在屏幕上显示武器信息
pub fn draw_weapon_info(p : &@p5js.P5JS, weapon : Weapon) -> Unit {
  p.push()
  p.fillColorPara(255, Some(255.0), Some(255.0), None)
  p.strokeColorPara(0, Some(0.0), Some(0.0), None)
  p.strokeWeight(1.0)
  p.textSize(16.0, None)
  p.textAlign(Some("left"), Some("top"), None)
  let weapon_name = match weapon.weapon_type {
    Melee => "Melee Weapon (Sword)"
    Gun => "Gun (Pistol)"
    Grenade => "Grenade Launcher"
    Laser => "Laser Gun"
  }
  p.text("\{weapon_name}", 10.0, 10.0, None, None, None)
  let ammo_text = if weapon.ammo_count < 0 {
    "Ammo: Unlimited"
  } else {
    "Ammo: \{weapon.ammo_count}"
  }
  p.text(ammo_text, 10.0, 30.0, None, None, None)
  p.text("Press SPACE to fire", 10.0, 50.0, None, None, None)
  p.text("Press 1-4 to switch weapon", 10.0, 70.0, None, None, None)
  let angle_deg = (weapon.direction * 180.0 / 3.14159).to_int()
  p.text("Direction: \{angle_deg}°", 10.0, 90.0, None, None, None)
  p.pop()
}

///|
/// Draw weapons and bullets
/// 绘制武器和子弹
pub fn draw_weapons_and_bullets(
  p : &@p5js.P5JS,
  width : Double,
  height : Double,
  ppm : Double,
) -> Unit {
  // Draw each weapon
  for weapon in weapon_list.val {
    let pos = weapon.body.getCenterPosition()
    let screen_pos = world_to_screen(width, height, pos.getX(), pos.getY(), ppm)
    p.push()
    // Simple rectangle representation
    p.fillColorPara(100, Some(100.0), Some(100.0), None)
    p.strokeColorPara(50, Some(50.0), Some(50.0), None)
    p.strokeWeight(2.0)

    // Draw simple rectangle for weapon
    let weapon_length = 40.0
    let weapon_width = 10.0
    p.rectMode(Some("center"), None, None, None)
    p.rect(
      screen_pos.0,
      screen_pos.1,
      weapon_length,
      weapon_width,
      None,
      None,
      None,
      None,
      None,
    )
    p.pop()
  }

  // Draw each bullet
  for bullet in bullet_list.val {
    if not(bullet.is_active) {
      continue
    }
    let pos = bullet.body.getCenterPosition()
    let screen_pos = world_to_screen(width, height, pos.getX(), pos.getY(), ppm)
    p.push()
    match bullet.bullet_type {
      Normal => {
        p.fillColorPara(255, Some(255.0), Some(0.0), None)
        p.strokeColorPara(200, Some(150.0), Some(0.0), None)
      }
      Explosive => {
        p.fillColorPara(255, Some(50.0), Some(50.0), None)
        p.strokeColorPara(200, Some(0.0), Some(0.0), None)
      }
      Piercing => {
        p.fillColorPara(200, Some(200.0), Some(255.0), None)
        p.strokeColorPara(150, Some(150.0), Some(200.0), None)
      }
      Special => {
        p.fillColorPara(150, Some(255.0), Some(150.0), None)
        p.strokeColorPara(100, Some(200.0), Some(100.0), None)
      }
    }
    p.strokeWeight(2.0)
    p.circle(screen_pos.0, screen_pos.1, 8.0)
    p.pop()
  }
}
