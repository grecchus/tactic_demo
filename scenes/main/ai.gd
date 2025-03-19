extends Node

#node access
@onready var MAIN : Node2D = get_node("/root/Main")
@onready var TURN_CONTROL : Node = get_node("/root/Main/TurnControl")
@onready var MODE : Node = get_node("/root/Main/ModeMachine/Default")
#tilemap access 
@onready var GROUND = get_node("/root/MainTileMap/Ground")
@onready var OBSTACLES = get_node("/root/MainTileMap/Obstacles")

#Red team is default AI controlled team
var controlled_teams : Array[int] = [gv.Team.RED]
var unit_queue : Array[Unit] = []
#AI behaviour patterns for given teams
var ai_pattern_dict : Dictionary = {
	gv.Team.RED : "Agressive"
}

func _ready():
	TURN_CONTROL.next_turn_signal.connect(_on_next_turn_signal)



func _on_next_turn_signal():
	if(controlled_teams.find(TURN_CONTROL.current_turn,0) != -1):
		unit_queue = MAIN.teams_array[TURN_CONTROL.current_turn]

func take_turn():
	
	while(not unit_queue.is_empty()):
		var u : Unit = unit_queue[0]
		while(u.action_points > 0):
			make_move(u)
		unit_queue.remove_at(0)
		
	
#	END TURN if queue is empty
	TURN_CONTROL.next_turn()

#MAKE STATE MACHINE
#TEMPLATE MOVE PATTERN
func make_move(u : Unit):
	pass
	

#move functions
