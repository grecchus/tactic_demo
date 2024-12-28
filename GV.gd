extends Node

enum Team{NEUTRAL, BLUE, RED}
enum Weapon{UNARMED, ARMED}

var console_log : Array[String] = []

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
