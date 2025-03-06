extends Node

#node access
@onready var MAIN : Node2D = get_node("/root/Main")
@onready var TURN_CONTROL : Node = get_node("/root/Main/TurnControl")
@onready var MODE : Node = get_node("/root/Main/ModeMachine/Default")
#tilemap access 
@onready var GROUND = get_node("/root/MainTileMap/Ground")
@onready var OBSTACLES = get_node("/root/MainTileMap/Obstacles")


var controlled_teams : Array[int] = [gv.Team.RED]
