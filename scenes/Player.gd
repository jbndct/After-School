extends CharacterBody2D

const SPEED = 180.0
var facing_right: bool = true
var scene_end_x: float = 3200.0  # how far until scene ends

# emitted when player reaches the end of the street
signal reached_end

func _physics_process(delta: float) -> void:
	var direction = get_input_direction()
	
	if direction != 0:
		velocity.x = direction * SPEED
		facing_right = direction > 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	velocity.y = 0
	move_and_slide()
	
	# clamp so player cant walk left off screen
	global_position.x = max(80.0, global_position.x)
	
	# check if player reached the end
	if global_position.x >= scene_end_x:
		emit_signal("reached_end")

func get_input_direction() -> float:
	if Input.is_action_pressed("ui_right"):
		return 1.0
	return 0.0
