extends Node

var current_turn : int = gv.Team.NEUTRAL
signal next_turn_signal


func next_turn():
	current_turn = (current_turn + 1) % get_parent().team_arrays.size()
	while(get_parent().team_arrays[current_turn].size() == 0):
		current_turn = (current_turn + 1) % get_parent().team_arrays.size()
	
	for unit in get_parent().team_arrays[current_turn]:
		unit.action_points = unit.max_ap
	get_parent().UNIT_PANEL.update_panel()
	emit_signal("next_turn_signal")


func _on_end_turn_pressed():
	if(get_parent().is_players_turn()):
		next_turn()
		
