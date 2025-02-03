class_name Carabine
extends Item

var rng = RandomNumberGenerator.new()

@onready var main : Node2D
@onready var Ground : TileMapLayer #= get_node("/root/Main/TileMap/Ground")
@onready var Obstacles : TileMapLayer #= get_node("/root/Main/TileMap/Obstacles")
const DEFAULT_EFFECTIVE_RANGE : float = 5.0

func _init():
	cursor = "reticle"
	main = gv.MainNodeAccess
	Ground = main.get_tm_layer(0)
	Obstacles = main.get_tm_layer(1)
	

func _use_item(coords : Vector2i = Vector2i.ZERO):
	fire(Ground.local_to_map(owner_unit.global_position), coords)


func get_objects_on_lof(start_pos : Vector2i, end_pos : Vector2i) -> Array:
	var object_tile_array : Array = []
	var space = main.get_world_2d().direct_space_state
	var excluded_rids : Array[RID] = [owner_unit.get_rid()]
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
			if(intersected_object["collider"] is TileMapLayer): 
				var atl_coords = Obstacles.get_cell_atlas_coords(Obstacles.get_coords_for_body_rid(obj_rid))
				#tm.get_layer_for_body_rid(obj_rid),
				object_tile_array.append(Obstacles.get_coords_for_body_rid(obj_rid))
				#Sprawdza czy pole jest sciana. sciany maja indeksy y od 2 do 3, poki co ic nie ma wiecej
				if(atl_coords.y == 2 || atl_coords.y == 3): break
			else: object_tile_array.append(Ground.local_to_map(intersected_object["collider"].global_position))
		else: break
	
	return object_tile_array

func get_distance(start_pos : Vector2i, end_pos : Vector2i) -> float:
	return Vector2i(end_pos - start_pos).length()
	
#function calls main's function checking for collision at given tile, then checks whether are there any Unit class objects. If so, return that first unit in array


func fire(shooter_pos : Vector2i, target_pos : Vector2i):
	var distance_to_target : float = get_distance(shooter_pos, target_pos)
	var objects_on_lof : Array = get_objects_on_lof(shooter_pos, target_pos)
	var chance_to_hit : float = clamp(100.0 - DEFAULT_EFFECTIVE_RANGE * distance_to_target, 0.0, 100.0)
	var target_unit = get_target(target_pos)
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
		elif(Obstacles.get_cell_atlas_coords(obj).y >= 2): gv.cprint("Hit the wall")

func roll_for_hit(hit_chance : float) -> bool:
	return randf_range(0.0, 1.0) <= hit_chance/100.0


func get_target(coords : Vector2i) -> Unit:
	var col_arr = main.check_point_for_collision(coords)
	if(col_arr.size() > 0):
		for col in col_arr:
			if(col["collider"] is Unit) : return col["collider"]
	return null
