extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var objective_label = $ObjectiveLabel

# We don't have CanvasModulate in your uploaded tree, so I removed it to prevent crashes.
# If you add one later, you can put the time-of-day logic back in!

var current_door: String = ""
var expected_destination: String = ""
var base_objective: String = ""
var has_talked: bool = false

func _ready() -> void:
	# --- DEBUG OVERRIDE: REMOVE THIS WHEN DONE TESTING ---
	GameState.current_part = 1
	GameState.current_step_index = 1
	# -----------------------------------------------------
	# Hide your built-in entrance labels by default
	$HomeEntrance/Label.visible = false
	$JobEntrance/Label.visible = false
	$SchoolEntrance/Label.visible = false
	setup_street_state()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_door != "" and has_talked:
		if current_door == expected_destination:
			# They picked the right door! Let GameState load the next scene.
			GameState.advance_scene()
		else:
			# Wrong door
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
				dialogue_lines = [{ "speaker": "Dominador", "text": "If I don't pass this scholarship exam, I'm getting dropped." }]
			elif GameState.current_step_index == 4:
				expected_destination = "home"
				base_objective = "Objective: Head home."
				dialogue_lines = [{ "speaker": "Dominador", "text": "Finally done. Need to head home." }]
		2:
			if GameState.current_step_index == 1:
				expected_destination = "job" # Assuming he walks the street to find jobs
				base_objective = "Objective: Find a job."
				dialogue_lines = [{ "speaker": "Dominador", "text": "Another day. Need to find work." }]
			elif GameState.current_step_index == 3:
				expected_destination = "job"
				base_objective = "Objective: Go to the interview."
				dialogue_lines = [{ "speaker": "Dominador", "text": "Time for the interview. Hope I don't mess this up." }]
			elif GameState.current_step_index == 6:
				expected_destination = "home"
				base_objective = "Objective: Head home."
				dialogue_lines = [{ "speaker": "Dominador", "text": "Exhausted. Let's just go home." }]
		# Add Part 3 and 4 logic following the exact same pattern
				
	objective_label.text = base_objective
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	has_talked = true
	# If they are already standing at a door when dialogue ends, show the prompt
	if current_door == "home": $HomeEntrance/Label.visible = true
	elif current_door == "job": $JobEntrance/Label.visible = true
	elif current_door == "school": $SchoolEntrance/Label.visible = true

# --- SIGNAL CALLBACKS ---

func _on_home_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "home"
		if has_talked: $HomeEntrance/Label.visible = true

func _on_home_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		$HomeEntrance/Label.visible = false

func _on_job_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "job"
		if has_talked: $JobEntrance/Label.visible = true

func _on_job_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		$JobEntrance/Label.visible = false

func _on_school_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "school"
		if has_talked: $SchoolEntrance/Label.visible = true

func _on_school_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		$SchoolEntrance/Label.visible = false
