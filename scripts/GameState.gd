extends Node

# ─── SIGNALS ──────────────────────────────────────────
signal money_changed(new_amount: int)
signal notification_added(notif: Dictionary)
signal sugal_unlocked
signal buzzing_changed(is_buzzing: bool)
signal paycheck_received_flag

# ─── MONEY ────────────────────────────────────────────
var hand: int = 2000
var debt: int = 0
var paycheck_received_flag: bool = false
var loan_from_dante: int = 0

# ─── PROGRESS ─────────────────────────────────────────
var day: int = 1
var path: String = ""  # "honest" | "gambling"
var shift_hour: int = 0
var logbook_signed: int = 0

# ─── PHONE ────────────────────────────────────────────
var sugal_unlocked: bool = false
var buzzing: bool = false
var notifications: Array = []
# notif shape: { id, app, text, time, read }

# ─── GAMBLING ─────────────────────────────────────────
var sugal_opened: bool = false
var sugal_session_active: bool = false
var sugal_total_lost: int = 0
var sugal_loans_accepted: int = 0

# ─── RELATIONSHIPS ────────────────────────────────────
var dante_messages_sent: int = 0
var dante_messages_read: int = 0
var family_ignored: bool = false

# ─── MONEY FUNCTIONS ──────────────────────────────────
func add_money(amount: int) -> void:
	hand += amount
	emit_signal("money_changed", hand)

func deduct_money(amount: int) -> void:
	hand -= amount
	emit_signal("money_changed", hand)

func receive_dante_loan() -> void:
	loan_from_dante = 7500
	add_money(7500)

func receive_paycheck() -> void:
	add_money(6500)
	paycheck_received_flag = true
	sugal_unlocked = true
	emit_signal("paycheck_received_flag")
	emit_signal("sugal_unlocked")

func accept_sugal_loan(amount: int) -> void:
	debt += amount
	sugal_loans_accepted += 1
	add_money(amount)

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
	hand = 2000
	debt = 0
	paycheck_received_flag = false
	loan_from_dante = 0
	day = 1
	path = ""
	shift_hour = 0
	logbook_signed = 0
	sugal_unlocked = false
	buzzing = false
	notifications = []
	sugal_opened = false
	sugal_session_active = false
	sugal_total_lost = 0
	sugal_loans_accepted = 0
	dante_messages_sent = 0
	dante_messages_read = 0
	family_ignored = false
