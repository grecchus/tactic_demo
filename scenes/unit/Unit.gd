class_name Unit
extends CharacterBody2D

@onready var main = get_node("/root/Main") 
@onready var tilemap : TileMapLayer = get_node("/root/Main/TileMap/Ground")

var unit_class_str : String = ""
var unit_class : UnitClass = null
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

var movement_speed : float = 20.0

signal action_finished(state : bool)

func _ready():
	unit_class = get_node("UnitClass/"+unit_class_str)
	set_sheet_index()
	get_item(weapon)

func _process(delta):
	if(id_path.is_empty()): return
	
	var target_pos := tilemap.map_to_local(id_path[0])
	global_position = global_position.move_toward(target_pos, movement_speed)
	
	if(global_position == target_pos):
		id_path.pop_front()
		if(main.active_unit == self):
			main.draw_path = id_path
			main.queue_redraw()
		if(id_path.is_empty()): emit_signal("action_finished", true)


func action(arg = null):
	if(action_points > 0): get_node("Actions/" + current_action).perform(arg)

func set_sheet_index():
	sheet_index = Vector2i.ZERO
	if(unit_class != null): sheet_index += unit_class.sheet_index
	sheet_index.y = team
	sheet_index.x += weapon
	$Sprite2D.frame_coords = sheet_index

func get_item(item_index : int):
	match item_index:
		gv.Weapon.UNARMED:
			weapon_obj = Item.new()
		gv.Weapon.ARMED:
			weapon_obj = Carabine.new()
	if(weapon_obj != null):
		weapon_obj.owner_unit = self


func find_path(coords : Vector2i) -> int:
	var movement_cost = 0
	if(main.check_point_for_collision(coords).size() > 0 || not main.astar_grid.is_in_boundsv(coords)): return -1
	var new_id_path = main.astar_grid.get_id_path(
		tilemap.local_to_map(global_position),
		coords
		) 
	id_path = new_id_path.slice(1, action_points*6+1)
	movement_cost = ceili(float(id_path.size()) / 6.0)
	return movement_cost

func _on_action_started(action_cost : int = 1, is_continuous_action : bool = true) -> void:
	action_points -= action_cost
	if(action_points <= 0):
		main.unit_selected()
	if(is_continuous_action):
		emit_signal("action_finished", false)

func take_damage(damage : int):
	health_points = clamp(health_points - damage, 0, max_hp)
	if(health_points == 0): 
		main.team_arrays[team].erase(self)
		queue_free()
