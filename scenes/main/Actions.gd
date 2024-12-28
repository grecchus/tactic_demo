extends HBoxContainer

func _ready():
	for button in get_children():
		button.custom_minimum_size = Vector2(self.size.y, self.size.y)
