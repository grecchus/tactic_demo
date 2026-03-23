extends Node
<<<<<<< Updated upstream
=======
enum TERRAIN{
	OPEN,
	CRATE,
	WALL1,
	WALL2
}
enum STATE{
	NoEnemy_NoCover_HasMoreAP,
	NoEnemy_NoCover_LastAP,
	NoEnemy_Covered_HasMoreAP,
	NoEnemy_Covered_LastAP,
	EnemyInSight_NoCover_HasMoreAP,
	EnemyInSight_NoCover_LastAP,
	EnemyInSight_Covered_HasMoreAP,
	EnemyInSight_Covered_LastAP
}
enum MAX_AP_COST{
	NO_RESTRAINT = -1,
	ONE_AP = 1,
	TWO_AP,
	THREE_AP
}
>>>>>>> Stashed changes

#node access
@onready var MAIN : Node2D = get_node("/root/Main")
@onready var TURN_CONTROL : Node = get_node("/root/Main/TurnControl")
@onready var MODE : Node = get_node("/root/Main/ModeMachine/Default")
#tilemap access 
@onready var GROUND = get_node("/root/Main/TileMap/Ground")
@onready var OBSTACLES = get_node("/root/Main/TileMap/Obstacles")

const NUMBER_OF_POSSIBLE_STATES : int = 8
const adjacent_tiles : Array = [Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1)]
<<<<<<< Updated upstream
var tile_eff_range : float = 0.0

=======
var cover_alignment_vector : Vector2i = Vector2i(1, 0) #This will be changed. That vector will be set according to
#coordinates of points: spawn point-map center
>>>>>>> Stashed changes

var controlled_teams : Array[int] = [gv.Team.RED] #Red team is default AI controlled team
var unit_queue : Array = []
#AI behaviour patterns for given teams
var ai_pattern_dict : Dictionary = {
	gv.Team.RED : "Defensive"
}
var current_unit : Unit = null
<<<<<<< Updated upstream
var ucount : int = 0 #Global variable used in determining cover safety
var closest_enemies : Array[Unit] = []
=======
var uc_min : int = 0 
var enemies_array : Array[Unit] = []
var line_of_sight : int #distance unit "sees" will it's movement range, that is a temporary solution
var enemies_in_sight : Array[Unit] = []
var unit_pos := Vector2i.ZERO
var state : int = 0 #state tells if: unit has enemies in range, is behind cover, has more than 1AP
>>>>>>> Stashed changes

signal unit_finished_movement

<<<<<<< Updated upstream
=======
func assign_enemies():
	for team in MAIN.team_arrays.size():
		if(not controlled_teams.has(team)): enemies_array.append_array(MAIN.team_arrays[team])
>>>>>>> Stashed changes

func _on_next_turn_signal():
	if(controlled_teams.find(TURN_CONTROL.current_turn) != -1):
		unit_queue.assign(MAIN.team_arrays[TURN_CONTROL.current_turn])
<<<<<<< Updated upstream
		take_turn()

func take_turn():
	print("turn started")
	var stuck_units : Array = []
	var iterations_stuck : int = 0
	while(not unit_queue.is_empty()):
		current_unit = unit_queue[0]
		make_move(current_unit)
		if(current_unit.id_path.is_empty()):
			unit_queue.append(current_unit)
			if(stuck_units.find(current_unit) == -1):
				stuck_units.append(current_unit)
		else:
			stuck_units.erase(current_unit)
			await current_unit.action_finished
		unit_queue.remove_at(0)
		if(stuck_units.size() == unit_queue.size()): #simple deadlock preventing mechanism
			if(iterations_stuck > stuck_units.size()): break
			iterations_stuck += 1
		else: iterations_stuck = 0
	print("turn ended")
	TURN_CONTROL.next_turn()


func make_move(u : Unit):
	var unit_pos : Vector2i = GROUND.local_to_map(u.global_position)
	var enemies_in_range : Array[Unit] = []
	var movement_range : int = u.movement_range
	var effective_range : float = 5.0
	ucount = 0
#checking state unit is in at every while iteration
#state = R*4 + C*2 + A*1
#R - has enemy in it's weapon range, that
#C - is behind cover
#A - unit has more than 1 action point to spend
	#while(u.action_points > 0):
	var state : int = 0
	state += int(u.action_points == 1)
	
	if(u.weapon == gv.Weapon.ARMED):
		effective_range = u.weapon_obj.rpm
	effective_range = effective_range * MAIN.TSD
	closest_enemies.assign(find_closest_enemies())
	enemies_in_range.assign(find_enemies_in_range(closest_enemies, effective_range))
	state += int(enemies_in_range.size() > 0) * 2
	if(not enemies_in_range.is_empty()): gv.cprint(str(enemies_in_range) + " " + str(unit_pos))
