//Player Entity - Legacy Article types (deprecated, use Character instead)

///|
pub struct ArticleControl {
  mut left : Bool
  mut right : Bool
}

///|
pub struct Article {
  mut id : Int
  mut body_list : Array[@box2d.B2Body]
}

// Note: ParticleControl, Particle, and Platform are defined in particle.mbt and platform.mbt
// This file is kept for ArticleControl and Article only
