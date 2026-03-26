extends Node2D

@export var next_scene: String = "res://scenes/room_day1.tscn"

func _ready() -> void:
	# player rectangle and starting position
	$Player.position = Vector2(80, 600)
	
	# floor rectangle
	$Floor/ColorRect.size = Vector2(4000, 20)
	$Floor/ColorRect.position = Vector2(-2000, -10)
	$Floor.position = Vector2(0, 640)
	
	# force the floor collision shape size
	var floor_shape = RectangleShape2D.new()
	floor_shape.size = Vector2(4000, 20)
	$Floor/CollisionShape2D.shape = floor_shape
	
	# Force the invisible collision boxes to perfectly match the drawn rectangles
	$Floor/CollisionShape2D.position = Vector2(0, 0)
	$Player.reached_end.connect(_on_player_reached_end)

func _on_player_reached_end() -> void:
	get_tree().change_scene_to_file(next_scene)
