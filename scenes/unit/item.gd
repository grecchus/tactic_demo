class_name Item
extends Node

@onready var main : Node2D
@onready var Ground : TileMapLayer #= get_node("/root/Main/TileMap/Ground")
@onready var Obstacles : TileMapLayer #= get_node("/root/Main/TileMap/Obstacles")

var cursor : String = ""
var owner_unit : Unit = null
var use_sound : AudioStreamWAV = AudioStreamWAV.new()

var effective_range : float = 0.0

func _use_item(coords : Vector2i = Vector2i.ZERO):
	pass
