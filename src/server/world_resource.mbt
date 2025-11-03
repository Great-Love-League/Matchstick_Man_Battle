
fn load_map(game:Game, level : Int) -> Bool {
  game.create_particle((-10.0, 12.0)) |> ignore
  game.create_particle((-5.0, 12.0)) |> ignore
	match level {
		1 => {
			create_platform(game, (-24.5, 25), (1, 25), angle = 0.0)|> ignore;
			create_platform(game, (24.5, 25), (1, 25), angle = 0.0)|> ignore;
			create_platform(game, (0, 49.5), (23.6, 1), angle = 0.0)|> ignore;
			create_platform(game, (0, 0.5), (23.6, 1), angle = 0.0)|> ignore;
			create_movable_platform(game, (5,1), (10-25,10), (40-25,40), 2 ,(10-25,10))|> ignore;
			create_movable_platform(game, (5,1), (15,10), (-15,40), 2, (0,25))|> ignore;
			create_platform(game, (0, 10), (5, 1) , angle = 1.57)|> ignore;
			create_platform(game, (0, 40), (5, 1) , angle = 1.57)|> ignore;
			create_rotatable_platform(game, (-17, 25), (6, 1) , 10)|> ignore;
			create_rotatable_platform(game, (17, 25), (6, 1) ,20)|> ignore;
			return true
		}
		2 => {
			create_platform(game, (-24.5, 25), (1, 25), angle = 0.0)|> ignore;
			create_platform(game, (24.5, 25), (1, 25), angle = 0.0)|> ignore;
			create_platform(game, (0, 49.5), (23.6, 1), angle = 0.0)|> ignore;
			create_platform(game, (0, 0.5), (23.6, 1), angle = 0.0)|> ignore;
			create_movable_platform(game, (6,1), (-16,10), (16,10), 4, (-16,10))|> ignore;
			create_movable_platform(game, (6,1), (-16,20), (16,20), 4, (-8,20))|> ignore;
			create_movable_platform(game, (6,1), (-16,30), (16,30), 4, (0,30))|> ignore;
			create_movable_platform(game, (6,1), (-16,40), (16,40), 4, (8,40))|> ignore;
			create_movable_platform(game, (6,1), (16,5), (-16,5), 4, (16,5))|> ignore;
			create_movable_platform(game, (6,1), (16,15), (-16,15), 4, (8,15))|> ignore;
			create_movable_platform(game, (6,1), (16,25), (-16,25), 4, (0,25))|> ignore;
			create_movable_platform(game, (6,1), (16,35), (-16,35), 4, (-8,35))|> ignore;
			return true
		}
		3 => {
			create_platform(game, (0, 0.5), (10, 1), angle = 0.0)|> ignore;
			create_rotatable_platform(game, (-20, 8), (8, 0.8), 2, initial_angle=0.3) |> ignore;
			create_rotatable_platform(game, (15, 10), (8, 0.8), 2, initial_angle=1.2) |> ignore;
			create_rotatable_platform(game, (-5, 16), (8, 0.8), 2, initial_angle=2.8) |> ignore;
			create_rotatable_platform(game, (22, 19), (8, 0.8), -2, initial_angle=-0.9) |> ignore;
			create_rotatable_platform(game, (-18, 28), (8, 0.8), -2, initial_angle=0.7) |> ignore;
			create_rotatable_platform(game, (8, 33), (8, 0.8), 2, initial_angle=-1.5) |> ignore;
			create_rotatable_platform(game, (-10, 41), (8, 0.8), 2, initial_angle=2.4) |> ignore;
			create_rotatable_platform(game, (19, 45), (8, 0.8), 2, initial_angle=-2.1) |> ignore;
			return true
		}
		4 => {
			
			create_platform(game, (-24.5, 25), (1, 25), angle = 0.0)|> ignore;
			create_platform(game, (24.5, 25), (1, 25), angle = 0.0)|> ignore;
			create_platform(game, (0, 49.5), (23.6, 1), angle = 0.0)|> ignore;
			create_platform(game, (0, 0.5), (23.6, 1), angle = 0.0)|> ignore;
			
			
			create_rotatable_platform(game, (0, 25), (20, 0.8), 1, initial_angle=0) |> ignore;
			
			return true
		}
		_ => {
			return false
		}
	}
}

