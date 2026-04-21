extends Control

@onready var question_label = $QuestionLabel
@onready var score_label = $ScoreLabel
@onready var options_container = $VBoxContainer

var all_questions = []
var active_questions = []
var current_question_index = 0
var score = 0
var required_score = 10 # Adjust passing grade here

func _ready():
	load_questions()
	setup_buttons()
	start_quiz()

func load_questions():
	var file = FileAccess.open("res://data/scholarship_questions.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			all_questions = json.data
		else:
			print("JSON Parse Error: ", json.get_error_message())
	else:
		print("Failed to load questions file.")

func setup_buttons():
	# Dynamically connect the 4 buttons inside the VBoxContainer
	var index = 0
	for button in options_container.get_children():
		if button is Button:
			# Bind the index so we know which button was pressed
			button.pressed.connect(_on_option_pressed.bind(index))
			index += 1

func start_quiz():
	all_questions.shuffle()
	# Grab exactly 15 questions (or whatever size the pool currently is, if less than 15)
	active_questions = all_questions.slice(0, min(15, all_questions.size()))
	current_question_index = 0
	score = 0
	update_score_display()
	load_question(current_question_index)

func load_question(index: int):
	if index >= active_questions.size():
		finish_quiz()
		return

	var q_data = active_questions[index]
	question_label.text = str(index + 1) + ". " + q_data["question"]
	
	var buttons = options_container.get_children()
	for i in range(buttons.size()):
		buttons[i].text = q_data["options"][i]

func _on_option_pressed(selected_index: int):
	var correct_index = int(active_questions[current_question_index]["answer_index"])
	
	if selected_index == correct_index:
		score += 1
		# Optional: Play correct sound effect or flash green here
	else:
		# Optional: Play wrong sound effect or flash red here
		pass
		
	update_score_display()
	
	# Move to next question
	current_question_index += 1
	load_question(current_question_index)

func update_score_display():
	score_label.text = "Score: %d / %d" % [score, active_questions.size()]

func finish_quiz():
	question_label.text = "Quiz Finished!\nYour Score: %d / %d" % [score, active_questions.size()]
	options_container.hide() # Hide options
	
	if score >= required_score:
		question_label.text += "\n\nPartial Scholarship Granted!"
		
		GameState.add_money(2500)
		
		# Wait 3 seconds so the player can read the text
		await get_tree().create_timer(3.0).timeout
		
		# Push the game progression forward normally
		GameState.advance_scene() 
		
	else:
		question_label.text += "\n\nYou failed to qualify. Without this, tuition is impossible..."
		
		# Wait 3 seconds so the dread sets in
		await get_tree().create_timer(3.0).timeout
		
		# --- NEW: Trigger the Global Failure State ---
		print("DEBUG: Minigame lost! failed_minigame is now: ", GameState.failed_minigame)
		GameState.failed_minigame = true
		
		# Since we updated GameState.gd earlier, calling advance_scene() 
		# while failed_minigame is TRUE will instantly boot them to the ending scene.
		GameState.advance_scene()
