extends Node2D

@export var next_scene: String = "res://scenes/room_day1.tscn"

func _ready() -> void:
	$Player.reached_end.connect(_on_player_reached_end)

func _on_player_reached_end() -> void:
	# simple fade then change scene
	# for now just change directly — add fade later
	get_tree().change_scene_to_file(next_scene)
