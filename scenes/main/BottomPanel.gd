extends Panel

var item_list = ["NONE", "CARABINE", "FIRST AID KIT"]

func update_panel(unit : Unit = null):
	$Control/Actions/Item.disabled = false
	if(unit == null): 
		$Control/Actions/Item.disabled = true
		unit = Unit.new()
	$Control/UnitInfo/UnitName.text = unit.unit_class_str
	$Control/UnitInfo/UnitIcon.texture.region.position = Vector2(unit.sheet_index) * Vector2(64.0, 64.0)
	$Control/UnitInfo/Stats/AP.text = "ACTION POINTS: " + str(unit.action_points)
	$Control/UnitInfo/Stats/HP.text = "HEAlTH POINTS: " + str(unit.health_points)
