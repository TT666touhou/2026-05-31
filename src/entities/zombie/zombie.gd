extends CharacterBody2D

@export var move_speed: float = 50.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var drawer = $ProceduralDrawer

var target_player: Node2D = null

func _ready() -> void:
	call_deferred("_find_player")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _physics_process(_delta: float) -> void:
	if not target_player:
		return
	if nav_agent:
		nav_agent.target_position = target_player.global_position
		var dir := nav_agent.get_next_path_position() - global_position
		if dir.length() > 5.0:
			velocity = dir.normalized() * move_speed
		else:
			velocity = Vector2.ZERO
	move_and_slide()
