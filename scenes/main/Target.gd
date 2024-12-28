extends Node
var rng = RandomNumberGenerator.new()

@onready var main = get_node("/root/Main")
@onready var tm = get_node("/root/Main/TileMap")
const DEFAULT_EFFECTIVE_RANGE : float = 5.0

var active_unit : Unit = null
var target_unit : Unit = null

func _input_mouse_click(button_index : int, collider_info : Array, mouse_tm_pos : Vector2i):
	var unit_pos := Vector2i.ZERO
	if(active_unit != null): unit_pos = tm.local_to_map(active_unit.global_position)
	
	match button_index:
		MOUSE_BUTTON_LEFT:
			target_unit = get_target(mouse_tm_pos)
			if(active_unit.weapon == gv.Weapon.ARMED and active_unit.action_points > 0 and target_unit != active_unit): 
				fire(unit_pos, mouse_tm_pos)
				active_unit.action_points -= 1
				if(active_unit.action_points == 0): main.unit_selected()
			
		MOUSE_BUTTON_MASK_RIGHT:
			main.reset_mode()
func _input_mouse_motion(mouse_tm_pos : Vector2i):
	pass


func _on_main_unit_selected_signal(unit):
	active_unit = unit


#lof - line of fire
func get_objects_on_lof(start_pos : Vector2i, end_pos : Vector2i) -> Array:
	var object_tile_array : Array = []
	var space = main.get_world_2d().direct_space_state
	var excluded_rids : Array[RID] = [active_unit.get_rid()]
	while(start_pos != end_pos):
		var query = PhysicsRayQueryParameters2D.new()
		var intersected_object : Dictionary
		query.collide_with_areas = true
		query.exclude = excluded_rids
		query.from = main.tm_to_global_position(start_pos)
		query.to = main.tm_to_global_position(end_pos)
		
		intersected_object = space.intersect_ray(query)
		
		if(intersected_object.size() > 0):
			var obj_rid : RID = intersected_object["rid"]
			excluded_rids.append(obj_rid)
			if(intersected_object["collider"] is TileMap): 
				var atl_coords = tm.get_cell_atlas_coords(tm.get_layer_for_body_rid(obj_rid), tm.get_coords_for_body_rid(obj_rid))
				object_tile_array.append(tm.get_coords_for_body_rid(obj_rid))
				#Sprawdza czy pole jest sciana. sciany maja indeksy y od 2 do 3, poki co ic nie ma wiecej
				if(atl_coords.y == 2 || atl_coords.y == 3): break
			else: object_tile_array.append(tm.local_to_map(intersected_object["collider"].global_position))
		else: break
	
	return object_tile_array

func get_distance(start_pos : Vector2i, end_pos : Vector2i) -> float:
	return Vector2i(end_pos - start_pos).length()
	
#function calls main's function checking for collision at given tile, then checks whether are there any Unit class objects. If so, return that first unit in array
func get_target(coords : Vector2i) -> Unit:
	var col_arr = main.check_point_for_collision(coords)
	if(col_arr.size() > 0):
		for col in col_arr:
			if(col["collider"] is Unit) : return col["collider"]
	return null


func fire(shooter_pos : Vector2i, target_pos : Vector2i):
	var distance_to_target : float = get_distance(shooter_pos, target_pos)
	var objects_on_lof : Array = get_objects_on_lof(shooter_pos, target_pos)
	var chance_to_hit : float = clamp(100.0 - DEFAULT_EFFECTIVE_RANGE * distance_to_target, 0.0, 100.0)
	rng.randomize()
	
	for obj in objects_on_lof:
		if(obj != target_pos and obj != objects_on_lof.back()):
			if(roll_for_hit((100.0 - DEFAULT_EFFECTIVE_RANGE * get_distance(shooter_pos, obj))*0.2)):
				gv.cprint("Hit at: " + str(obj))
				var new_target = get_target(obj)
				if(new_target != null): new_target.take_damage(1)
				return
			if(int(get_distance(obj, target_pos)) == 1): chance_to_hit *= 0.7
		elif(obj == target_pos): 
			if(roll_for_hit(chance_to_hit)):
				gv.cprint("Target hit at: " + str(chance_to_hit) + "%")
				if(target_unit != null): target_unit.take_damage(2)
				return 
			else: gv.cprint("Target missed!")
		#TO BE CHANGED!!!
		elif(tm.get_cell_atlas_coords(2, obj).y >= 2): gv.cprint("Hit the wall")

func roll_for_hit(hit_chance : float) -> bool:
	return randf_range(0.0, 1.0) <= hit_chance/100.0
