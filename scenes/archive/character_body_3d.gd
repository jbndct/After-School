extends CharacterBody3D

# Automatically fetches a reference to your player's AnimationPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPEED = 5.0

func _physics_process(delta: float) -> void:
	# 1. Gather movement vector inputs from keyboard/controller
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 2. Check if player is pressing an arrow key / WASD direction
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# 3. Match the correct animation name to the direction velocity
		if velocity.x < 0:
			# Moving Left (X is negative)
			animation_player.play("walk_left")
		elif velocity.x > 0:
			# Moving Right (X is positive)
			animation_player.play("walk_right")
		else:
			# If moving purely forward/backward (Z-axis), default to right walk frame
			animation_player.play("walk_right") 
			
	else:
		# 4. Decelerate smoothly if no keys are pressed
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		# Play your forward-facing idle track when stopped
		animation_player.play("idle") 

	# 5. Execute 3D physical movement and slide along terrain collisions
	move_and_slide()
