extends Node

@onready var main = get_node("/root/Main")
@onready var tm = get_node("/root/Main/TileMap")

var active_unit : Unit = null
var target_unit : Unit = null

func _input_mouse_click(button_index : int, collider_info : Array, mouse_tm_pos : Vector2i):
	var unit_pos := Vector2i.ZERO
	if(active_unit != null): unit_pos = tm.local_to_map(active_unit.global_position)
	
	match button_index:
		MOUSE_BUTTON_LEFT:
			active_unit.action(mouse_tm_pos)
			if(active_unit.action_points == 0): main.unit_selected()
			
		MOUSE_BUTTON_MASK_RIGHT:
			main.reset_mode()
func _input_mouse_motion(mouse_tm_pos : Vector2i):
	pass


func _on_main_unit_selected_signal(unit):
	active_unit = unit
