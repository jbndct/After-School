extends CharacterBody2D

const SPEED = 180.0
const GRAVITY = 800.0

enum State { FREE, LOCKED }
var current_state: State = State.FREE

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	up_direction = Vector2.UP
	
	# We listen to the EventBus. When the minigame opens, we lock input.
	EventBus.sugalhub_opened.connect(_on_sugalhub_opened)
	EventBus.sugalhub_closed.connect(_on_sugalhub_closed)

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
		animated_sprite.play("walk")
		animated_sprite.flip_h = direction < 0 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.play("idle")

func handle_locked() -> void:
	# If the player was running when the app opened, bring them to a clean halt.
	velocity.x = move_toward(velocity.x, 0, SPEED)
	animated_sprite.play("idle")

# ─── EVENT RECEIVERS ───────────────────────────────────

func _on_sugalhub_opened() -> void:
	current_state = State.LOCKED
	RunState.interruption_return_x = global_position.x
	print("PLAYER EVENT: Saved interruption coordinate at X: ", RunState.interruption_return_x)

func _on_sugalhub_closed() -> void:
	current_state = State.FREE
