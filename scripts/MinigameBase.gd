extends Node
class_name MinigameBase

# ==============================================================================
# THE MINIGAME CONTRACT
# Every minigame (Breakfast, Scholarship, Call Center, Sugal, Dream) 
# MUST extend this script. 
# ==============================================================================

@export var minigame_id: String = "default_game"
@export var reward_amount: int = 0
@export var time_limit: float = 0.0 # 0 means no timer

var is_active: bool = false
var current_time: float = 0.0

func _ready() -> void:
	# Automatically lock the player state if they happen to exist in this scene
	EventBus.sugalhub_opened.emit() 
	setup_game()

func _process(delta: float) -> void:
	if is_active and time_limit > 0:
		current_time -= delta
		if current_time <= 0:
			finish_game(false) # Time's up means failure by default

# ─── VIRTUAL FUNCTIONS (To be overridden by the specific minigames) ───

func setup_game() -> void:
	# E.g., spawn ingredients, load trivia questions
	pass

func start_game() -> void:
	is_active = true
	current_time = time_limit
	print("MINIGAME STARTED: ", minigame_id)

# ─── CORE RESOLUTION LOGIC ───

func finish_game(success: bool) -> void:
	if not is_active: return
	is_active = false
	
	print("MINIGAME FINISHED: ", minigame_id, " | Success: ", success)
	
	# 1. Update the Global RunState
	match minigame_id:
		"scholarship":
			RunState.scholarship_passed = success
			if success: RunState.money += reward_amount
		"work":
			RunState.job_completed = success
			if success: RunState.money += reward_amount
		"sugal":
			RunState.gambling_attempted = true
			# Sugal handles its own net result math internally before calling finish_game
		
	# 2. Tell the EventBus in case UI needs to flash a notification
	EventBus.minigame_completed.emit(minigame_id, success, reward_amount if success else 0)
	
	# 3. Route back to the narrative
	exit_to_narrative()

func exit_to_narrative() -> void:
	EventBus.sugalhub_closed.emit() # Unlock player just in case
	
	# Route back based on what game this was
	if minigame_id == "sugal":
		# Sugal is an interruption, reload the street
		SceneManager.load_scene("street")
	else:
		# Standard narrative progression
		SceneManager.advance_story(minigame_id)