=======
		for u in unit_queue:
			current_unit = u
			await take_turn()
		TURN_CONTROL.next_turn()


func take_turn() -> bool:
	var continous_action : bool = false
	var prev_ap : int = current_unit.action_points
	line_of_sight = current_unit.movement_range #distance unit "sees" will it's movement range, that is a temporary solution
	enemies_in_sight = []
	
	if(current_unit.unit_ai.size() < NUMBER_OF_POSSIBLE_STATES):
		print("Unit has undefined behavior for " + str(NUMBER_OF_POSSIBLE_STATES - current_unit.unit_ai.size()) + " states.")
		return false
	
	while (current_unit.action_points > 0):
		state = int(current_unit.action_points == 1)
		unit_pos = GROUND.local_to_map(current_unit.global_position)
		
		enemies_in_sight = get_enemies_in_sight(unit_pos, line_of_sight)
		
		
		if(enemies_in_sight.size() > 0):
			for enemy in enemies_in_sight:
				if(not is_behind_cover(unit_pos,
					GROUND.local_to_map(enemy.global_position))): uc_min += 1
			state = state + 2*int(uc_min == 0)
		else:
			var temp = MAIN.check_point_for_collision(unit_pos - cover_alignment_vector)
			for ob in temp:
				if(ob["collider"] is TileMapLayer):
					state = state + 2
					break
		
		state = state + 4*int(enemies_in_sight.size() > 0)
		
		for f_name in current_unit.unit_ai[state]:
			var action_function = Callable(self, f_name)
			
			if(action_function.call()): 
				await current_unit.action_finished
				continous_action = true
		
		if(prev_ap == current_unit.action_points): break #add deadlock handling !!! CRITICAL !!!
		prev_ap = current_unit.action_points
	return continous_action

#################################unit action functions###########################################
#Every method has to return a boolean value. If returned value means true, then the action that unit is ordered to perform is continous.
#In that case, we need to wait until it is finished before taking another action. Otherwise action is instant.
func wait() -> bool:
	current_unit.action_points -= 1
	return false

#For now, units will advance towards center of the map
func move_forward() -> bool:
	var new_pos = unit_pos
	if(abs(unit_pos.x - MAIN.mapCenter.x) > current_unit.movement_range and unit_pos.x > MAIN.mapCenter.x):
		new_pos = MAIN.mapCenter
	elif(state != STATE.NoEnemy_Covered_HasMoreAP): return find_cover()
	else: return wait()
	
	return new_position_found(new_pos, MAX_AP_COST.ONE_AP)


func find_cover() -> bool:
	var covers_in_range : Array[Vector2i] = []
	var objects_array : Array = []
	var found_cover : Vector2i = unit_pos        
		
	objects_array = MAIN.check_radius(GROUND.local_to_map(current_unit.global_position),
		 line_of_sight + 1)
	for ob in objects_array:
		if(ob["collider"] is TileMapLayer):
			covers_in_range.append(ob["collider"].get_coords_for_body_rid(ob["rid"]))
				
	if(state >= STATE.EnemyInSight_NoCover_HasMoreAP):
		for cover in covers_in_range:
			var cover_side_pos = find_safest_side(cover, line_of_sight)
			if(cover_side_pos != unit_pos):
				found_cover = cover_side_pos
	else: 
		if(current_unit.calculate_cost(MAIN.mapSize - MAIN.spawnSize) <= 1): return move_forward()
		covers_in_range.sort_custom(comp_dist_path)
		for cover in covers_in_range:
			if(current_unit.calculate_cost(cover + cover_alignment_vector) == 1): # ==1 means unit can reach given tile using 1 AP
				found_cover = cover + cover_alignment_vector
				break
	
	return new_position_found(found_cover)

