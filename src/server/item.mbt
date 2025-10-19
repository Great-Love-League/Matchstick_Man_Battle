///| Item System
/// Manages item creation, pickups, and effects

pub enum ItemType {
  HealthPack
  AmmoPack
  WeaponUpgrade
  SpeedBoost
}

pub struct Item {
  id : Int
  body : @box2d.B2Body
  item_type : ItemType
  value : Int
  mut is_active : Bool
  position : (Double, Double)
}

fn Game::create_item(
  self : Self,
  position : (Double, Double),
  item_type : ItemType,
  value? : Int = 20
) -> Item {
  let box_def = @box2d.b2BoxDef()
  box_def.setExtents(@box2d.b2Vec2(0.3, 0.3))
  box_def.setDensity(0.0)
  box_def.setGroupIndex(-3)
  
  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(box_def.getBase())
  body_def.setAllowSleep(false)
  
  let body = self.world.createBody(body_def)
  
  let item_id = self.item_list.length()
  let item = Item::{
    id: item_id,
    body,
    item_type,
    value,
    is_active: true,
    position,
  }
  
  self.item_list.push(item)
  item
}

fn Game::check_item_pickup(self : Self, item : Item) -> Bool {
  for particle in self.particle_list {
    if particle.control.faint_state {
      continue
    }
    
    if self.is_contact(particle.torso, item.body) ||
       self.is_contact(particle.head, item.body) {
      self.apply_item_effect(particle, item)
      return true
    }
  }
  false
}

fn Game::apply_item_effect(self : Self, particle : Particle, item : Item) -> Unit {
  match item.item_type {
    HealthPack => {
      particle.control.health += item.value
      if particle.control.health > 100 {
        particle.control.health = 100
      }
      println("Player \{particle.index} picked up HealthPack! Health: \{particle.control.health}")
    }
    AmmoPack => {
      println("Player \{particle.index} picked up AmmoPack! (TODO)")
    }
    WeaponUpgrade => {
      println("Player \{particle.index} picked up WeaponUpgrade! (TODO)")
    }
    SpeedBoost => {
      println("Player \{particle.index} picked up SpeedBoost! (TODO)")
    }
  }
}

fn Game::update_all_items(self : Self) -> Unit {
  for item in self.item_list {
    if item.is_active {
      if self.check_item_pickup(item) {
        item.is_active = false
      }
    }
  }
}

fn Game::cleanup_items(self : Self) -> Unit {
  let active_items : Array[Item] = Array::new()
  
  for item in self.item_list {
    if item.is_active {
      active_items.push(item)
    } else {
      self.world.destroyBody(item.body)
    }
  }
  
  self.item_list = active_items
}

fn Game::spawn_health_pack(self : Self, position : (Double, Double)) -> Unit {
  self.create_item(position, HealthPack, value=20) |> ignore
}