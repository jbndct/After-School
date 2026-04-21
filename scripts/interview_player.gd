extends CharacterBody2D

@export var speed: float = 500.0
@export var horizontal_padding: float = 60.0 # Adjust based on your sprite's width

var screen_width: float

func _ready() -> void:
	# Get the viewport width dynamically so it works even if you change resolutions
	screen_width = get_viewport_rect().size.x

func _physics_process(_delta: float) -> void:
	# Get input from default arrow keys or A/D
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * speed
	else:
		# Smoothly decelerate to 0 when keys are released
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	# Clamp the position so the player cannot leave the screen
	global_position.x = clamp(global_position.x, horizontal_padding, screen_width - horizontal_padding)
