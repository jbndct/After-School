# res://scripts/street.gd
extends Node2D

@onready var player = $Player
@onready var objective_label = $Player/ObjectiveLabel

@onready var home_label = $HomeEntrance/Label
@onready var job_label = $JobEntrance/Label
@onready var school_label = $SchoolEntrance/Label

# Use get_node_or_null so the game doesn't crash if you forget to place an arrow
@onready var home_arrow = $HomeEntrance.get_node_or_null("TutorialArrow")
@onready var job_arrow = $JobEntrance.get_node_or_null("TutorialArrow")
@onready var school_arrow = $SchoolEntrance.get_node_or_null("TutorialArrow")

var current_door: String = ""
var expected_destination: String = ""

# ==============================================================================
# PHASE-BASED DIALOGUE
# ==============================================================================
var street_dialogue = {
	"morning": [
		"Kailangan kong pumasa sa exam. Walang palya dapat.",
		"Lahat ng nakakasabay ko sa jeep, sugal ang nasa screen. Nakaka-pressure na pakiramdam ko ako na lang ang nahuhuli sa ganitong diskarte."
	],
	"afternoon": [
		"Tapos na yung exam. Hihintayin ko na lang yung 7,000 ko mamaya sa trabaho.",
		"Wala akong magawa ngayon. Bored na bored ako. Siguro kung i-download ko yung app, may pampalipas oras ako..."
	]
}

func _ready() -> void:
	# 1. SPATIAL ROUTING
	if RunState.interruption_return_x != 0.0:
		player.global_position.x = RunState.interruption_return_x
		RunState.interruption_return_x = 0.0 
	else:
		if RunState.previous_location == "room":
			player.global_position.x = -1500
		elif RunState.previous_location == "school" or RunState.previous_location == "work":
			player.global_position.x = 1100
			
	# 2. HIDE DOOR LABELS
	if home_label: home_label.visible = false
	if job_label: job_label.visible = false
	if school_label: school_label.visible = false
	
	# 3. CONNECT DIALOG MANAGER
	if not DialogManager.dialog_finished.is_connected(_on_dialogue_finished):
		DialogManager.dialog_finished.connect(_on_dialogue_finished)
		
	setup_street_state()

func setup_street_state() -> void:
	var phase = RunState.current_phase
	
	# Hide all arrows initially to reset state
	if home_arrow: home_arrow.hide()
	if job_arrow: job_arrow.hide()
	if school_arrow: school_arrow.hide()
	
	# Set Target Door & Show the correct arrow
	if phase == "morning":
		expected_destination = "school"
		objective_label.text = "Objective: Head to school."
		if school_arrow: school_arrow.show()
			
	elif phase == "afternoon":
		expected_destination = "home"
		objective_label.text = "Objective: Head back to the dorm."
		if home_arrow: home_arrow.show()

	var dialogue_id = "street_" + phase
	
	# Play Intro Dialogue
	if not RunState.completed_dialogues.has(dialogue_id) and street_dialogue.has(phase):
		player.current_state = player.State.LOCKED
		var lines: Array[String] = []
		lines.assign(street_dialogue[phase])
		DialogManager.start_dialog(player.global_position, lines)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	var dialogue_id = "street_" + RunState.current_phase
	RunState.completed_dialogues[dialogue_id] = true
	if player and "current_state" in player:
		player.current_state = player.State.FREE
	
	# Refresh door prompt if they are standing next to one
	if current_door == "home" and home_label: home_label.visible = true
	elif current_door == "job" and job_label: job_label.visible = true
	elif current_door == "school" and school_label: school_label.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if DialogManager.is_dialog_active: return
	
	if event.is_action_pressed("interact") and current_door != "":
		if current_door == expected_destination:
			SceneManager.advance_story("street")
		else:
			objective_label.text = "I don't need to go there right now."
			await get_tree().create_timer(2.0).timeout
			setup_street_state() # Resets the label back to the correct objective

# ==============================================================================
# TRIGGER ZONES (Hiding arrows on entry)
# ==============================================================================

func _on_home_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "home"
		if home_arrow: home_arrow.hide() # Disappear when touching the door
		if RunState.completed_dialogues.has("street_" + RunState.current_phase) and home_label: 
			home_label.visible = true

func _on_home_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if home_label: home_label.visible = false
		if expected_destination == "home" and home_arrow: 
			home_arrow.show() # Reappear if they walk away without entering

func _on_job_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "job"
		if job_arrow: job_arrow.hide()
		if RunState.completed_dialogues.has("street_" + RunState.current_phase) and job_label: 
			job_label.visible = true

func _on_job_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if job_label: job_label.visible = false
		if expected_destination == "job" and job_arrow: 
			job_arrow.show()

func _on_school_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "school"
		if school_arrow: school_arrow.hide()
		if RunState.completed_dialogues.has("street_" + RunState.current_phase) and school_label: 
			school_label.visible = true

func _on_school_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if school_label: school_label.visible = false
		if expected_destination == "school" and school_arrow: 
			school_arrow.show()
