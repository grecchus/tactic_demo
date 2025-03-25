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
var current_unit : Unit = null


func _on_next_turn_signal():
	if(controlled_teams.find(TURN_CONTROL.current_turn,0) != -1):
		unit_queue.assign(MAIN.team_arrays[TURN_CONTROL.current_turn])
		take_turn()

func take_turn():
	while(not unit_queue.is_empty()):
		current_unit = unit_queue[0]
		make_move(current_unit)
		unit_queue.remove_at(0)
		
#	On queue empty, end turn
	TURN_CONTROL.next_turn()

#MAKE STATE MACHINE
#TEMPLATE MOVE PATTERN
func make_move(u : Unit):
	var closest_enemies : Array[Unit] = []
	var enemies_in_range : Array[Unit] = []
	var movement_range : int = 6
	var effective_range : float = 0.0
	if(u.weapon == gv.Weapon.ARMED):
		effective_range = u.weapon_obj.effective_range
	closest_enemies.assign(find_closest_enemies())
	enemies_in_range.assign(find_enemies_in_range(closest_enemies, pow(effective_range,2)))
	print(enemies_in_range)


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


func find_closest_enemies() -> Array[Unit]:
	var closest_units : Array[Unit]  
	
	closest_units.assign(MAIN.team_arrays[TURN_CONTROL.current_turn])
	closest_units.sort_custom(comp_dist)
	return closest_units

func find_enemies_in_range(sorted_unit_array : Array[Unit], range_sqrd: float) -> Array[Unit]:
	var in_range : Array[Unit] = []
	var i = 0
	
	if(sorted_unit_array.size() == 0):
		return []
	while((sorted_unit_array[i].global_position - current_unit.global_position).length_squared() <= range_sqrd):
		in_range.push_back(sorted_unit_array[i])
		i += 1
		if(i == sorted_unit_array.size()): break
	return in_range

func comp_dist(u1 : Unit, u2 : Unit) -> bool:
	var id_path_1
	var id_path_2
	id_path_1 = MAIN.astar_grid.get_id_path(
		GROUND.local_to_map(current_unit.global_position),
		GROUND.local_to_map(u1.global_position)
		)
	id_path_2 = MAIN.astar_grid.get_id_path(
		GROUND.local_to_map(current_unit.global_position),
		GROUND.local_to_map(u2.global_position)
		)
	return id_path_1.size() < id_path_2.size()
	
