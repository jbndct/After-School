extends Node

# ─── MONEY ────────────────────────────────────────────
var balance: int = 10300

# ─── PROGRESS ─────────────────────────────────────────
var day: int = 1

# ─── RELATIONSHIP FLAGS ────────────────────────────────
var mom_replied: bool = false
var trisha_warm: bool = false

# ─── GAMBLING FLAGS ───────────────────────────────────
var sugal_opened: bool = false
var credit_taken: bool = false
var notifications_dismissed: int = 0
var slot_credits: int = 0

# ─── FUNCTIONS ────────────────────────────────────────
func apply_trisha_loan():
	balance += 2450

func apply_shift_pay():
	balance += 435

func apply_credit_line():
	balance -= 1000
	slot_credits += 1000
	credit_taken = true

func can_enroll() -> bool:
	return balance >= 13021

func get_ending() -> String:
	if can_enroll():
		return "A"
	elif not sugal_opened:
		return "B1"
	else:
		return "B2"

func reset():
	balance = 10300
	day = 1
	mom_replied = false
	trisha_warm = false
	sugal_opened = false
	credit_taken = false
	notifications_dismissed = 0
	slot_credits = 0
