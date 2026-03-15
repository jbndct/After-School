extends Node2D

@export var next_scene: String = "res://scenes/room_day1.tscn"

func _ready() -> void:
	# parallax layers
	$ParallaxBackground/"ParallaxLayer (far)"/ColorRect.size = Vector2(3840, 720)
	$ParallaxBackground/"ParallaxLayer (mid)"/ColorRect.size = Vector2(3840, 720)
	$ParallaxBackground/"ParallaxLayer (near)"/ColorRect.size = Vector2(3840, 720)
	
	# player rectangle and starting position
	$Player/ColorRect.size = Vector2(32, 52)
	$Player/ColorRect.position = Vector2(-16, -52)
	$Player.position = Vector2(80, 600)
	
	# floor rectangle
	$Floor/ColorRect.size = Vector2(4000, 20)
	$Floor/ColorRect.position = Vector2(-2000, -10)
	$Floor.position = Vector2(0, 640)
	
	# force the floor collision shape size
	var floor_shape = RectangleShape2D.new()
	floor_shape.size = Vector2(4000, 20)
	$Floor/CollisionShape2D.shape = floor_shape
	
	# force the player collision shape size
	var player_shape = RectangleShape2D.new()
	player_shape.size = Vector2(32, 52)
	$Player/CollisionShape2D.shape = player_shape

	# debug — confirm player shape is set
	print("Player shape: ", $Player/CollisionShape2D.shape)
	print("Player shape size: ", $Player/CollisionShape2D.shape.size)

	print("Floor position: ", $Floor.global_position)
	print("Player position: ", $Player.global_position)
	print("Floor shape size: ", $Floor/CollisionShape2D.shape.size)
	
	$Player.reached_end.connect(_on_player_reached_end)

func _on_player_reached_end() -> void:
	get_tree().change_scene_to_file(next_scene)
