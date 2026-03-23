extends Action


func perform(ap_restraint, target_pos = null) -> void:
	var action_cost = get_owner().find_path(target_pos, ap_restraint)
	if(action_cost > 0): get_owner()._on_action_started(action_cost)
