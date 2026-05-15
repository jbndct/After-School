# res://scripts/tutorial_arrow.gd
extends Node2D

var target_node: Node2D = null
var base_y: float = -80.0 # Height above the player's head

func _ready() -> void:
	position.y = base_y
	hide()
	
	# Simple up-and-down hovering animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", base_y - 10.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", base_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(_delta: float) -> void:
	if not is_instance_valid(target_node):
		hide()
		return
		
	# CRITICAL FIX: Track the CollisionShape's position instead of the root Area2D's origin
	var target_x = target_node.global_position.x
	var collision = target_node.get_node_or_null("CollisionShape2D")
	if is_instance_valid(collision):
		target_x = collision.global_position.x
		
	var player_x = get_parent().global_position.x
	var distance = target_x - player_x
	
	# If player is within 100 pixels of the target zone, hide the arrow
	if abs(distance) < 100.0:
		hide()
	else:
		show()
		# Flip the arrow horizontally based on direction
		if distance > 0:
			scale.x = 1  # Target is to the Right
		else:
			scale.x = -1 # Target is to the Left

func set_target(node: Node2D) -> void:
	target_node = node
