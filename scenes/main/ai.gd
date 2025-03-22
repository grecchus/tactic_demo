extends Node

#node access
@onready var MAIN : Node2D = get_node("/root/Main")
@onready var TURN_CONTROL : Node = get_node("/root/Main/TurnControl")
@onready var MODE : Node = get_node("/root/Main/ModeMachine/Default")
#tilemap access 
@onready var GROUND = get_node("/root/Main/TileMap/Ground")
@onready var OBSTACLES = get_node("/root/Main/TileMap/Obstacles")

#ray degree difference
var rd : float = 10.0

#Red team is default AI controlled team
var controlled_teams : Array[int] = [gv.Team.RED]
var unit_queue : Array = []
#AI behaviour patterns for given teams
var ai_pattern_dict : Dictionary = {
	gv.Team.RED : "Agressive"
}

func _ready():
	TURN_CONTROL.next_turn_signal.connect(_on_next_turn_signal)



func _on_next_turn_signal():
	if(controlled_teams.find(TURN_CONTROL.current_turn,0) != -1):
		unit_queue = MAIN.team_arrays[TURN_CONTROL.current_turn]
		take_turn()

func take_turn():
	while(not unit_queue.is_empty()):
		var u : Unit = unit_queue[0]
		#while(u.action_points > 0):
			#make_move(u)
		make_move(u)
		unit_queue.remove_at(0)
		
#	On queue empty, end turn
	TURN_CONTROL.next_turn()

#MAKE STATE MACHINE
#TEMPLATE MOVE PATTERN
func make_move(u : Unit):
	print(u)
	var movement_range : int = 6
	var effective_range : float = 0.0
	if(u.weapon == gv.Weapon.ARMED):
		effective_range = u.weapon_obj.effective_range
	find_nearby_enemies(GROUND.local_to_map(u.global_position), effective_range)
	

#move functions
func find_cover():
	pass

func find_target():
	pass

func move():
	pass

func find_flank():
	pass

func fall_back():
	pass

func find_nearby_enemies(unit_position : Vector2i, range : float = 0.0):
	var space = MAIN.get_world_2d().direct_space_state
	var nx = 0
	var ny = 0
	for ray in floori(90.0/rd):
		var query = PhysicsRayQueryParameters2D
		query.from = unit_position
		query.to = Vector2(
			float(unit_position.x) + range * cos(deg_to_rad(0)),
			float(unit_position.y) + range * sin(deg_to_rad(0)),
			)
		print(space.intersect_ray(query))
