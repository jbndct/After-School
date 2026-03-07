extends CharacterBody2D

const SPEED = 120.0
var can_move: bool = true

func _physics_process(delta):
	if not can_move:
		velocity.x = 0
		move_and_slide()
		return
	
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	move_and_slide()
