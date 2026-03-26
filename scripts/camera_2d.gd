extends Camera2D

@export var target: CharacterBody2D

func _process(_delta: float) -> void:
	if target:
		global_position.x = target.global_position.x
		global_position.y = 300  # fixed vertical center
