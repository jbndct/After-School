# res://scripts/scholarship_minigame.gd
extends MinigameBase

@onready var paper_ui = $Paper
@onready var question_label = $Paper/MarginContainer/QuizLayout/QuestionLabel
@onready var score_label = $Paper/MarginContainer/QuizLayout/ScoreLabel
@onready var options_container = $Paper/MarginContainer/QuizLayout/OptionsContainer

@onready var tutorial_popup = $TutorialPopup
@onready var start_button = $TutorialPopup/VBoxContainer/StartButton

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
	question_label.text = "Q" + str(index + 1) + ". " + q_data["question"]
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
	score_label.text = "Score: %d / 10" % score

func finish_quiz() -> void:
	options_container.hide() 
	if score >= required_score:
		AudioManager.play_sfx("sfx_coin_fountain")
		RunState.scholarship_passed = true
		question_label.text = "EXAM COMPLETE\n\nFinal Score: %d / 10\n\nStatus: PASSED.\nStipend secured. Check your phone later." % score
		question_label.add_theme_color_override("font_color", Color.DARK_GREEN)
		await get_tree().create_timer(3.5).timeout
		finish_game(true) 
	else:
		AudioManager.play_sfx("sfx_ear_ringing")
		RunState.scholarship_passed = false
		question_label.text = "EXAM COMPLETE\n\nFinal Score: %d / 10\n\nStatus: FAILED.\nScholarship denied. Without this, tuition is impossible..." % score
		question_label.add_theme_color_override("font_color", Color.DARK_RED)
		await get_tree().create_timer(3.5).timeout
		finish_game(false)
