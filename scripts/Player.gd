# res://scripts/Player.gd
extends CharacterBody2D
@onready var sprite = $AnimatedSprite2D

const SPEED = 150.0
const SPRINT_SPEED = 250.0
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
	# 1. GRAVITY (We keep this at the top so he falls even if a dialogue pops up mid-air)
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. THE DIALOGUE LOCK (This is what was missing)
	# Checks if DialogManager is active, OR if the room/tutorial script locked the player
	var is_locked = false
	if "is_dialog_active" in DialogManager and DialogManager.is_dialog_active:
		is_locked = true
	if "current_state" in self and current_state == State.LOCKED:
		is_locked = true

	if is_locked:
		velocity.x = move_toward(velocity.x, 0, 300.0) # Force Diego to slide to a halt
		if is_on_floor():
			$AnimatedSprite2D.play("idle") # Force him into the idle animation
		move_and_slide()
		return # This 'return' completely stops the rest of the movement code below from running!

	# 3. NORMAL MOVEMENT & SPRINTING
	var direction := Input.get_axis("move_left", "move_right")
	var speed = 150.0
	
	if Input.is_key_pressed(KEY_SHIFT):
		speed = 250.0 
		
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# 4. NORMAL ANIMATION
	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0
		if Input.is_key_pressed(KEY_SHIFT):
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("idle")

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
