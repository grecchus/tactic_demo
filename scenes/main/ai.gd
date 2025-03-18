extends Node

#node access
@onready var MAIN : Node2D = get_node("/root/Main")
@onready var TURN_CONTROL : Node = get_node("/root/Main/TurnControl")
@onready var MODE : Node = get_node("/root/Main/ModeMachine/Default")
#tilemap access 
@onready var GROUND = get_node("/root/MainTileMap/Ground")
@onready var OBSTACLES = get_node("/root/MainTileMap/Obstacles")


var controlled_teams : Array[int] = [gv.Team.RED]
var unit_queue : Array[Unit] = []
#new_unit.action_finished.connect(_on_action_finished)
func _ready():
	TURN_CONTROL.next_turn_signal.connect(_on_next_turn_signal)

func _on_next_turn_signal():
	print("sss")
	if(controlled_teams.find(TURN_CONTROL.current_turn,0) != -1):
		TURN_CONTROL.next_turn()
