extends CharacterBody2D

const SPEED = 180.0
const GRAVITY = 800.0

var scene_end_x: float = 3200.0
signal reached_end

var debug_label: Label

func _ready() -> void:
	up_direction = Vector2.UP
	
func _physics_process(delta: float) -> void:
	# 1. Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 2. Check standard arrow keys
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# 3. Apply physics
	move_and_slide()

	# 4. End of scene check
	if global_position.x >= scene_end_x:
		emit_signal("reached_end")
