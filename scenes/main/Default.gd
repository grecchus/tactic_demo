extends Node

@onready var main = get_node("/root/Main")
@onready var tm = get_node("/root/Main/TileMap/Ground")
var active_unit : Unit = null


func _input_mouse_click(button_index : int, collider_info : Array, mouse_tm_pos : Vector2i):
	match button_index:
		
		MOUSE_BUTTON_LEFT:
			if(collider_info.size() > 0):
				if(collider_info[0]["collider"] is Unit): main.unit_selected(collider_info[0]["collider"])
			else: main.unit_selected()
			
		MOUSE_BUTTON_MASK_RIGHT:
			if(active_unit != null):
				active_unit.action(mouse_tm_pos)


func _input_mouse_motion(mouse_tm_pos : Vector2i):
	if(active_unit != null):
		if(active_unit.id_path.is_empty() and main.astar_grid.is_in_boundsv(mouse_tm_pos)):
			main.draw_path = main.astar_grid.get_id_path(
				tm.local_to_map(active_unit.global_position),
				mouse_tm_pos
				)
	else: main.draw_path = []
	main.queue_redraw()

func _on_main_unit_selected_signal(unit):
	active_unit = unit
