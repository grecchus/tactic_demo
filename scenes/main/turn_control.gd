extends Node

var turn_counter : int = 1
var current_turn : int = gv.Team.NEUTRAL



func next_turn():
	if(current_turn == gv.Team.RED): 
		turn_counter += 1
		current_turn = 0
		if(get_parent().team_arrays[0].size() == 0): current_turn = 1
	else: current_turn += 1
	
	for unit in get_parent().team_arrays[current_turn]:
		unit.action_points = unit.max_ap
	get_parent().UnitPanel.update_panel()


func _on_end_turn_pressed():
	next_turn()
