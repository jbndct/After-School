extends MinigameBase

@onready var question_label = $QuestionLabel
@onready var score_label = $ScoreLabel
@onready var options_container = $VBoxContainer

var all_questions = []
var active_questions = []
var current_question_index = 0
var score = 0
var required_score = 10

func setup_game() -> void:
	minigame_id = "scholarship"
	reward_amount = 2500
	
	if options_container:
		for child in options_container.get_children():
			child.hide()
			
	load_questions()
	setup_buttons()
	start_quiz()

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
		push_error("Missing JSON file. Using fallback questions.")
		all_questions = [
			{"question": "What does CPU stand for?", "options": ["Central Process Unit", "Computer Personal Unit", "Central Processing Unit", "Control Processing Unit"], "answer_index": 2},
			{"question": "What is an array?", "options": ["A function", "A data structure", "A variable", "A loop"], "answer_index": 1}
		]

func setup_buttons() -> void:
	if not options_container: return
	var index = 0
	for button in options_container.get_children():
		if button is Button:
			button.show()
			if button.pressed.is_connected(_on_option_pressed):
				button.pressed.disconnect(_on_option_pressed)
			button.pressed.connect(_on_option_pressed.bind(index))
			index += 1

func start_quiz() -> void:
	if all_questions.is_empty(): return
	all_questions.shuffle()
	active_questions = all_questions.slice(0, min(15, all_questions.size()))
	current_question_index = 0
	score = 0
	update_score_display()
	load_question(current_question_index)
	
	start_game()

func load_question(index: int) -> void:
	if index >= active_questions.size():
		finish_quiz()
		return

	var q_data = active_questions[index]
	if question_label:
		question_label.text = str(index + 1) + ". " + q_data["question"]
	
	if options_container:
		var buttons = options_container.get_children()
		for i in range(buttons.size()):
			if buttons[i] is Button and i < q_data["options"].size():
				buttons[i].text = q_data["options"][i]

func _on_option_pressed(selected_index: int) -> void:
	var correct_index = int(active_questions[current_question_index]["answer_index"])
	if selected_index == correct_index:
		score += 1
	update_score_display()
	current_question_index += 1
	load_question(current_question_index)

func update_score_display() -> void:
	if score_label:
		score_label.text = "Score: %d / %d" % [score, active_questions.size()]

func finish_quiz() -> void:
	if question_label:
		question_label.text = "Quiz Finished!\nYour Score: %d / %d" % [score, active_questions.size()]
	
	if options_container:
		options_container.hide() 
	
	if score >= required_score:
		if question_label:
			question_label.text += "\n\nPartial Scholarship Granted!"
		await get_tree().create_timer(3.0).timeout
		finish_game(true) 
	else:
		if question_label:
			question_label.text += "\n\nYou failed to qualify. Without this, tuition is impossible..."
		await get_tree().create_timer(3.0).timeout
		finish_game(false)
