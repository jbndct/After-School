# res://scripts/workplace.gd
extends MinigameBase

@onready var timer_label: Label = $TerminalMargin/TerminalScreen/Padding/VBox/Header/TimerLabel
@onready var ticket_label: Label = $TerminalMargin/TerminalScreen/Padding/VBox/Header/TicketLabel
@onready var typing_display: RichTextLabel = $TerminalMargin/TerminalScreen/Padding/VBox/TypingDisplay
@onready var error_flash: CanvasItem = $ErrorFlash

@onready var tutorial_popup: CanvasItem = $TutorialPopup
@onready var start_button: Button = $TutorialPopup/VBoxContainer/StartButton
@onready var terminal_margin: CanvasItem = $TerminalMargin

const MAX_TICKETS: int = 5
const MAX_TIME: float = 60.0

var time_left: float = MAX_TIME
var tickets_completed: int = 0
var game_active: bool = false
var shift_ended: bool = false

var current_target_string: String = ""
var current_input_index: int = 0
var mistakes_this_ticket: int = 0

var escalating_phrases: Array = [
	[
		"Naiproseso na namin ang iyong kahilingan.",
		"Paano kita matutulungan?",
		"Naivalidate na ang iyong account."
	],
	[
		"Titingnan ko ang iyong dapat bang bayaran.",
		"Sandali lang po, hinihintay ko.",
		"Naiproseso na po ang dapat na ibabalik na bayad sa inyo."
	],
	[
		"Humihingi po ako ng paumanhin sa abala na ito.",
		"Malalaman mo ang status ng iyong refund sa loob ng tatlong araw."
	],
	[
		"Naiintindihan ko po ang iyong pagkabigo. Iniimbestigahan ko na ito.",
		"Para i-reset ang iyong password, pindutin ang link na ipinadala sa iyong email."
	],
	[
		"Kasalukuyan kaming nakakaranas ng pagkabigo sa sistema. Inaayos na ito ng aming team.",
		"Salamat sa pagtawag sa suporta. Maaari ko bang makuha ang iyong labindalawang digit na numero ng account?"
	]
]

func _ready() -> void:
	AudioManager.play_bgm("bgm_work")
	minigame_id = "work"
	reward_amount = 800

	if terminal_margin:
		terminal_margin.hide()
	if tutorial_popup:
		tutorial_popup.show()
	if start_button and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	if tutorial_popup:
		tutorial_popup.hide()
	if terminal_margin:
		terminal_margin.show()
	setup_game()

func setup_game() -> void:
	time_left = MAX_TIME
	tickets_completed = 0
	shift_ended = false
	game_active = true
	_load_next_ticket()
	start_game()

func _load_next_ticket() -> void:
	current_input_index = 0
	mistakes_this_ticket = 0
	var difficulty_index: int = clampi(tickets_completed, 0, escalating_phrases.size() - 1)
	var pool: Array = escalating_phrases[difficulty_index]
	current_target_string = str(pool.pick_random())
	_update_header()
	_update_display()

func _process(delta: float) -> void:
	if not game_active or shift_ended:
		return

	time_left = maxf(time_left - delta, 0.0)
	_update_header()

	if error_flash and error_flash.modulate.a > 0.0:
		error_flash.modulate.a = move_toward(error_flash.modulate.a, 0.0, delta * 3.0)

	if time_left <= 0.0:
		_end_shift()

func _unhandled_key_input(event: InputEvent) -> void:
	if not game_active or shift_ended:
		return
	if current_target_string.is_empty() or current_input_index >= current_target_string.length():
		return

	if event.is_pressed() and not event.is_echo():
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_CAPSLOCK, KEY_TAB, KEY_BACKSPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
			return
		if event.unicode == 0:
			return

		var typed_char: String = char(event.unicode)
		var expected_char: String = current_target_string[current_input_index]

		if typed_char == expected_char:
			AudioManager.play_sfx("sfx_typewriter")
			current_input_index += 1
			_update_display()
			if current_input_index >= current_target_string.length():
				_ticket_completed()
		else:
			AudioManager.play_sfx("sfx_error_buzz")
			mistakes_this_ticket += 1
			time_left = maxf(time_left - 1.0, 0.0)
			_trigger_error_flash()
			if time_left <= 0.0:
				_end_shift()

		get_viewport().set_input_as_handled()

func _update_display() -> void:
	if not typing_display:
		return
	var safe_idx: int = clampi(current_input_index, 0, current_target_string.length())
	var completed_text: String = current_target_string.substr(0, safe_idx)
	var remaining_text: String = current_target_string.substr(safe_idx)
	typing_display.text = "[b][color=#ffffff]%s[/color][/b][color=#555555]%s[/color]" % [completed_text, remaining_text]

func _update_header() -> void:
	if timer_label:
		timer_label.text = "TIME: %.2fs" % maxf(time_left, 0.0)
	if ticket_label:
		ticket_label.text = "TICKETS: %d/%d" % [tickets_completed, MAX_TICKETS]

func _trigger_error_flash() -> void:
	if error_flash:
		error_flash.modulate.a = 0.3
	if timer_label:
		timer_label.add_theme_color_override("font_color", Color.RED)
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or shift_ended or not timer_label:
		return
	timer_label.remove_theme_color_override("font_color")

func _ticket_completed() -> void:
	AudioManager.play_sfx("sfx_correct_ding")
	tickets_completed += 1
	_update_header()

	if mistakes_this_ticket == 0:
		time_left += 10.0
		if timer_label:
			timer_label.add_theme_color_override("font_color", Color.GREEN)
			timer_label.text = "SYS_TIME: %.2fs (+10s STREAK!)" % time_left
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree() or shift_ended:
			return
		if timer_label:
			timer_label.remove_theme_color_override("font_color")
		_update_header()

	if tickets_completed >= MAX_TICKETS:
		_end_shift()
	else:
		_load_next_ticket()

func _end_shift() -> void:
	if shift_ended:
		return
	shift_ended = true
	game_active = false

	RunState.set_meta("work_shift_done", true)
	RunState.job_completed = true

	if tickets_completed >= MAX_TICKETS:
		AudioManager.play_sfx("sfx_coin_fountain")
		reward_amount = 800
		if typing_display:
			typing_display.text = "[center][color=#33ff33]SHIFT COMPLETE.\nFULL WAGE EARNED.[/color][/center]"
	else:
		AudioManager.play_sfx("sfx_error_buzz")
		reward_amount = 200
		if typing_display:
			typing_display.text = "[center][color=#ff3333]SHIFT FAILED.\nQUOTA NOT MET.\nPARTIAL WAGE APPLIED.[/color][/center]"

	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	finish_game(tickets_completed >= MAX_TICKETS)
