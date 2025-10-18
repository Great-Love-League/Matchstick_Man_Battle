pub let world :Ref[@box2d.B2World]=Ref::new(create_world())

pub let particle_list:Ref[Array[Particle]]=Ref::new(Array::new())
pub let platform_list:Ref[Array[Platform]]=Ref::new(Array::new())

// pub let body_entity_list : Array[@system.Entity] = Array::new()

pub let sword_body:String=
#|{
#|	"id": "body_1760536199757_75cvmdoa7",
#|	"body_def": {
#|		"type": "dynamic",
#|		"position": [
#|			-6.335077519379845,
#|			16.96435594294783
#|		],
#|		"angle": 0,
#|		"linear_velocity": [
#|			0,
#|			0
#|		],
#|		"angular_velocity": 0,
#|		"linear_damping": 0,
#|		"angular_damping": 0,
#|		"allow_sleep": true,
#|		"awake": true,
#|		"fixed_rotation": false,
#|		"bullet": false,
#|		"gravity_scale": 1
#|	},
#|	"fixtures": [
#|		{
#|			"shape": {
#|				"type": "polygon",
#|				"params": {
#|					"vertices": [
#|						[
#|							-0.8400000000000007,
#|							-2.277499999999998
#|						],
#|						[
#|							-0.6400000000000006,
#|							-2.277499999999998
#|						],
#|						[
#|							-0.5200000000000005,
#|							2.7025000000000006
#|						],
#|						[
#|							-1.0200000000000005,
#|							2.2225
#|						],
#|						[
#|							-0.8600000000000003,
#|							-1.237499999999999
#|						],
#|						[
#|							-1.2600000000000007,
#|							-1.4974999999999987
#|						],
#|						[
#|							-1.1400000000000006,
#|							-1.6574999999999989
#|						],
#|						[
#|							-0.8200000000000003,
#|							-1.4974999999999987
#|						]
#|					]
#|				}
#|			},
#|			"fixture_def": {
#|				"density": 1,
#|				"friction": 0.3,
#|				"restitution": 0.5,
#|				"is_sensor": false,
#|				"filter_category_bits": 1,
#|				"filter_mask_bits": 65535,
#|				"filter_group_index": 0
#|			}
#|		}
#|	],
#|	"visual_properties": {},
#|	"user_data": {}
#|}