func find_target() -> bool:
	var best_target : Unit
	var target_pos : Vector2i
	var max_hit_chance : float = 0.0
	var unit_pos = GROUND.local_to_map(current_unit.global_position)
	if(enemies_in_sight.is_empty()): return wait()
	
	for enemy in enemies_in_sight:
		var enemy_pos = GROUND.local_to_map(enemy.global_position)
		var new_chance : float = 0.0
		if(enemy.weapon_obj is Firearm): new_chance = enemy.weapon_obj.get_chance(unit_pos, enemy_pos)
		if (new_chance > max_hit_chance):
			max_hit_chance = new_chance
			best_target = enemy
	
	if(best_target == null): return wait()
	target_pos = GROUND.local_to_map(best_target.global_position)
	current_unit.current_action = "Use"
	current_unit.action(target_pos)
	return false

#################################cover functions###########################################
func find_safest_side(cover_pos : Vector2i, range : int) -> Vector2i:
	var best_side : Vector2i = GROUND.local_to_map(current_unit.global_position)
	var ucount : int = 0
	var local_eis  : Array = get_enemies_in_sight(cover_pos, range+1)
	
	for side in adjacent_tiles:
		ucount = 0
		if(MAIN.check_point_for_collision(cover_pos + side)): continue
		if(current_unit.calculate_cost(cover_pos + side) < 2):
			for enemy in local_eis:
				if(not is_behind_cover(cover_pos, GROUND.local_to_map(enemy.global_position))): ucount += 1
			if(uc_min > ucount):
				uc_min = ucount
				best_side = cover_pos + side
	return best_side

#check if unit is behind cover relative to other given (enemy) unit
func is_behind_cover(u_start : Vector2i, u_target : Vector2i) -> bool:
	var objects_on_lof : Array
	objects_on_lof.assign(get_objects_on_lof(u_start, u_target))
	if(objects_on_lof.is_empty()): return false
	if(int(get_distance(objects_on_lof.front(), u_start)) == 1):
		return true
	return false
	
#################################utility functions###########################################
func get_enemies_in_sight(coords : Vector2i, range : int) -> Array[Unit]:
	var eis_array : Array[Unit] = [] #eis - enemies in sight
	var objects_in_radius : Array = MAIN.check_radius(coords, range)
	for i in objects_in_radius.size():
		if((objects_in_radius[i]["collider"] is Unit) and enemies_array.has(objects_in_radius[i]["collider"])):
			eis_array.append(objects_in_radius[i]["collider"])
		i+=1
>>>>>>> Stashed changes
	
	for enemy in enemies_in_range:
		if(not is_behind_cover(unit_pos,
			GROUND.local_to_map(enemy.global_position))): ucount += 1
	state += int(ucount > 0) * 4
	
	if(find_cover(u, movement_range, enemies_in_range, effective_range)):
		await u.action_finished
		#match state:
			#0:
				#pass
			#1: 
				#find_cover(u, movement_range, enemies_in_range, effective_range)
			#2:
				#pass
			#3:
				#pass
			#4:
				#pass
			#5:
				#find_cover(u, movement_range, enemies_in_range, effective_range)
			#6:
				#pass
			#7:
				#pass
	emit_signal("unit_finished_movement")


<<<<<<< Updated upstream
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% move functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#find cover facing opposite to spawnpoint, used when there are no enemies in range
func find_cover_ots(acting_unit : Unit, search_range : int) -> bool:
	var covers_in_range : Array[Vector2i] = []
	var objects_array
	return false
#	use adjecent_tiles
	objects_array = MAIN.check_radius(GROUND.local_to_map(acting_unit.global_position),
		 search_range,
		 true)
	for sub_arr in objects_array:
		for ob in sub_arr:
			if(ob["collider"] is TileMapLayer):
				covers_in_range.append(ob["collider"].get_coords_for_body_rid(ob["rid"]))
#!!!!!!!!!!TO DO!!!!!!!!!!!


#Funkcja zwraca NAJGORSZĄ z opcji!!!!!!!!!!
#find cover when there are enemies in range
func find_cover(acting_unit : Unit, search_range : int, in_range : Array[Unit], weapon_range : float) -> bool:
	var unit_pos : Vector2i = GROUND.local_to_map(acting_unit.global_position)
	var covers_in_range : Array[Vector2i] = []
	var objects_array
	var uc_min : int = 0
	var found_cover : Vector2i = unit_pos
	
	for enemy in in_range:
		if(not is_behind_cover(unit_pos,
			GROUND.local_to_map(enemy.global_position))):
				uc_min += 1
				print(str(unit_pos) + str(uc_min) + str(acting_unit.name))
	#if(uc_min == 0): return false                      
		
	objects_array = MAIN.check_radius(GROUND.local_to_map(acting_unit.global_position),
		 search_range,
		 true)
	for sub_arr in objects_array:
		for ob in sub_arr:
			if(ob["collider"] is TileMapLayer):
				covers_in_range.append(ob["collider"].get_coords_for_body_rid(ob["rid"]))
				
	for cover in covers_in_range:
		var cover_side_pos = cover_safety(cover, acting_unit, search_range, weapon_range)
		print(str(cover_side_pos) + " " + str(ucount))
		if(ucount == 0):
			found_cover = cover_side_pos
			break
		elif(uc_min > ucount):
			uc_min = ucount
			found_cover = cover_side_pos
	
	acting_unit.current_action = "Move"
	acting_unit.action(found_cover)
	if(acting_unit.id_path.is_empty()):
		return false
	return true

