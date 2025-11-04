pub(all) struct SampleAnimation {
  fun : (&@box2d.World, @p5js.P5Instance) -> AnimationState
}

pub fn SampleAnimation::new(fun: (&@box2d.World, @p5js.P5Instance) -> AnimationState) -> Self {
  SampleAnimation::{
    fun: fun
  }
}

pub impl Animation for SampleAnimation with update (self: SampleAnimation, world: &@box2d.World, p5: @p5js.P5Instance) -> AnimationState {
  (self.fun)(world, p5)
}