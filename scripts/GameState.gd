extends Node

# ─── SIGNALS ──────────────────────────────────────────
signal money_changed(new_amount: int)
signal notification_added(notif: Dictionary)
signal sugal_unlocked
signal buzzing_changed(is_buzzing: bool)
signal paycheck_received

# ─── MONEY (THE PERFECT ZERO ECONOMY) ─────────────────
var hand: int = 550
var debt: int = 0
var paycheck_received_flag: bool = false
var loan_from_pepito: int = 0
var daily_expense: int = 350

# ─── NARRATIVE ENDING FLAGS ───────────────────────────
var failed_minigame: bool = false
var has_gambled: bool = false
var gambling_profit: int = 0

# ─── PROGRESS ─────────────────────────────────────────
var day: int = 1
var path: String = ""  # "honest" | "gambling"
var shift_hour: int = 0
var logbook_signed: int = 0
var step_dialogue_finished: bool = false

var current_part: int = 1
var current_step_index: int = 0
var last_scene_path: String = ""

var progression_flow: Dictionary = {
	1: ["res://scenes/room.tscn", "res://scenes/street.tscn", "res://scenes/school.tscn", "res://scenes/MinigameScholarship.tscn", "res://scenes/school.tscn", "res://scenes/street.tscn", "res://scenes/room.tscn"],
	2: ["res://scenes/room.tscn", "res://scenes/street.tscn", "res://scenes/school.tscn", "res://scenes/street.tscn", "res://scenes/workplace.tscn", "res://scenes/MinigameInterview.tscn", "res://scenes/workplace.tscn", "res://scenes/street.tscn", "res://scenes/room.tscn"],
	3: ["res://scenes/room.tscn", "res://scenes/street.tscn", "res://scenes/school.tscn", "res://scenes/street.tscn", "res://scenes/workplace.tscn", "res://scenes/MinigameWork.tscn", "res://scenes/workplace.tscn", "res://scenes/street.tscn", "res://scenes/room.tscn"],
	4: ["res://scenes/room.tscn", "res://scenes/street.tscn", "res://scenes/school.tscn", "res://scenes/ending.tscn"]
}

var objectives_map: Dictionary = {
	1: ["Wake up and get ready", "Walk to the terminal", "Go to school", "Take the scholarship exam", "Leave school", "Walk home", "Rest for the night"],
	# Add arrays for parts 2, 3, and 4...
}

func get_current_objective() -> String:
	if objectives_map.has(current_part) and current_step_index < objectives_map[current_part].size():
		return objectives_map[current_part][current_step_index]
	return "No current objectives."

# ─── PHONE ────────────────────────────────────────────
var sugal_unlocked_flag: bool = true
var buzzing: bool = false
var notifications: Array = []

# ─── GAMBLING ─────────────────────────────────────────
var sugal_opened: bool = false
var sugal_session_active: bool = false
var sugal_total_lost: int = 0
var sugal_loans_accepted: int = 0
var sugal_visits: int = 0

# ─── RELATIONSHIPS ────────────────────────────────────
var pepito_messages_sent: int = 0
var pepito_messages_read: int = 0
var family_ignored: bool = false

# ─── MONEY FUNCTIONS ──────────────────────────────────
func add_money(amount: int) -> void:
	hand += amount
	emit_signal("money_changed", hand)

func deduct_money(amount: int) -> void:
	hand -= amount
	emit_signal("money_changed", hand)

func receive_pepito_loan() -> void:
	loan_from_pepito = 7500
	debt += loan_from_pepito # Ensures he carries the debt
	add_money(7500)

func receive_paycheck() -> void:
	add_money(5500) # Minimum wage reality
	paycheck_received_flag = true
	sugal_unlocked_flag = true
	emit_signal("paycheck_received")
	emit_signal("sugal_unlocked")

func accept_sugal_loan(amount: int) -> void:
	debt += amount
	sugal_loans_accepted += 1
	add_money(amount)

func process_daily_expenses() -> void:
	deduct_money(daily_expense)
	print("Day ", current_part, " ended. Deducted daily expenses: ₱", daily_expense, ". Current balance: ₱", hand)

# ─── PHONE FUNCTIONS ──────────────────────────────────
func add_notification(id: String, app: String, text: String, time: String) -> void:
	var notif = { "id": id, "app": app, "text": text, "time": time, "read": false }
	notifications.append(notif)
	emit_signal("notification_added", notif)

func set_buzzing(value: bool) -> void:
	buzzing = value
	emit_signal("buzzing_changed", value)

# ─── ENDING LOGIC ─────────────────────────────────────
func can_enroll() -> bool:
	return hand >= 15000

func resolve_path() -> void:
	if sugal_opened:
		path = "gambling"
	else:
		path = "honest"

# ─── RESET ────────────────────────────────────────────
func reset() -> void:
	hand = 550
	debt = 0
	paycheck_received_flag = false
	loan_from_pepito = 0
	day = 1
	path = ""
	shift_hour = 0
	logbook_signed = 0
	sugal_unlocked_flag = true
	buzzing = false
	notifications = []
	sugal_opened = false
	sugal_session_active = false
	sugal_total_lost = 0
	sugal_loans_accepted = 0
	pepito_messages_sent = 0
	pepito_messages_read = 0
	family_ignored = false
	current_part = 1
	current_step_index = 0
	sugal_visits = 0
	step_dialogue_finished = false
	
	# Reset new flags
	failed_minigame = false
	has_gambled = false
	gambling_profit = 0

# ─── SCENE PROGRESSION ────────────────────────────────
func advance_scene() -> void:
	# --- UPDATED: CRITICAL FAILURE OVERRIDE ---
	# If they failed, skip to Day 4. We check 'current_part < 4' so it only skips once 
	# and allows them to actually play out the final day's walk of shame.
	if failed_minigame and current_part < 4:
		current_part = 4
		current_step_index = 0
		
		# WE NO LONGER TURN THE FLAG OFF HERE. 
		# It stays true so ending.tscn can read it later!
		
		var skip_scene = progression_flow[current_part][current_step_index]
		if ResourceLoader.exists(skip_scene):
			get_tree().change_scene_to_file(skip_scene)
		else:
			print("CRITICAL ERROR: Could not skip to Day 4.")
		return

	var sequence = progression_flow[current_part]
	current_step_index += 1
	step_dialogue_finished = false
	
	# Move to the next part if we finished the current sequence
	if current_step_index >= sequence.size():
		
		# Trigger daily expenses before the day changes
		if current_part < 4:
			process_daily_expenses()
			
		current_part += 1
		current_step_index = 0
		
		# Check if the game is over
		if current_part > 4:
			resolve_path() 
			get_tree().change_scene_to_file("res://scenes/ending.tscn")
			return
			
	var next_scene_path = progression_flow[current_part][current_step_index]
	
	if ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("CRITICAL ERROR: Tried to load a scene that doesn't exist! Path: ", next_scene_path)
