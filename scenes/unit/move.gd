extends Action


func perform(target_pos = null) -> void:
	var action_cost = get_owner().find_path(target_pos)
	if(action_cost != -1): get_owner()._on_action_started(action_cost)
	
