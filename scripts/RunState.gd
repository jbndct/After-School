extends Node

# --- HYBRID ECONOMY ---
var money: int = 3000:
	set(value):
		money = value
		EventBus.money_updated.emit(money)

var debt: int = 0

# --- CORE ENDING FLAGS ---
var scholarship_passed: bool = false
var job_completed: bool = false
var work_shift_done: bool = false
var gambling_attempted: bool = false
var gambling_net_result: int = 0

# --- SESSION DATA ---
var current_phase: String = "morning"
var previous_location: String = ""
var interruption_return_x: float = 0.0
var credits_only: bool = false

# --- RETROFITTED DIALOGUE STATE ---
var completed_dialogues: Dictionary = {}

func is_work_shift_done() -> bool:
	return work_shift_done or job_completed or has_meta("work_shift_done")

func mark_work_shift_done(passed_quota: bool = true) -> void:
	work_shift_done = true
	job_completed = passed_quota
	set_meta("work_shift_done", true)

func reset_run() -> void:
	money = 3000
	debt = 0
	scholarship_passed = false
	job_completed = false
	work_shift_done = false
	gambling_attempted = false
	gambling_net_result = 0
	current_phase = "morning"
	previous_location = ""
	interruption_return_x = 0.0
	completed_dialogues.clear()
	if has_meta("work_shift_done"):
		remove_meta("work_shift_done")
	credits_only = false
