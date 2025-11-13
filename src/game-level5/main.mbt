fn main {
  let game = @server.create_game()
  @server.load_map(game, 5) |> ignore
	@server.Gun::create(game,0, Some("src/assets/gun1.png"))
	@server.Gun::create(game,1, Some("src/assets/gun1.png"))

  @server.register_both_weapon_change(game)

  @server.register_mouse_shoot(game, 0)

  @server.register_control(game)
  
  @server.register_auto_aim(game)

  @server.register_hp_show(game)

  @server.register_show_mouse_screen_coords(game)

  game.start_run()

}