#Function checking cover for safety. Returns safest side of the cover and it's unit count with ucount global variable.
func cover_safety(cover_pos : Vector2i, u : Unit, unit_range : int, weapon_range : float) -> Vector2i:
	var uc_min : int = closest_enemies.size()
	var best_side : Vector2i = cover_pos
	var movement_cost : int = 0
	var range_sqrd = pow(weapon_range,2)
	
	for i in adjacent_tiles:
		if(MAIN.check_point_for_collision(cover_pos + i)): continue
		ucount = 0
		if(u.find_path(cover_pos + i) < 2):
			for enemy in closest_enemies:
				if((enemy.global_position - u.global_position).length_squared() <= range_sqrd):
					if(not is_behind_cover(cover_pos, GROUND.local_to_map(enemy.global_position))): ucount += 1
			if(uc_min > ucount):
				uc_min = ucount
				best_side = cover_pos + i
	ucount = uc_min
	return best_side

func find_target():
	pass

func move():
	pass

func fall_back():
	pass

#check if unit is behind cover relative to other given (enemy) unit
func is_behind_cover(u_start : Vector2i, u_target : Vector2i) -> bool:
	var objects_on_lof : Array
	objects_on_lof.assign(get_objects_on_lof(u_start, u_target))
	if(objects_on_lof.is_empty()): return false
	if(int(get_distance(objects_on_lof.front(), u_start)) == 1):
		return true
	return false

func find_closest_enemies() -> Array[Unit]:
	var closest_units : Array[Unit]  
	
	for t in MAIN.player_controlled_teams:
		closest_units.append_array(MAIN.team_arrays[t])
	closest_units.sort_custom(comp_dist)
	return closest_units
#tutaj chyba jest błąd!!!, jeżeli to nie zadziała, przepisz wszystko
func find_enemies_in_range(sorted_unit_array : Array[Unit], range: float) -> Array[Unit]:
	var in_range : Array[Unit] = []
	var i = 0
	var range_sqrd = pow(range,2)
	
	if(sorted_unit_array.size() == 0):
		return []
	while((sorted_unit_array[i].global_position - current_unit.global_position).length_squared() <= range_sqrd):
		in_range.push_back(sorted_unit_array[i])
		i += 1
		if(i == sorted_unit_array.size()): break
	return in_range

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
=======
>>>>>>> Stashed changes

func comp_dist_path(p1 : Vector2i, p2 : Vector2i) -> bool:
	var id_path_1
	var id_path_2
	id_path_1 = MAIN.astar_grid.get_id_path(
		GROUND.local_to_map(current_unit.global_position),
		p1
		)
	id_path_2 = MAIN.astar_grid.get_id_path(
		GROUND.local_to_map(current_unit.global_position),
		p2
		)
	return id_path_1.size() < id_path_2.size()
	

func get_objects_on_lof(start_pos : Vector2i, end_pos : Vector2i) -> Array:
	var object_tile_array : Array = []
	var space = MAIN.get_world_2d().direct_space_state
	var excluded_rids : Array[RID] = [current_unit.get_rid()] #USE OF current_unit!!!
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
				#Sprawdza czy pole jest sciana. sciany maja indeksy y od 2 do 3, poki co nic nie ma wiecej
				if(atl_coords.y == 2 || atl_coords.y == 3): break
		else: break
	
	return object_tile_array

func get_distance(start_pos : Vector2i, end_pos : Vector2i) -> float:
	return Vector2i(end_pos - start_pos).length()

func new_position_found(new_pos : Vector2i, ap_restraint = MAX_AP_COST.NO_RESTRAINT) -> bool:
	current_unit.current_action = "Move"
	current_unit.action(new_pos, ap_restraint)
	if(current_unit.id_path.is_empty()):
		return false
	return true
