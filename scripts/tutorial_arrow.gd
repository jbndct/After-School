# res://scripts/tutorial_arrow.gd
extends Node2D

@export var float_distance: float = 15.0
@export var float_speed: float = 0.8

var base_y: float = 0.0

func _ready() -> void:
	# Save the starting Y position
	base_y = position.y
	_start_bounce()

func _start_bounce() -> void:
	# Create an infinite bouncing animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", base_y - float_distance, float_speed / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", base_y, float_speed / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
