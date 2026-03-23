class_name Unit
extends CharacterBody2D

@onready var main = get_node("/root/Main") 
@onready var tilemap : TileMapLayer = get_node("/root/Main/TileMap/Ground")
@onready var audio_player = get_node("AudioPlayer")

const NO_RESTRAINT := -1

var unit_class_str : String = ""
var unit_ai : Array = []
var state = null
var team : int = gv.Team.NEUTRAL
var weapon : int = gv.Weapon.UNARMED
var weapon_obj : Item = Item.new()
var sheet_index := Vector2i.ZERO
var id_path : Array[Vector2i] = []

var current_action : String = "Move"
var action_points : int = 0
var max_ap : int = 2
var health_points : int = 3
var max_hp : int = 3

var movement_range : int = 6
var movement_speed : float = 15.0

#for detecting if unit moved after taking an action
var prev_pos : Vector2

var signal_emition_queued : bool = false
signal action_finished(state : bool)

func _ready():
	max_ap = gv.unit_data[unit_class_str]["action_points"]
	max_hp = gv.unit_data[unit_class_str]["health_points"]
	health_points = max_hp
	movement_range = gv.unit_data[unit_class_str]["movement_range"]
	unit_ai = gv.unit_data[unit_class_str]["ai"]
#	assign weapon -- to be added
	set_sheet_index()
	get_item(weapon)
	prev_pos = self.global_position

func _process(delta):
	if(id_path.is_empty()): return
	
	var target_pos := tilemap.map_to_local(id_path[0])
	global_position = global_position.move_toward(target_pos, movement_speed)
	
	if(global_position == target_pos):
		id_path.pop_front()
		if(main.active_unit == self):
			main.draw_path = id_path
			main.queue_redraw()
		if(id_path.is_empty()):
			emit_signal("action_finished", true)
			if(prev_pos != self.global_position): main.set_tile_occupied(tilemap.local_to_map(prev_pos), tilemap.local_to_map(self.global_position))


func action(arg = null, ap_restraint : int = NO_RESTRAINT):
	if(action_points > 0): get_node("Actions/" + current_action).perform(ap_restraint, arg)

func set_sheet_index():
	sheet_index = Vector2i.ZERO
	sheet_index.x += gv.unit_data[unit_class_str]["sprite_sheet_coord"]
	sheet_index.y = team
	sheet_index.x += weapon
	$Sprite2D.frame_coords = sheet_index

func get_item(item_index : int):
	match item_index:
		gv.Weapon.UNARMED:
			weapon_obj = Item.new()
		gv.Weapon.ARMED:
			weapon_obj = Firearm.new()
	if(weapon_obj != null):
		weapon_obj.owner_unit = self


func find_path(coords : Vector2i, ap_restraint : int = NO_RESTRAINT) -> int:
	var movement_cost = 0
	var front : int = 1
	var incr : int = 1
	var neighbouring_tiles = []
	
	if(main.check_point_for_collision(coords).size() > 0 || not main.astar_grid.is_in_boundsv(coords)): return -1
	
	id_path = main.astar_grid.get_id_path(tilemap.local_to_map(global_position), coords)
	if(ap_restraint > 0):
		id_path = id_path.slice(front, ap_restraint*movement_range+1)
		front = 0
	id_path = id_path.slice(front, action_points*movement_range+1)
#if the last tile on path is solid, find unoccupied neighbouring tile
	if(not id_path.is_empty()):
		while(main.astar_grid.is_point_solid(id_path[-1])):
			while(neighbouring_tiles.is_empty()):
				neighbouring_tiles = main.find_empty_tiles_in_radius(id_path[-1], incr)
				incr += 1
			id_path = main.astar_grid.get_id_path(tilemap.local_to_map(global_position), neighbouring_tiles.front())
			if(ap_restraint > 0):
				id_path = id_path.slice(front, ap_restraint*movement_range+1)
				front = 0
			id_path = id_path.slice(front, action_points*movement_range+1)
	
	movement_cost = ceili(float(id_path.size()) / float(movement_range))
	return movement_cost

func calculate_cost(coords : Vector2i):
	var cost : int = 0
	if(main.check_point_for_collision(coords).size() > 0 || not main.astar_grid.is_in_boundsv(coords)): return -1
	id_path = main.astar_grid.get_id_path(tilemap.local_to_map(global_position), coords)
	
	cost = ceili(float(id_path.size()-1) / float(movement_range))
	return cost

func _on_action_started(action_cost : int = 1, is_continuous_action : bool = true) -> void:
	action_points -= action_cost
	if(action_points <= 0):
		main.unit_selected()
	if(is_continuous_action):
		emit_signal("action_finished", false)
		prev_pos = self.global_position
		main.free_tile(tilemap.local_to_map(self.global_position))

func take_damage(damage : int):
	health_points = clamp(health_points - damage, 0, max_hp)
	if(health_points == 0): 
		main.team_arrays[team].erase(self)
		main.free_tile(tilemap.local_to_map(self.global_position))
		queue_free()

func play_sound(sound : AudioStreamWAV = null):
	audio_player.stream = sound
	print(audio_player.stream)
	audio_player.play()
	#audio_player.stream = null
