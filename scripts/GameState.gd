extends Node

# ==============================================================================
# TRANSITIONAL BRIDGE
# Do not build new features here! This file exists purely to intercept calls 
# from your old scenes and route them to the new RunState/EventBus architecture
# without crashing the game. We will slowly phase this out.
# ==============================================================================

# ─── OLD SIGNALS (Kept alive so old UI connections don't crash) ───
signal money_changed(new_amount: int)
signal notification_added(notif: Dictionary)
signal sugal_unlocked
signal buzzing_changed(is_buzzing: bool)
signal paycheck_received

# ─── THE ECONOMY PROXY ───
# When an old script asks for "GameState.hand", we silently give them "RunState.money".
var hand: int:
	get:
		return RunState.money
	set(value):
		RunState.money = value

var debt: int:
	get:
		return RunState.debt
	set(value):
		RunState.debt = value

# ─── GHOST VARIABLES ───
# These are kept alive strictly so old scripts don't crash when trying to access them.
# They no longer drive the game logic.
var day: int = 1
var path: String = ""
var shift_hour: int = 0
var logbook_signed: int = 0
var step_dialogue_finished: bool = false
var current_part: int = 1
var current_step_index: int = 0
var last_scene_path: String = ""
var sugal_unlocked_flag: bool = true
var buzzing: bool = false
var notifications: Array = []
var sugal_opened: bool = false
var sugal_session_active: bool = false
var sugal_total_lost: int = 0
var sugal_loans_accepted: int = 0
var sugal_visits: int = 0
var pepito_messages_sent: int = 0
var pepito_messages_read: int = 0
var family_ignored: bool = false
var failed_minigame: bool = false
var has_gambled: bool = false
var gambling_profit: int = 0
var paycheck_received_flag: bool = false
var loan_from_pepito: int = 0
var daily_expense: int = 350
var progression_flow: Dictionary = {}
var objectives_map: Dictionary = {}


# ─── PROXY FUNCTIONS ───

func add_money(amount: int) -> void:
	RunState.money += amount
	emit_signal("money_changed", RunState.money) # Trigger old UI updates

func deduct_money(amount: int) -> void:
	RunState.money -= amount
	emit_signal("money_changed", RunState.money) # Trigger old UI updates

func reset() -> void:
	RunState.reset_run()

func get_current_objective() -> String:
	return "Go to school." # Dummy fallback so text boxes don't crash

func advance_scene() -> void:
	print("WARNING: advance_scene() was called but is disabled during architecture transition.")
	pass 

# ─── DEAD FUNCTIONS (Safely bypassed) ───
func receive_pepito_loan() -> void:
	pass 

func process_daily_expenses() -> void:
	pass

func accept_sugal_loan(amount: int) -> void:
	pass

func receive_paycheck() -> void:
	add_money(5500)

func add_notification(id: String, app: String, text: String, time: String) -> void:
	pass

func set_buzzing(value: bool) -> void:
	buzzing = value
	emit_signal("buzzing_changed", value)
