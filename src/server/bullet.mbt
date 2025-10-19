///| Bullet System
/// Manages bullet creation, updates, and destruction

pub struct Bullet {
  id : Int
  owner_id : Int
  body : @box2d.B2Body
  damage : Int
  max_distance : Double
  mut traveled_distance : Double
  start_position : (Double, Double)
  mut is_active : Bool
}

fn Game::create_bullet(
  self : Self,
  position : (Double, Double),
  velocity : (Double, Double),
  owner_id : Int,
  damage? : Int = 10,
  max_distance? : Double = 50.0,
) -> Bullet {
  let circle_def = @box2d.b2CircleDef()
  circle_def.setRadius(0.1)
  circle_def.setDensity(0.5)
  circle_def.setFriction(0.1)
  circle_def.setGroupIndex(-2)
  circle_def.setLocalPosition(@box2d.b2Vec2(0.0, 0.0))
  
  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(circle_def.getBase())
  body_def.setAllowSleep(false)
  
  let body = self.world.createBody(body_def)
  body.setLinearVelocity(@box2d.b2Vec2(velocity.0, velocity.1))
  
  let bullet_id = self.bullet_list.length()
  let bullet = Bullet::{
    id: bullet_id,
    owner_id,
    body,
    damage,
    max_distance,
    traveled_distance: 0.0,
    start_position: position,
    is_active: true,
  }
  
  self.bullet_list.push(bullet)
  bullet
}

fn Game::update_bullet(self : Self, bullet : Bullet) -> Unit {
  if not(bullet.is_active) {
    return
  }
  
  let current_pos = bullet.body.getCenterPosition()
  let dx = current_pos.getX() - bullet.start_position.0
  let dy = current_pos.getY() - bullet.start_position.1
  bullet.traveled_distance = @cmath.sqrt(dx * dx + dy * dy)
  
  if bullet.traveled_distance >= bullet.max_distance {
    bullet.is_active = false
    return
  }
  
  let x = current_pos.getX()
  let y = current_pos.getY()
  let half_width = VIEWPORT_WIDTH / PPM / 2.0
  let half_height = VIEWPORT_HEIGHT / PPM / 2.0
  
  if x < -half_width || x > half_width || y < 0.0 || y > half_height * 2.0 {
    bullet.is_active = false
    return
  }
  
  self.check_bullet_collision(bullet)
}

fn Game::check_bullet_collision(self : Self, bullet : Bullet) -> Unit {
  for particle in self.particle_list {
    if particle.index == bullet.owner_id {
      continue
    }
    
    if particle.control.faint_state {
      continue
    }
    
    let mut hit = false
    let mut damage = 0
    
    if self.is_contact(particle.head, bullet.body) {
      damage = bullet.damage * 2
      hit = true
    } else if self.is_contact(particle.torso, bullet.body) {
      damage = bullet.damage
      hit = true
    } else if self.is_contact(particle.left_thigh, bullet.body) ||
              self.is_contact(particle.right_thigh, bullet.body) {
      damage = bullet.damage / 2
      hit = true
    } else if self.is_contact(particle.left_shank, bullet.body) ||
              self.is_contact(particle.right_shank, bullet.body) {
      damage = bullet.damage / 3
      hit = true
    } else if self.is_contact(particle.left_arm, bullet.body) ||
              self.is_contact(particle.right_arm, bullet.body) {
      damage = bullet.damage / 2
      hit = true
    } else if self.is_contact(particle.left_forearm, bullet.body) ||
              self.is_contact(particle.right_forearm, bullet.body) {
      damage = bullet.damage / 3
      hit = true
    }
    
    if hit {
      particle.control.health -= damage
      if particle.control.health <= 0 {
        particle.control.faint_state = true
      }
      bullet.is_active = false
      break
    }
  }
}

fn Game::update_all_bullets(self : Self) -> Unit {
  for bullet in self.bullet_list {
    if bullet.is_active {
      self.update_bullet(bullet)
    }
  }
}

fn Game::cleanup_bullets(self : Self) -> Unit {
  let active_bullets : Array[Bullet] = Array::new()
  
  for bullet in self.bullet_list {
    if bullet.is_active {
      active_bullets.push(bullet)
    } else {
      self.world.destroyBody(bullet.body)
    }
  }
  
  self.bullet_list = active_bullets
}

fn Game::shoot_bullet(self : Self, player_index : Int, direction : Double) -> Unit {
  if player_index >= self.particle_list.length() {
    return
  }
  
  let particle = self.particle_list[player_index]
  let hand_pos = particle.right_forearm.getCenterPosition()
  let position = (hand_pos.getX(), hand_pos.getY())
  
  let speed = 20.0
  let velocity = (direction * speed, 0.0)
  
  self.create_bullet(position, velocity, player_index, damage=10, max_distance=50.0) |> ignore
}