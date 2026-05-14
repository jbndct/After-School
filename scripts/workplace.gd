# res://scripts/workplace.gd
extends MinigameBase

@onready var timer_label = $TerminalMargin/TerminalScreen/Padding/VBox/Header/TimerLabel
@onready var ticket_label = $TerminalMargin/TerminalScreen/Padding/VBox/Header/TicketLabel
@onready var typing_display = $TerminalMargin/TerminalScreen/Padding/VBox/TypingDisplay
@onready var error_flash = $ErrorFlash

const MAX_TICKETS = 5
const MAX_TIME = 60.0

var time_left: float = MAX_TIME
var tickets_completed: int = 0
var game_active: bool = false

var current_target_string: String = ""
var current_input_index: int = 0

var customer_support_phrases: Array[String] = [
	"Thank you for calling support. Can I have your account number?",
	"I apologize for the inconvenience. Let me check your billing statement.",
	"Please hold for a moment while I pull up your transaction history.",
	"Your refund has been processed and will reflect in three business days.",
	"To reset your password, please click the link sent to your registered email.",
	"I understand your frustration. I am escalating this to my supervisor now.",
	"Is there anything else I can assist you with today?",
	"We are currently experiencing a system outage. Our engineers are on it."
]

func _ready() -> void:
	# Initialize MinigameBase requirements
	minigame_id = "work"
	reward_amount = 800 # Full payout
	
	setup_game()

func setup_game() -> void:
	time_left = MAX_TIME
	tickets_completed = 0
	game_active = false
	
	_update_header()
	typing_display.text = "[center][color=#33ff33]PRESS [ENTER] TO START SHIFT[/color][/center]"

func start_quiz() -> void:
	game_active = true
	_load_next_ticket()
	start_game()

func _load_next_ticket() -> void:
	current_input_index = 0
	current_target_string = customer_support_phrases.pick_random()
	_update_display()

func _process(delta: float) -> void:
	if not game_active:
		return
		
	time_left -= delta
	_update_header()
	
	if error_flash.modulate.a > 0:
		error_flash.modulate.a = move_toward(error_flash.modulate.a, 0.0, delta * 3.0)
	
	if time_left <= 0:
		_end_shift()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if not game_active:
			if event.is_action("ui_accept"):
				start_quiz()
				get_viewport().set_input_as_handled()
			return
			
		# Ignore modifier keys completely
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_CAPSLOCK, KEY_TAB, KEY_BACKSPACE]:
			return
			
		var typed_char = char(event.unicode)
		var expected_char = current_target_string[current_input_index]
		
		# If the typed character matches exactly (case-sensitive)
		if typed_char == expected_char:
			current_input_index += 1
			_update_display()
			
			if current_input_index >= current_target_string.length():
				_ticket_completed()
		else:
			# Wrong key pressed
			_trigger_error_flash()
		
		get_viewport().set_input_as_handled()

func _update_display() -> void:
	var completed_text = current_target_string.substr(0, current_input_index)
	var remaining_text = current_target_string.substr(current_input_index, current_target_string.length() - current_input_index)
	
	# BBCode formatting: White for typed, gray/dim for remaining
	var bbcode = "[b][color=#ffffff]" + completed_text + "[/color][/b][color=#555555]" + remaining_text + "[/color]"
	typing_display.text = bbcode

func _update_header() -> void:
	timer_label.text = "SYS_TIME: %.2fs" % max(time_left, 0.0)
	ticket_label.text = "TICKETS: %d/%d" % [tickets_completed, MAX_TICKETS]

func _trigger_error_flash() -> void:
	error_flash.modulate.a = 0.3 # Briefly spike opacity

func _ticket_completed() -> void:
	tickets_completed += 1
	_update_header()
	
	if tickets_completed >= MAX_TICKETS:
		_end_shift()
	else:
		_load_next_ticket()

func _end_shift() -> void:
	game_active = false
	
	if tickets_completed >= MAX_TICKETS:
		typing_display.text = "[center][color=#33ff33]SHIFT COMPLETE.\nFULL WAGE EARNED.[/color][/center]"
		RunState.job_completed = true
		reward_amount = 800
	else:
		typing_display.text = "[center][color=#ff3333]SHIFT FAILED. QUOTA NOT MET.\nPARTIAL WAGE APPLIED.[/color][/center]"
		RunState.job_completed = false
		reward_amount = 200 # Partial payout
		
	# Delay so player can read the outcome before returning to room
	await get_tree().create_timer(3.0).timeout
	
	# finish_game is inherited from MinigameBase, it handles the HUD update and routing
	finish_game(RunState.job_completed)
