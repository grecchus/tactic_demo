extends Node

enum Team{NEUTRAL, BLUE, RED}
enum Weapon{UNARMED, ARMED}

var MainNodeAccess : Node2D
var console_log : Array[String] = []
var unit_data : Dictionary
var weapon_data : Dictionary

var cursor_paths := {
	"" : null,
	"reticle" : preload("res://textures/Reticle.png"),
	"heal" : preload("res://textures/heal_cursor.png")
}
signal log_updated()

func cprint(value) -> void:
	var string_val = str(value)
	print(string_val)
	console_log.push_front(string_val)
	emit_signal("log_updated")
	
func parse_json_data():
	var file = FileAccess.open("res://unitClassData/Classes.json", FileAccess.READ)
	if(file == null):
		print("Error opening class data file!")
		return
	var json = JSON.new()
	var json_string = file.get_as_text()
	var error = json.parse(json_string)
	if(error == OK):
		unit_data = json.data
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
