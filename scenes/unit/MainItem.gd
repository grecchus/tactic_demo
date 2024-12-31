extends Action
#Code for "Use" node. This will check for unit's item and perform and action it's responsible for,
#for instance firing weapon or healing with a medkit.


func perform(target_pos = null) -> void:
	var item : Item = get_owner().weapon_obj
	if(target_pos != null):
		item._use_item(target_pos)
	else: item._use_item()
