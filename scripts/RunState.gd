extends Node

# --- HYBRID ECONOMY ---
var money: int = 550 :
	set(value):
		money = value
		EventBus.money_updated.emit(money)
		
var debt: int = 0

# --- CORE ENDING FLAGS ---
var scholarship_passed: bool = false
var job_completed: bool = false
var gambling_attempted: bool = false
var gambling_net_result: int = 0

# --- SESSION DATA ---
var current_phase: String = "morning"
var previous_location: String = ""
var interruption_return_x: float = 0.0

# --- RETROFITTED DIALOGUE STATE ---
# We will use this to track which dialogues Ador has seen 
# instead of relying on 'current_step_index'.
var completed_dialogues: Dictionary = {}

func reset_run() -> void:
	money = 550
	debt = 0
	scholarship_passed = false
	job_completed = false
	gambling_attempted = false
	gambling_net_result = 0
	current_phase = "morning"
	completed_dialogues.clear()