pub let level1:String=
#|{
#|  "world_settings": {
#|    "gravity": [
#|      0,
#|      -9.8
#|    ],
#|    "allow_sleeping": true,
#|    "auto_clear_forces": true
#|  },
#|  "bodies": [
#|    {
#|      "id": "body_1760796354261_8xkqzmqy7",
#|      "body_def": {
#|        "type": "static",
#|        "position": [
#|          -15.899999999999999,
#|          3.649999999999997
#|        ],
#|        "angle": 0,
#|        "linear_velocity": [
#|          0,
#|          0
#|        ],
#|        "angular_velocity": 0,
#|        "linear_damping": 0,
#|        "angular_damping": 0,
#|        "allow_sleep": true,
#|        "awake": true,
#|        "fixed_rotation": false,
#|        "bullet": false,
#|        "gravity_scale": 1
#|      },
#|      "fixtures": [
#|        {
#|          "shape": {
#|            "type": "box",
#|            "params": {
#|              "width": 10,
#|              "height": 1
#|            }
#|          },
#|          "fixture_def": {
#|            "density": 1,
#|            "friction": 0.3,
#|            "restitution": 0.5,
#|            "is_sensor": false,
#|            "filter_category_bits": 1,
#|            "filter_mask_bits": 65535,
#|            "filter_group_index": 0
#|          }
#|        }
#|      ],
#|      "visual_properties": {},
#|      "user_data": {}
#|    },
#|    {
#|      "id": "body_1760796380543_r63xejldw",
#|      "body_def": {
#|        "type": "static",
#|        "position": [
#|          -5.774999999999998,
#|          8.9
#|        ],
#|        "angle": 0,
#|        "linear_velocity": [
#|          0,
#|          0
#|        ],
#|        "angular_velocity": 0,
#|        "linear_damping": 0,
#|        "angular_damping": 0,
#|        "allow_sleep": true,
#|        "awake": true,
#|        "fixed_rotation": false,
#|        "bullet": false,
#|        "gravity_scale": 1
#|      },
#|      "fixtures": [
#|        {
#|          "shape": {
#|            "type": "box",
#|            "params": {
#|              "width": 10,
#|              "height": 1
#|            }
#|          },
#|          "fixture_def": {
#|            "density": 1,
#|            "friction": 0.3,
#|            "restitution": 0.5,
#|            "is_sensor": false,
#|            "filter_category_bits": 1,
#|            "filter_mask_bits": 65535,
#|            "filter_group_index": 0
#|          }
#|        }
#|      ],
#|      "visual_properties": {},
#|      "user_data": {}
#|    },
#|    {
#|      "id": "body_1760796448787_nhjivvkra",
#|      "body_def": {
#|        "type": "static",
#|        "position": [
#|          7.85,
#|          19.275
#|        ],
#|        "angle": 0,
#|        "linear_velocity": [
#|          0,
#|          0
#|        ],
#|        "angular_velocity": 0,
#|        "linear_damping": 0,
#|        "angular_damping": 0,
#|        "allow_sleep": true,
#|        "awake": true,
#|        "fixed_rotation": false,
#|        "bullet": false,
#|        "gravity_scale": 1
#|      },
#|      "fixtures": [
#|        {
#|          "shape": {
#|            "type": "box",
#|            "params": {
#|              "width": 1,
#|              "height": 19.45
#|            }
#|          },
#|          "fixture_def": {
#|            "density": 1,
#|            "friction": 0.3,
#|            "restitution": 0.5,
#|            "is_sensor": false,
#|            "filter_category_bits": 1,
#|            "filter_mask_bits": 65535,
#|            "filter_group_index": 0
#|          }
#|        }
#|      ],
#|      "visual_properties": {},
#|      "user_data": {}
#|    },
#|    {
#|      "id": "body_1760796499813_fcoevvg6m",
#|      "body_def": {
#|        "type": "static",
#|        "position": [
#|          16.0875,
#|          10.737499999999999
#|        ],
#|        "angle": 0,
#|        "linear_velocity": [
#|          0,
#|          0
#|        ],
#|        "angular_velocity": 0,
#|        "linear_damping": 0,
#|        "angular_damping": 0,
#|        "allow_sleep": true,
#|        "awake": true,
#|        "fixed_rotation": false,
#|        "bullet": false,
#|        "gravity_scale": 1
#|      },
#|      "fixtures": [
#|        {
#|          "shape": {
#|            "type": "polygon",
#|            "params": {
#|              "vertices": [
#|                [
#|                  4.112500000000001,
#|                  4.862500000000001
#|                ],
#|                [
#|                  -5.0375,
#|                  -3.8375000000000004
#|                ],
#|                [
#|                  -4.1875,
#|                  -4.887499999999999
#|                ],
#|                [
#|                  5.112500000000001,
#|                  3.8625000000000007
#|                ]
#|              ]
#|            }
#|          },
#|          "fixture_def": {
#|            "density": 1,
#|            "friction": 0.3,
#|            "restitution": 0.5,
#|            "is_sensor": false,
#|            "filter_category_bits": 1,
#|            "filter_mask_bits": 65535,
#|            "filter_group_index": 0
#|          }
#|        }
#|      ],
#|      "visual_properties": {},
#|      "user_data": {}
#|    }
#|  ],
#|  "joints": []
#|}