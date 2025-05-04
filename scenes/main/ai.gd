extends Node

#node access
@onready var MAIN : Node2D = get_node("/root/Main")
@onready var TURN_CONTROL : Node = get_node("/root/Main/TurnControl")
@onready var MODE : Node = get_node("/root/Main/ModeMachine/Default")
#tilemap access 
@onready var GROUND = get_node("/root/Main/TileMap/Ground")
@onready var OBSTACLES = get_node("/root/Main/TileMap/Obstacles")

var tile_eff_range : float = 0.0

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
	var movement_range : int = u.movement_range
	var effective_range : float = 0.0
	var nccount : int = 0
	
	if(u.weapon == gv.Weapon.ARMED):
		effective_range = u.weapon_obj.rpm
		effective_range = 25.0/effective_range * MAIN.TSD 
	closest_enemies.assign(find_closest_enemies())
	enemies_in_range.assign(find_enemies_in_range(closest_enemies, pow(effective_range,2)))
	
	find_cover(u, movement_range, enemies_in_range)

#move functions
func find_cover(acting_unit : Unit, search_range : int, in_range : Array[Unit]):
	var covers_in_range : Array[Vector2i] = []
	var objects_array = MAIN.check_radius(GROUND.local_to_map(acting_unit),
		 search_range,
		 true)
	
	for ob in objects_array:
		if(ob["collider"] is TileMapLayer):
			covers_in_range
	
	

func find_target():
	pass

func move():
	pass

func find_flank():
	pass

func fall_back():
	pass

#check if unit is behind cover relative to other given (enemy) unit
func is_behind_cover(u_start : Unit, u_target : Unit) -> bool:
	var u_start_pos = GROUND.local_to_map(u_start.global_position)
	var u_target_pos = GROUND.local_to_map(u_target.global_position)
	var objects_on_lof : Array
	objects_on_lof.assign(get_objects_on_lof(u_start_pos, u_target_pos, u_start))
	if(int(get_distance(objects_on_lof[0], u_start_pos)) == 1):
		return true
	return false

func find_closest_enemies() -> Array[Unit]:
	var closest_units : Array[Unit]  
	
	for t in MAIN.player_controlled_teams:
		closest_units.append_array(MAIN.team_arrays[t])
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
	

func get_objects_on_lof(start_pos : Vector2i, end_pos : Vector2i, unit : Unit) -> Array:
	var object_tile_array : Array = []
	var space = MAIN.get_world_2d().direct_space_state
	var excluded_rids : Array[RID] = [unit.get_rid()]
	while(start_pos != end_pos):
		var query = PhysicsRayQueryParameters2D.new()
		var intersected_object : Dictionary
		query.collide_with_areas = true
		query.exclude = excluded_rids
		query.from = MAIN.tm_to_global_position(start_pos)
		query.to = MAIN.tm_to_global_position(end_pos)
		
		intersected_object = space.intersect_ray(query)
		
		if(intersected_object.size() > 0):
			var obj_rid : RID = intersected_object["rid"]
			excluded_rids.append(obj_rid)
			if(intersected_object["collider"] is TileMapLayer): 
				var atl_coords = OBSTACLES.get_cell_atlas_coords(OBSTACLES.get_coords_for_body_rid(obj_rid))
				object_tile_array.append(OBSTACLES.get_coords_for_body_rid(obj_rid))
				#Sprawdza czy pole jest sciana. sciany maja indeksy y od 2 do 3, poki co ic nie ma wiecej
				if(atl_coords.y == 2 || atl_coords.y == 3): break
		else: break
	
	return object_tile_array

func get_distance(start_pos : Vector2i, end_pos : Vector2i) -> float:
	return Vector2i(end_pos - start_pos).length()
