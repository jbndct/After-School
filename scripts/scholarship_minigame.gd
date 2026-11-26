# res://scripts/scholarship_minigame.gd
extends MinigameBase

const TEAL := Color("#41B9A7")
const ORANGE := Color("#F7640F")

@onready var paper_ui = $Paper
@onready var question_label = $Paper/MarginContainer/QuizLayout/QuestionLabel
@onready var score_label = $Paper/MarginContainer/QuizLayout/ScoreLabel
@onready var options_container = $Paper/MarginContainer/QuizLayout/OptionsContainer

@onready var tutorial_popup = $TutorialPopup
@onready var start_button = $TutorialPopup/VBoxContainer/StartButton

# Result card (the tilted FAILED / PASSED card)
@onready var result_layer = $ResultLayer
@onready var result_dimmer = $ResultLayer/Dimmer
@onready var result_card = $ResultLayer/ResultCard
@onready var result_title = %ResultTitle
@onready var result_score = %ResultScore
@onready var result_message = %ResultMessage

var all_questions: Array = []
var active_questions: Array = []
var current_question_index: int = 0
var score: int = 0
var required_score: int = 7 

func setup_game() -> void:
	AudioManager.play_bgm("bgm_scholarship")
	minigame_id = "scholarship"
	reward_amount = 5000 
	paper_ui.hide()
	result_layer.hide()
	tutorial_popup.show()
	start_button.pressed.connect(_on_start_pressed)
	load_questions()

func load_questions() -> void:
	var file = FileAccess.open("res://data/scholarship_questions.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			all_questions = json.data
		else:
			push_error("JSON Parse Error")
	else:
		push_error("Missing JSON file.")

func _on_start_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	tutorial_popup.hide()
	paper_ui.show()
	start_quiz()

func start_quiz() -> void:
	if all_questions.is_empty(): return
	all_questions.shuffle()
	active_questions = all_questions.slice(0, 10)
	current_question_index = 0
	score = 0
	_setup_option_connections()
	update_score_display()
	load_question(current_question_index)
	start_game()

func _setup_option_connections() -> void:
	var index = 0
	for button in options_container.get_children():
		if button is Button:
			if button.pressed.is_connected(_on_option_pressed):
				button.pressed.disconnect(_on_option_pressed)
			button.pressed.connect(_on_option_pressed.bind(index))
			index += 1

func load_question(index: int) -> void:
	if index >= active_questions.size():
		finish_quiz()
		return

	var q_data = active_questions[index]
	# The design shows the question text only. To show "Q1." again, use:
	# question_label.text = "Q" + str(index + 1) + ". " + q_data["question"]
	question_label.text = q_data["question"]
	var buttons = options_container.get_children()
	for i in range(buttons.size()):
		if buttons[i] is Button:
			if i < q_data["options"].size():
				buttons[i].text = q_data["options"][i]
				buttons[i].show()
			else:
				buttons[i].hide()

func _on_option_pressed(selected_index: int) -> void:
	var correct_index = int(active_questions[current_question_index]["answer_index"])
	
	if selected_index == correct_index:
		AudioManager.play_sfx("sfx_correct_ding")
		score += 1
	else:
		AudioManager.play_sfx("sfx_error_buzz")
		
	current_question_index += 1
	update_score_display()
	load_question(current_question_index)

func update_score_display() -> void:
	score_label.text = "Score: %d/10" % score

func finish_quiz() -> void:
	var passed: bool = score >= required_score
	RunState.scholarship_passed = passed
	if passed:
		AudioManager.play_sfx("sfx_coin_fountain")
	else:
		AudioManager.play_sfx("sfx_ear_ringing")
	_show_result(passed)
	await get_tree().create_timer(4.0).timeout
	finish_game(passed)

# Dims the screen and drops in the tilted result card
func _show_result(passed: bool) -> void:
	result_title.text = "PASSED" if passed else "FAILED"
	result_title.add_theme_color_override("font_color", TEAL if passed else ORANGE)
	result_score.text = "%d/10" % score
	if passed:
		result_message.text = "Scholarship secured!\nStipend added. Check your phone later."
	else:
		result_message.text = "Scholarship Denied!\nwithout this, tuition is impossible."

	result_layer.show()
	result_dimmer.modulate.a = 0.0
	result_card.modulate.a = 0.0
	result_card.scale = Vector2(0.7, 0.7)
	result_card.rotation_degrees = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(result_dimmer, "modulate:a", 1.0, 0.4)
	tw.tween_property(result_card, "modulate:a", 1.0, 0.25)
	tw.tween_property(result_card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(result_card, "rotation_degrees", -7.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
