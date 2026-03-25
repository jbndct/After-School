extends CharacterBody2D

const SPEED = 180.0
const GRAVITY = 800.0

var scene_end_x: float = 1200.0
signal reached_end

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	up_direction = Vector2.UP
	
func _physics_process(delta: float) -> void:
	# 1. Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 2. Input and Animation
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
		animated_sprite.play("walk")
		# Flip the sprite if moving left
		animated_sprite.flip_h = direction < 0 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.play("idle")
		
	# 3. Apply physics
	move_and_slide()
