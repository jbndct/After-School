extends CharacterBody2D

const SPEED = 180.0
const GRAVITY = 800.0
var facing_right: bool = true
var scene_end_x: float = 3200.0

signal reached_end

func _physics_process(delta: float) -> void:
	# apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
	
	var direction = get_input_direction()
	
	if direction != 0:
		velocity.x = direction * SPEED
		facing_right = direction > 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	
	global_position.x = max(80.0, global_position.x)
	
	if global_position.x >= scene_end_x:
		emit_signal("reached_end")

func get_input_direction() -> float:
	if Input.is_action_pressed("ui_right"):
		return 1.0
	return 0.0
	
func _ready() -> void:
	up_direction = Vector2.UP
