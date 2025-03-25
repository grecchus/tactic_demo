extends Node

var turn_counter : int = 1
var current_turn : int = gv.Team.NEUTRAL
signal next_turn_signal


func next_turn():
	if(current_turn == gv.Team.RED): 
		turn_counter += 1
		current_turn = 0
		#do zmiany dla reszty druzyn
		while(get_parent().team_arrays[current_turn].size() == 0):
			current_turn += 1
	else: current_turn += 1
	
	for unit in get_parent().team_arrays[current_turn]:
		unit.action_points = unit.max_ap
	get_parent().UNIT_PANEL.update_panel()
	emit_signal("next_turn_signal")


func _on_end_turn_pressed():
	if(get_parent().is_players_turn()):
		next_turn()
		
