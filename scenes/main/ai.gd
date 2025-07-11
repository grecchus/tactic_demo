extends Node
enum TERRAIN{
	OPEN,
	CRATE,
	WALL1,
	WALL2
}

#node access
@onready var MAIN : Node2D = get_node("/root/Main")
@onready var TURN_CONTROL : Node = get_node("/root/Main/TurnControl")
@onready var MODE : Node = get_node("/root/Main/ModeMachine/Default")
#tilemap access 
@onready var GROUND = get_node("/root/Main/TileMap/Ground")
@onready var OBSTACLES = get_node("/root/Main/TileMap/Obstacles")

const adjacent_tiles : Array = [Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1)]

var controlled_teams : Array[int] = [gv.Team.RED] #Red team is default AI controlled team
var unit_queue : Array[Unit] = []
var current_unit : Unit = null
var closest_enemies : Array[Unit] = []

signal unit_finished_turn

#temporary place for a function assigning enemies

func assign_enemies():
	for team in MAIN.team_arrays.size():
		if(not controlled_teams.has(team)): closest_enemies.append_array(MAIN.team_arrays[team])

func _on_next_turn_signal():
	if(controlled_teams.find(TURN_CONTROL.current_turn) != -1):
		unit_queue.assign(MAIN.team_arrays[TURN_CONTROL.current_turn])
		for u in unit_queue:
			current_unit = u
			if(take_turn()): await current_unit.action_finished
		TURN_CONTROL.next_turn()


func take_turn() -> bool:
	var state : int = 0 #state tells if: unit has enemies in range, is behind cover, has more than 1AP
	var line_of_sight : int = current_unit.movement_range #distance unit "sees" will it's movement range, that is a temporary solution
	var enemies_in_sight : Array[Unit] = []
	var unit_pos : Vector2i = GROUND.local_to_map(current_unit.global_position)
	
	var continous_action : bool = false
	while (current_unit.action_points > 0):
		state = int(current_unit.action_points > 1)
		
#		check if unit is behind cover
		
		closest_enemies.sort_custom(comp_dist)
		enemies_in_sight = get_enemies_in_sight(unit_pos, line_of_sight)
		state = state + 4*int(enemies_in_sight.size() > 0)
		
		current_unit.action_points -= 1
	return continous_action


func get_enemies_in_sight(unit_pos : Vector2i, range : int) -> Array[Unit]:
	var eis_array : Array[Unit] = []
	var objects_in_radius : Array = MAIN.check_radius(unit_pos, range)
	var i : int = 0
	while(i < objects_in_radius.size()):
		if((objects_in_radius[i]["collider"] is Unit) and not MAIN.team_arrays[TURN_CONTROL.current_turn].has(objects_in_radius[i]["collider"])):
			eis_array.append(objects_in_radius[i]["collider"])
		i+=1
	
	return eis_array


func comp_dist(u1 : Unit, u2 : Unit) -> bool:
	var dist_1 : float
	var dist_2 : float
	dist_1 = get_distance(
		current_unit.global_position,
		u1.global_position
		)
	dist_2 = get_distance(
		current_unit.global_position,
		u2.global_position
		)
	return dist_1 < dist_2

func comp_dist_path(u1 : Unit, u2 : Unit) -> bool:
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
	

func get_objects_on_lof(start_pos : Vector2i, end_pos : Vector2i) -> Array:
	var object_tile_array : Array = []
	var space = MAIN.get_world_2d().direct_space_state
	var excluded_rids : Array[RID] = [current_unit.get_rid()]
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
				if(atl_coords.y == TERRAIN.WALL1 || atl_coords.y == TERRAIN.WALL2): break
		else: break
	return object_tile_array

func get_distance(start_pos : Vector2i, end_pos : Vector2i) -> float:
	return Vector2i(end_pos - start_pos).length()
