extends Node2D

@onready var MODE = get_node("ModeMachine/Default")
@onready var LOG = get_node("UI/GameUI/RightPanel/GameLog")
@onready var UNITSCENE = preload("res://scenes/unit/unit.tscn")
@onready var UNIT_PANEL = get_node("UI/GameUI/BottomPanel")
#Tile Map Layers
@onready var GROUND = get_node("TileMap/Ground")
@onready var OBSTACLES = get_node("TileMap/Obstacles")
var astar_grid := AStarGrid2D.new()
var grid_offset := Vector2.ZERO 

enum TILE{DEFAULT, HOVERED, CLICKED}
enum TILE_MAP_LAYER{GROUND, OBSTACLES}

const TSD := float(64.0)
const TILESIZE := Vector2(TSD, TSD)
const nonexistent_tile := Vector2i(-1,-1)
var mapSize : Vector2i = Vector2i(36, 20)
var spawnSize : Vector2i = Vector2i(6, 5)
var team_arrays : Array[Array] = [[],[],[]]
var spawn_arrays : Array[Array] = [[],[],[]]
var player_controlled_teams : Array[int] = [gv.Team.BLUE]

var active_unit : Unit = null

var prev_mouse_pos : Vector2i = Vector2i.ZERO

var draw_path : Array = []

signal unit_selected_signal(unit : Unit)

#main functions
func _ready():
	gv.MainNodeAccess = self
	astar_grid.region = GROUND.get_used_rect()
	astar_grid.cell_size = TILESIZE
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	astargrid_set_walls()
	gv.log_updated.connect(LOG._on_log_updated)
	new_game()

func _process(delta):
	if(active_unit != null):
		$SelectedLabel.global_position = active_unit.global_position - $SelectedLabel.size/2
		$SelectedLabel.text = "AP: " + str(active_unit.action_points)
	$UI/GameUI/TurnDisplay.text = "Current turn: " + str($TurnControl.current_turn)

func _unhandled_input(event):
	var mouse_tm_pos = GROUND.local_to_map(get_global_mouse_position())
	if(event is InputEventMouseButton):
		if(event.pressed):
			var collider_info = check_point_for_collision(mouse_tm_pos)
			gv.cprint(mouse_tm_pos)
			#gv.cprint(astar_grid.is_point_solid(mouse_tm_pos))
			#print(check_radius(mouse_tm_pos,3))
			if(is_players_turn()):
				MODE._input_mouse_click(event.button_index, collider_info, mouse_tm_pos)
			
			var alt = 1
			if(collider_info.size() > 0): alt = 2
			GROUND.set_cell(mouse_tm_pos,0,Vector2i(TILE.CLICKED,0), alt)
		else:
			GROUND.set_cell(mouse_tm_pos,0,Vector2i(TILE.HOVERED,0))
			
	if(event is InputEventMouseMotion):
		GROUND.set_cell(mouse_tm_pos,0,Vector2i(TILE.HOVERED,0))
		if(prev_mouse_pos != mouse_tm_pos): GROUND.set_cell(prev_mouse_pos,0,Vector2i(TILE.DEFAULT,0))
			
		MODE._input_mouse_motion(mouse_tm_pos)
	
	prev_mouse_pos = mouse_tm_pos



func new_game():
	for i in 6:
		add_unit_to_spawn("Soldier", gv.Team.BLUE, gv.Weapon.ARMED)
		add_unit_to_spawn("Soldier", gv.Team.RED, gv.Weapon.ARMED)
	
	for i in 1:
		add_unit_to_spawn("Officer", gv.Team.BLUE, gv.Weapon.ARMED)
		add_unit_to_spawn("Officer", gv.Team.RED, gv.Weapon.ARMED)
	for i in 1:
		add_unit_to_spawn("Medic", gv.Team.BLUE)
		add_unit_to_spawn("Medic", gv.Team.RED)
	
	while(spawn_arrays[gv.Team.BLUE].size() > 0):
		spawn_unit(spawn_arrays[gv.Team.BLUE][0])
		spawn_arrays[gv.Team.BLUE].remove_at(0)
	
	while(spawn_arrays[gv.Team.RED].size() > 0):
		spawn_unit(spawn_arrays[gv.Team.RED][0])
		spawn_arrays[gv.Team.RED].remove_at(0)
	$TurnControl.next_turn()



#UNIT SELECT
func unit_selected(unit : Unit = null):
	if(active_unit != null): active_unit.current_action = "Move"
	if(unit != null):
		if(unit.action_points == 0 or unit.team != $TurnControl.current_turn): 
			unit = null
			$SelectedLabel.hide()
		else:
			$SelectedLabel.show()
	else:
		$SelectedLabel.hide() 
	active_unit = unit
	UNIT_PANEL.update_panel(unit)
	MODE = get_node("ModeMachine/Default")
	emit_signal("unit_selected_signal", active_unit)
	reset_mode()
	
	draw_path = []
	queue_redraw()


