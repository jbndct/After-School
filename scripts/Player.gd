extends CharacterBody2D

const SPEED = 180.0
const GRAVITY = 800.0

enum State { FREE, LOCKED }
var current_state: State = State.FREE

@onready var animated_sprite = $AnimatedSprite2D
@onready var anim_sprite = $AnimatedSprite2D
@onready var footstep_sfx = $FootstepSFX
var walk_concrete = preload("res://assets/audio/sfx/sfx_walk_concrete.ogg")
var walk_wood = preload("res://assets/audio/sfx/sfx_walk_wood.ogg")

func _ready() -> void:
	up_direction = Vector2.UP
	
	# Listen to EventBus for state shifting
	EventBus.sugalhub_opened.connect(_on_sugalhub_opened)
	EventBus.sugalhub_closed.connect(_on_sugalhub_closed)
	
	anim_sprite.frame_changed.connect(_on_frame_changed)

func _on_frame_changed():
	var anim_name = anim_sprite.animation
	var current_frame = anim_sprite.frame
	
	# Only trigger sounds during walking animations
	if anim_name.begins_with("walk_") or anim_name.begins_with("player_walk"):
		# Assuming a standard 4-frame walk cycle where feet hit the ground on frames 1 and 3
		if current_frame == 1 or current_frame == 3:
			_play_footstep()

func _play_footstep():
	var current_scene = get_tree().current_scene.name.to_lower()
	
	# Swap sound based on the map
	if current_scene.begins_with("room"):
		footstep_sfx.stream = walk_wood
	else:
		footstep_sfx.stream = walk_concrete
		
	# Randomize pitch slightly so footsteps don't sound identical like a machine gun
	footstep_sfx.pitch_scale = randf_range(0.85, 1.15)
	footstep_sfx.play()

func _physics_process(delta: float) -> void:
	# 1. Gravity (Always applies, even if locked)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 2. State Routing
	match current_state:
		State.FREE:
			handle_movement()
		State.LOCKED:
			handle_locked()
			
	# 3. Apply physics
	move_and_slide()
	
	

func handle_movement() -> void:
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
		
		# Play the correct side-view walk cycle depending on input direction
		if direction > 0:
			if animated_sprite.animation != "walk_right":
				animated_sprite.play("walk_right")
		elif direction < 0:
			if animated_sprite.animation != "walk_left":
				animated_sprite.play("walk_left")
				
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		# Play the front-facing idle animation when standing still
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func handle_locked() -> void:
	# If the player was running when the app opened, bring them to a clean halt.
	velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if animated_sprite.animation != "idle":
		animated_sprite.play("idle")

# ─── EVENT RECEIVERS ───────────────────────────────────

func _on_sugalhub_opened() -> void:
	current_state = State.LOCKED
	RunState.interruption_return_x = global_position.x
	print("PLAYER EVENT: Saved interruption coordinate at X: ", RunState.interruption_return_x)

func _on_sugalhub_closed() -> void:
	current_state = State.FREE
