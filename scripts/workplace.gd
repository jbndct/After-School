# res://scripts/workplace.gd
extends MinigameBase

const TEAL := Color("#41B9A7")
const ORANGE := Color("#F7640F")
const TYPED_COLOR := "#4A3A2A"       # letters already typed (dark brown)
const REMAINING_COLOR := "#C2AE97"   # letters still to type (faded)

const MAX_TICKETS: int = 5
const MAX_TIME: float = 60.0

# Result card text (edit freely)
const FAIL_MESSAGE := "Quota not Met!\nNo money gained."
const PASS_MESSAGE := "Quota met!\nFull wage earned."

@onready var timer_label: Label = %TimerLabel
@onready var ticket_label: Label = %TicketLabel
@onready var typing_display: RichTextLabel = %TypingDisplay
@onready var error_flash: CanvasItem = %ErrorFlash

@onready var start_screen: CanvasItem = %StartScreen
@onready var start_button: Button = %StartButton
@onready var terminal_state: CanvasItem = %TerminalState

@onready var result_layer: CanvasItem = %ResultLayer
@onready var result_dimmer: CanvasItem = %Dimmer
@onready var result_card: Control = %ResultCard
@onready var result_title: Label = %ResultTitle
@onready var result_icon: Panel = %ResultIcon
@onready var result_icon_label: Label = %ResultIconLabel
@onready var result_message: RichTextLabel = %ResultMessage
@onready var result_score: Label = %ResultScore

var time_left: float = MAX_TIME
var tickets_completed: int = 0
var game_active: bool = false
var shift_ended: bool = false

var current_target_string: String = ""
var current_input_index: int = 0
var mistakes_this_ticket: int = 0

var _locked: bool = false        # short pause between tickets (keys ignored)
var _streak_left: float = 0.0    # shows "+10s" in the timer for a moment
var _flash_left: float = 0.0     # shows the timer in red after a mistake

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

	terminal_state.hide()
	result_layer.hide()
	start_screen.show()
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	start_screen.hide()
	terminal_state.show()
	setup_game()

func setup_game() -> void:
	time_left = MAX_TIME
	tickets_completed = 0
	shift_ended = false
	game_active = true
	_locked = false
	_load_next_ticket()
	start_game()

func _load_next_ticket() -> void:
	current_input_index = 0
	mistakes_this_ticket = 0
	_locked = false
	var difficulty_index: int = clampi(tickets_completed, 0, escalating_phrases.size() - 1)
	var pool: Array = escalating_phrases[difficulty_index]
	current_target_string = str(pool.pick_random())
	_update_header()
	_update_display()

func _process(delta: float) -> void:
	if error_flash.modulate.a > 0.0:
		error_flash.modulate.a = move_toward(error_flash.modulate.a, 0.0, delta * 3.0)

	if not game_active or shift_ended:
		return

	time_left = maxf(time_left - delta, 0.0)
	_streak_left = maxf(_streak_left - delta, 0.0)
	_flash_left = maxf(_flash_left - delta, 0.0)
	_update_header()

	if time_left <= 0.0:
		_end_shift()

func _unhandled_key_input(event: InputEvent) -> void:
	if not game_active or shift_ended or _locked:
		return
	if current_target_string.is_empty() or current_input_index >= current_target_string.length():
		return
	if not (event is InputEventKey):
		return

	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_CAPSLOCK, KEY_TAB, KEY_BACKSPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
		return
	# ignore non-printing keys and invalid code points (char() can fail on them)
	if key.unicode < 32 or (key.unicode >= 0xD800 and key.unicode <= 0xDFFF) or key.unicode > 0x10FFFF:
		return

	var typed_char: String = char(key.unicode)
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
		error_flash.modulate.a = 0.3
		_flash_left = 0.25
		if time_left <= 0.0:
			_end_shift()

	get_viewport().set_input_as_handled()

func _update_display() -> void:
	var safe_idx: int = clampi(current_input_index, 0, current_target_string.length())
	var done: String = _bb(current_target_string.substr(0, safe_idx))
	var rest: String = _bb(current_target_string.substr(safe_idx))
	typing_display.text = "[b][color=%s]%s[/color][/b][color=%s]%s[/color]" % [TYPED_COLOR, done, REMAINING_COLOR, rest]

# keeps "[" in a sentence from being read as a BBCode tag
func _bb(s: String) -> String:
	return s.replace("[", "[lb]")

func _update_header() -> void:
	ticket_label.text = "%d/%d" % [tickets_completed, MAX_TICKETS]
	var t := "TIME: %ds" % ceili(maxf(time_left, 0.0))
	if _streak_left > 0.0:
		t += "  +10s"
		timer_label.add_theme_color_override("font_color", TEAL)
	elif _flash_left > 0.0:
		timer_label.add_theme_color_override("font_color", ORANGE)
	else:
		timer_label.remove_theme_color_override("font_color")
	timer_label.text = t

func _ticket_completed() -> void:
	AudioManager.play_sfx("sfx_correct_ding")
	tickets_completed += 1

	var perfect: bool = mistakes_this_ticket == 0
	if perfect:
		time_left += 10.0
		_streak_left = 0.8
	_update_header()

	if tickets_completed >= MAX_TICKETS:
		_end_shift()
		return

	# short pause, then the next ticket (no awaiting inside the key handler)
	_locked = true
	get_tree().create_timer(0.6 if perfect else 0.25).timeout.connect(_after_ticket_pause)

func _after_ticket_pause() -> void:
	if shift_ended or not is_inside_tree():
		return
	_load_next_ticket()

func _end_shift() -> void:
	if shift_ended:
		return
	shift_ended = true
	game_active = false
	_locked = true

	RunState.set_meta("work_shift_done", true)
	RunState.job_completed = true

	var passed: bool = tickets_completed >= MAX_TICKETS
	if passed:
		AudioManager.play_sfx("sfx_coin_fountain")
		reward_amount = 7000
	else:
		AudioManager.play_sfx("sfx_error_buzz")
		reward_amount = 1000

	_show_result(passed)

	await get_tree().create_timer(4.0).timeout
	if not is_inside_tree():
		return
	finish_game(passed)

# Dims the screen and pops in the result card
func _show_result(passed: bool) -> void:
	result_title.text = "Complete!" if passed else "Failed"
	result_icon.add_theme_stylebox_override("panel", _circle_style(TEAL if passed else ORANGE))
	result_icon_label.text = "OK" if passed else "X"
	result_icon_label.add_theme_font_size_override("font_size", 40 if passed else 56)
	result_message.text = "[b]%s[/b]" % (PASS_MESSAGE if passed else FAIL_MESSAGE)
	result_score.text = "%d/%d" % [tickets_completed, MAX_TICKETS]

	result_layer.show()
	result_dimmer.modulate.a = 0.0
	result_card.modulate.a = 0.0
	result_card.scale = Vector2(0.85, 0.85)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(result_dimmer, "modulate:a", 1.0, 0.4)
	tw.tween_property(result_card, "modulate:a", 1.0, 0.25)
	tw.tween_property(result_card, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _circle_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(100)
	return sb