#Spawn unit
func add_unit_to_spawn(unit_class : String, team : int, weapon : int = 0):
	var new_unit = UNITSCENE.instantiate()
	new_unit.unit_class_str = unit_class
	new_unit.team = team
	new_unit.weapon = weapon
	spawn_arrays[team].push_back(new_unit)

func spawn_unit(new_unit : Unit):
	var next_pos_sign : int
	var init_spawn_pos : Vector2i
	match new_unit.team:
		gv.Team.BLUE:
			next_pos_sign = 1
			init_spawn_pos = Vector2i(0,0)
		gv.Team.RED:
			next_pos_sign = -1
			init_spawn_pos = mapSize - Vector2i(1,1)
	var next_pos := Vector2i.ZERO
	var spawn_pos := init_spawn_pos + next_pos * next_pos_sign
	while(next_pos.y < spawnSize.y):
		if(not check_point_for_collision(spawn_pos).size() > 0):
			new_unit.global_position = tm_to_global_position(spawn_pos)
			$UnitControl.add_child(new_unit)
			new_unit.action_finished.connect(_on_action_finished)
			team_arrays[new_unit.team].push_back(new_unit)
			break
		
		if(next_pos.x < spawnSize.x - 1): next_pos.x += 1
		else: 
			next_pos.x = 0
			next_pos.y += 1
		spawn_pos = init_spawn_pos + next_pos * next_pos_sign
	set_tile_occupied(spawn_pos, spawn_pos)


#utility
func check_point_for_collision(coords : Vector2i):
	var space := get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = tm_to_global_position(coords)
	return space.intersect_point(query)

func _draw():
	var color = Color("ffff00") #yellow
	for i in draw_path.size() - 1:
		if(i > 5):
			if(i > 11): color = Color("ff0000")
			else: color = Color("0000ff")
		var p1 : Vector2 = GROUND.map_to_local(draw_path[i])
		var p2 : Vector2 = GROUND.map_to_local(draw_path[i+1])
		draw_line(p1, p2, color)

func check_radius(starting_coords : Vector2i, range : int, exclude_center : bool = false) -> Array:
	const xy_diff : Array[Vector2i] = [Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,-1),Vector2i(-1,1)]
	var objects_found : Array = []
	var res : Array = []
	
	if(range < 0): return []
	if(not exclude_center):
		res = check_point_for_collision(starting_coords)
		if(not res.is_empty()):
			objects_found.append(res)
	
	while(range > 0):
		var next_pos = starting_coords - Vector2i(range, 0)
		for i in 4:
			for j in range:
				res = check_point_for_collision(next_pos)
				if(not res.is_empty()):
					objects_found.append(res)
				next_pos += xy_diff[i]
		range -= 1
	return objects_found

func tm_to_global_position(tm_pos : Vector2i) -> Vector2:
	return Vector2(tm_pos) * TILESIZE + TILESIZE/2

#setup
func astargrid_set_walls():
	for y in mapSize.y:
		for x in mapSize.x:
			if(OBSTACLES.get_cell_atlas_coords(Vector2i(x,y)) != nonexistent_tile):
				astar_grid.set_point_solid(Vector2i(x,y))

func set_tile_occupied(prev_pos : Vector2i, curr_pos : Vector2i):
	astar_grid.set_point_solid(curr_pos)
	if(prev_pos != curr_pos):
		astar_grid.set_point_solid(prev_pos, false)
func free_tile(pos : Vector2i):
	astar_grid.set_point_solid(pos, false)


func _on_action_finished(state : bool = true) -> void:
	if(not is_players_turn()): return
	set_process_unhandled_input(state)
	UNIT_PANEL.update_panel(active_unit)
	
func _on_end_turn_pressed():
	unit_selected()
	$SelectedLabel.hide()


func reset_mode():
	change_cursor()
	MODE = get_node("ModeMachine/Default")
	if(active_unit != null): active_unit.current_action = "Move"

func change_cursor(cursor : String = ""):
	Input.set_custom_mouse_cursor(gv.cursor_paths[cursor], Input.CURSOR_ARROW, Vector2(32.0, 32.0))


#Controling unit
func _on_item_pressed():
	MODE = get_node("ModeMachine/Target")
	active_unit.current_action = "Use"
	change_cursor(active_unit.weapon_obj.cursor)
	
	draw_path = []
	queue_redraw()

func get_tm_layer(layer : int = 0) -> TileMapLayer:
	return $TileMap.get_child(layer)

func is_players_turn() -> bool:
	return player_controlled_teams.find($TurnControl.current_turn) != -1
