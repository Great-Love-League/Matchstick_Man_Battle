///| Item Pickup System
/// 物品拾取系统

///|
/// Global item list and counter
let item_index : Ref[Int] = Ref::new(0)

///|
let item_list : Ref[Array[Item]] = Ref::new(Array::new())

///|
/// Create a new item
/// 创建新物品
pub fn create_item(
  world : @box2d.B2World,
  position : (Double, Double),
  item_type : ItemType,
) -> Item {
  item_index.val += 1

  // Create item body (small box)
  let box_def = @box2d.b2BoxDef()
  box_def.setExtents(@box2d.b2Vec2(0.3, 0.3))
  box_def.setDensity(0.5)
  box_def.setFriction(0.5)
  let body_def = @box2d.b2BodyDef()
  body_def.setPosition(@box2d.b2Vec2(position.0, position.1))
  body_def.addShape(box_def.getBase())
  body_def.setAllowSleep(true)
  let body = world.createBody(body_def)
  let item = Item::{
    id: item_index.val - 1,
    item_type,
    body,
    is_collected: false,
  }
  item_list.val.push(item)
  item
}

///|
/// Update items and check for pickups
/// 更新物品并检查拾取
pub fn update_items(
  world : @box2d.B2World,
  characters : Array[Character],
) -> Unit {
  let mut to_remove : Array[Int] = Array::new()
  for i = 0; i < item_list.val.length(); i = i + 1 {
    let item = item_list.val[i]
    if item.is_collected {
      to_remove.push(i)
      continue
    }

    // Check collision with characters
    for character in characters {
      if character.control.is_faint {
        continue
      }

      // Check if character is close enough to pick up
      if is_contact(character.torso, item.body) ||
        is_contact(character.left_forearm, item.body) ||
        is_contact(character.right_forearm, item.body) {

        // Try to pick up the item
        if try_pickup_item(character, item) {
          item.is_collected = true
          to_remove.push(i)
          break
        }
      }
    }
  }

  // Remove collected items (reverse order to maintain indices)
  for i = to_remove.length() - 1; i >= 0; i = i - 1 {
    let idx = to_remove[i]
    let item = item_list.val[idx]
    world.destroyBody(item.body)
    item_list.val.remove(idx) |> ignore
  }
}

///|
/// Try to pickup an item
/// 尝试拾取物品
fn try_pickup_item(character : Character, item : Item) -> Bool {
  match item.item_type {
    WeaponPickup(weapon_id) => {
      // Check if inventory is full
      if character.control.weapon_slots.length() >= 2 {
        return false
      }

      // Add weapon to inventory
      character_pickup_weapon(character, weapon_id)
    }
    HealthPack(heal_amount) => {
      // Heal character (don't overheal)
      let new_health = character.control.health + heal_amount
      character.control.health = if new_health > character.control.max_health {
        character.control.max_health
      } else {
        new_health
      }

      // Revive if fainted
      if character.control.is_faint && character.control.health > 0 {
        character.control.is_faint = false
      }
      true
    }
    AmmoBox(ammo_amount) => {
      // Add ammo to current weapon
      if character.control.current_weapon == -1 {
        return false
      }
      let weapon_id = character.control.weapon_slots[character.control.current_weapon]

      // Find weapon in weapon list
      for weapon in weapon_list.val {
        if weapon.id == weapon_id {
          if weapon.ammo_count < 0 {
            // Infinite ammo weapon, can't add more
            return false
          }
          weapon.ammo_count += ammo_amount
          return true
        }
      }
      false
    }
  }
}

///|
/// Spawn weapon drop at position
/// 在指定位置生成武器掉落
pub fn spawn_weapon_drop(
  world : @box2d.B2World,
  position : (Double, Double),
  weapon_type : WeaponType,
) -> Unit {
  // Create weapon
  let weapon = create_weapon(world, position, weapon_type, owner_id=-1)

  // Create pickup item for this weapon
  create_item(world, position, ItemType::WeaponPickup(weapon.id)) |> ignore
}

///|
/// Spawn health pack
/// 生成血包
pub fn spawn_health_pack(
  world : @box2d.B2World,
  position : (Double, Double),
  heal_amount? : Int = 50,
) -> Unit {
  create_item(world, position, ItemType::HealthPack(heal_amount)) |> ignore
}

///|
/// Spawn ammo box
/// 生成弹药箱
pub fn spawn_ammo_box(
  world : @box2d.B2World,
  position : (Double, Double),
  ammo_amount? : Int = 30,
) -> Unit {
  create_item(world, position, ItemType::AmmoBox(ammo_amount)) |> ignore
}

///|
/// Clear all items
/// 清空所有物品
pub fn clear_items(world : @box2d.B2World) -> Unit {
  for item in item_list.val {
    world.destroyBody(item.body)
  }
  item_list.val = Array::new()
  item_index.val = 0
}
