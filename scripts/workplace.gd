# res://scripts/workplace.gd
extends MinigameBase

@onready var timer_label = $TerminalMargin/TerminalScreen/Padding/VBox/Header/TimerLabel
@onready var ticket_label = $TerminalMargin/TerminalScreen/Padding/VBox/Header/TicketLabel
@onready var typing_display = $TerminalMargin/TerminalScreen/Padding/VBox/TypingDisplay
@onready var error_flash = $ErrorFlash

@onready var tutorial_popup = $TutorialPopup
@onready var start_button = $TutorialPopup/VBoxContainer/StartButton

const MAX_TICKETS = 5
const MAX_TIME = 60.0 # 1 Minutes

var time_left: float = MAX_TIME
var tickets_completed: int = 0
var game_active: bool = false

var current_target_string: String = ""
var current_input_index: int = 0
var mistakes_this_ticket: int = 0

# Escalating Difficulty Rounds
var escalating_phrases = [
	["Password reset sent.", "How can I help?", "Account verified."], # Round 1: Easy
	["Let me check your billing.", "Please hold for a moment.", "Your refund is processed."], # Round 2: Medium
	["I apologize for the inconvenience today.", "Your refund will reflect in 3 days."], # Round 3: Harder
	["I understand your frustration. I am escalating this.", "To reset your password, click the link sent to your email."], # Round 4: Very Hard
	["We are currently experiencing a system outage. Engineers are on it.", "Thank you for calling support. Can I have your 12-digit account number?"] # Round 5: Boss level
]

func _ready() -> void:
	minigame_id = "work"
	reward_amount = 800 
	
	$TerminalMargin.hide()
	tutorial_popup.show()
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	tutorial_popup.hide()
	$TerminalMargin.show()
	setup_game()

func setup_game() -> void:
	time_left = MAX_TIME
	tickets_completed = 0
	game_active = true
	
	_load_next_ticket()
	start_game()

func _load_next_ticket() -> void:
	current_input_index = 0
	mistakes_this_ticket = 0
	
	# Pull from the correct difficulty array based on current ticket number
	var difficulty_index = clampi(tickets_completed, 0, 4)
	current_target_string = escalating_phrases[difficulty_index].pick_random()
	
	_update_header()
	_update_display()

func _process(delta: float) -> void:
	if not game_active: return
		
	time_left -= delta
	_update_header()
	
	if error_flash.modulate.a > 0:
		error_flash.modulate.a = move_toward(error_flash.modulate.a, 0.0, delta * 3.0)
	
	if time_left <= 0:
		_end_shift()

func _unhandled_key_input(event: InputEvent) -> void:
	if not game_active: return
		
	if event.is_pressed() and not event.is_echo():
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_CAPSLOCK, KEY_TAB, KEY_BACKSPACE]: return
			
		var typed_char = char(event.unicode)
		var expected_char = current_target_string[current_input_index]
		
		if typed_char == expected_char:
			current_input_index += 1
			_update_display()
			
			if current_input_index >= current_target_string.length():
				_ticket_completed()
		else:
			# PENALTY: Minus 1 second and flag mistake
			mistakes_this_ticket += 1
			time_left -= 1.0
			_trigger_error_flash()
		
		get_viewport().set_input_as_handled()

func _update_display() -> void:
	var completed_text = current_target_string.substr(0, current_input_index)
	var remaining_text = current_target_string.substr(current_input_index, current_target_string.length() - current_input_index)
	var bbcode = "[b][color=#ffffff]" + completed_text + "[/color][/b][color=#555555]" + remaining_text + "[/color]"
	typing_display.text = bbcode

func _update_header() -> void:
	timer_label.text = "SYS_TIME: %.2fs" % max(time_left, 0.0)
	ticket_label.text = "TICKETS: %d/%d" % [tickets_completed, MAX_TICKETS]

func _trigger_error_flash() -> void:
	error_flash.modulate.a = 0.3 
	timer_label.add_theme_color_override("font_color", Color.RED)
	await get_tree().create_timer(0.2).timeout
	timer_label.remove_theme_color_override("font_color")

func _ticket_completed() -> void:
	tickets_completed += 1
	
	# REWARD: Perfect Streak (+10 seconds)
	if mistakes_this_ticket == 0:
		time_left += 10.0
		timer_label.add_theme_color_override("font_color", Color.GREEN)
		timer_label.text = "SYS_TIME: %.2fs (+10s STREAK!)" % time_left
		await get_tree().create_timer(0.8).timeout
		timer_label.remove_theme_color_override("font_color")
	
	if tickets_completed >= MAX_TICKETS:
		_end_shift()
	else:
		_load_next_ticket()

func _end_shift() -> void:
	game_active = false
	
	# BUG FIX FOR ROOM LOOP: Mark the shift as explicitly done
	RunState.set_meta("work_shift_done", true)
	
	if tickets_completed >= MAX_TICKETS:
		typing_display.text = "[center][color=#33ff33]SHIFT COMPLETE.\nFULL WAGE EARNED.[/color][/center]"
		RunState.job_completed = true
		reward_amount = 800
	else:
		typing_display.text = "[center][color=#ff3333]SHIFT FAILED. QUOTA NOT MET.\nPARTIAL WAGE APPLIED.[/color][/center]"
		RunState.job_completed = false
		reward_amount = 200 
		
	await get_tree().create_timer(3.0).timeout
	finish_game(RunState.job_completed)
