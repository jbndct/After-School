extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var objective_label = $Player/ObjectiveLabel

# Grab the labels safely right when the scene loads
@onready var home_label = $HomeEntrance/Label
@onready var job_label = $JobEntrance/Label
@onready var school_label = $SchoolEntrance/Label

var current_door: String = ""
var expected_destination: String = ""
var base_objective: String = ""
var has_talked: bool = false

func _ready() -> void:
	# Hide all labels safely on startup
	if home_label: home_label.visible = false
	if job_label: job_label.visible = false
	if school_label: school_label.visible = false
	setup_street_state()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_door != "" and has_talked:
		if current_door == expected_destination:
			# They picked the right door! Let GameState load the next scene.
			GameState.advance_scene()
		else:
			# Wrong door
			if objective_label:
				objective_label.text = "I don't need to go there right now."
				await get_tree().create_timer(2.0).timeout
				objective_label.text = base_objective

func setup_street_state() -> void:
	var dialogue_lines = []
	
	match GameState.current_part:
		1:
			if GameState.current_step_index == 1:
				expected_destination = "school"
				base_objective = "Objective: Get to school for the exam."
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "If I don't pass this scholarship exam, the 15,000 tuition is impossible." }
				]
			elif GameState.current_step_index == 5:
				expected_destination = "home"
				base_objective = "Objective: Head home."
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Stipend secured, but my wallet is still bleeding 350 a day for food and fare." }
				]
		2:
			if GameState.current_step_index == 1:
				expected_destination = "school" 
				base_objective = "Objective: Find a job."
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "The 2,500 stipend isn't enough. I have to find work today." }
				]
			elif GameState.current_step_index == 3:
				expected_destination = "job"
				base_objective = "Objective: Go to the interview."
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "A night guard shift paying 5,500. I cannot afford to mess this up." }
				]
			elif GameState.current_step_index == 7: 
				expected_destination = "home"
				base_objective = "Objective: Head home."
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "I got the job, but doing the math... I'm still going to be short." },
					{ "speaker": "Dominador", "text": "I'm going to have to swallow my pride and message Pepito for a loan tonight." }
				]
		3:
			if GameState.current_step_index == 1:
				expected_destination = "school"
				base_objective = "Objective: Go to class."
				
				# --- NEW: TRIGGER THE LOAN HERE ---
				if GameState.loan_from_pepito == 0:
					GameState.receive_pepito_loan()
					
				dialogue_lines = [
					{ "speaker": "System", "text": "[ E-Pera Transfer Received: ₱7,500 from Pepito ]" },
					{ "speaker": "Dominador", "text": "The loan hit my account. I'm drowning in debt, but it keeps me in school." }
				]
			elif GameState.current_step_index == 3:
				expected_destination = "job"
				base_objective = "Objective: Head to the night shift."
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "If I survive tonight's shift, the 5,500 paycheck clears. It has to be enough." }
				]
			elif GameState.current_step_index == 7: 
				expected_destination = "home"
				base_objective = "Objective: Go home and rest."
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "I can't feel my legs. Just get to the bed." }
				]
		4:
			if GameState.current_step_index == 1:
				expected_destination = "school"
				base_objective = "Objective: Head to the registrar."
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "The final walk. Time to see if the math worked out." }
				]
				
	if objective_label:
		objective_label.text = base_objective
	else:
		print("ERROR: objective_label is missing! Did you add it to the scene?")
		
		# If we already talked for this step, skip the dialogue box entirely
	if GameState.step_dialogue_finished:
		has_talked = true
		_on_dialogue_finished() # Triggers the door UI if you're standing near one
		return 
				
	if dialogue_lines.size() > 0:
		if dialogue_box:
			print("SUCCESS: DialogueBox found. Playing dialogue now!")
			dialogue_box.play(dialogue_lines, _on_dialogue_finished)
		else:
			print("ERROR: dialogue_box is missing! You forgot to instantiate the DialogueBox scene!")
			_on_dialogue_finished()
	else:
		print("WARNING: No dialogue lines matched this part/step combo.")
		_on_dialogue_finished()
	print("------------------")

func _on_dialogue_finished() -> void:
	has_talked = true
	GameState.step_dialogue_finished = true
	
	# If they are already standing at a door when dialogue ends, show the prompt safely
	if current_door == "home" and home_label: home_label.visible = true
	elif current_door == "job" and job_label: job_label.visible = true
	elif current_door == "school" and school_label: school_label.visible = true

# --- SIGNAL CALLBACKS ---

func _on_home_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "home"
		if has_talked and home_label: home_label.visible = true

func _on_home_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if home_label: home_label.visible = false

func _on_job_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "job"
		if has_talked and job_label: job_label.visible = true

func _on_job_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if job_label: job_label.visible = false

func _on_school_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "school"
		if has_talked and school_label: school_label.visible = true

func _on_school_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if school_label: school_label.visible = false
