# res://scripts/Player.gd
extends CharacterBody2D

const SPEED = 180.0
const SPRINT_SPEED = 300.0
const GRAVITY = 800.0

enum State { FREE, LOCKED }
var current_state: State = State.FREE

@onready var animated_sprite = $AnimatedSprite2D
@onready var footstep_sfx = $FootstepSFX

# Use the .wav files for footsteps as seen in your file directory
var walk_concrete = preload("res://assets/audio/sfx/sfx_walk_concrete.wav")
var walk_wood = preload("res://assets/audio/sfx/sfx_walk_wood.wav")

# Independent timing for footsteps
var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.35 # Adjust this (e.g. 0.4 for slower, 0.25 for faster)

func _ready() -> void:
	up_direction = Vector2.UP
	EventBus.sugalhub_opened.connect(_on_sugalhub_opened)
	EventBus.sugalhub_closed.connect(_on_sugalhub_closed)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	match current_state:
		State.FREE:
			handle_movement(delta)
		State.LOCKED:
			handle_locked()
			
	move_and_slide()

func handle_movement(delta: float) -> void:
	var direction = Input.get_axis("move_left", "move_right")
	var is_sprinting = Input.is_action_pressed("sprint")
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED
	
	if direction != 0:
		velocity.x = direction * current_speed
		
		if direction > 0 and animated_sprite.animation != "walk_right":
			animated_sprite.play("walk_right")
		elif direction < 0 and animated_sprite.animation != "walk_left":
			animated_sprite.play("walk_left")
			
		# Handle the footstep timer while moving
		if is_on_floor():
			footstep_timer -= delta
			if footstep_timer <= 0.0:
				_play_footstep()
				footstep_timer = FOOTSTEP_INTERVAL * (0.6 if is_sprinting else 1.0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		footstep_timer = 0.0 # Reset so next movement plays a step instantly
		
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func _play_footstep() -> void:
	var current_scene = get_tree().current_scene.name.to_lower()
	
	if current_scene.begins_with("room"):
		footstep_sfx.stream = walk_wood
	else:
		footstep_sfx.stream = walk_concrete
		
	footstep_sfx.pitch_scale = randf_range(0.85, 1.15)
	footstep_sfx.play()

func handle_locked() -> void:
	velocity.x = move_toward(velocity.x, 0, SPEED)
	footstep_timer = 0.0
	if animated_sprite.animation != "idle":
		animated_sprite.play("idle")

# ─── EVENT RECEIVERS ───────────────────────────────────
func _on_sugalhub_opened() -> void:
	current_state = State.LOCKED
	RunState.interruption_return_x = global_position.x

func _on_sugalhub_closed() -> void:
	current_state = State.FREE
