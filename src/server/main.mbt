fn main {
  @system.App::new(@canvas.CanvasBackend::new())
  .with_canvas_width(VIEWPORT_WIDTH)
  .with_canvas_height(VIEWPORT_HEIGHT)
  .with_image_smooth(false)
  .with_zoom(1)
  .with_fps(60)
  .add_plugin(@plugins.default_plugin)
  // .add_plugin(@plugins.debug_plugin)
  .add_system(game_start, schedule=Startup)
  .run()
}
fn game_start(backend : &@system.Backend, _dt: Double) -> Unit {
  //generate_map(backend)
}