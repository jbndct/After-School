# res://scripts/street.gd
extends Node2D

@onready var player = $Player
@onready var objective_label = $Player/ObjectiveLabel

@onready var home_label = $HomeEntrance/Label
@onready var job_label = $JobEntrance/Label
@onready var school_label = $SchoolEntrance/Label

var current_door: String = ""
var expected_destination: String = ""

func _ready() -> void:
	if RunState.interruption_return_x != 0.0:
		player.global_position.x = RunState.interruption_return_x
		RunState.interruption_return_x = 0.0 
	else:
		if RunState.previous_location == "room":
			player.global_position.x = -1500
		elif RunState.previous_location == "school" or RunState.previous_location == "work":
			player.global_position.x = 1100
			
	if home_label: home_label.visible = false
	if job_label: job_label.visible = false
	if school_label: school_label.visible = false
	
	if not DialogManager.dialog_finished.is_connected(_on_dialogue_finished):
		DialogManager.dialog_finished.connect(_on_dialogue_finished)
		
	setup_street_state()

func setup_street_state() -> void:
	var phase = RunState.current_phase
	var arrow = player.get_node_or_null("TutorialArrow") 
	
	if phase == "morning":
		expected_destination = "school"
		objective_label.text = DialogManager.get_text("obj_street_school")
		if arrow: arrow.set_target($SchoolEntrance)
			
	elif phase == "afternoon":
		expected_destination = "home"
		objective_label.text = DialogManager.get_text("obj_street_dorm")
		if arrow: arrow.set_target($HomeEntrance)

	var dialogue_id = "street_" + phase
	
	if not RunState.completed_dialogues.has(dialogue_id) and phase in ["morning", "afternoon"]:
		player.current_state = player.State.LOCKED
		DialogManager.start_world_dialog(dialogue_id, player.global_position)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	var dialogue_id = "street_" + RunState.current_phase
	RunState.completed_dialogues[dialogue_id] = true
	if player and "current_state" in player:
		player.current_state = player.State.FREE
	
	if current_door == "home" and home_label: home_label.visible = true
	elif current_door == "job" and job_label: job_label.visible = true
	elif current_door == "school" and school_label: school_label.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if DialogManager.is_dialog_active: return
	
	if event.is_action_pressed("interact") and current_door != "":
		if current_door == expected_destination:
			var arrow = player.get_node_or_null("TutorialArrow")
			if arrow: arrow.set_target(null)
			
			SceneManager.advance_story("street")
		else:
			objective_label.text = DialogManager.get_text("warn_street_wrong_way")
			await get_tree().create_timer(2.0).timeout
			setup_street_state()

func _on_home_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "home"
		if RunState.completed_dialogues.has("street_" + RunState.current_phase) and home_label: home_label.visible = true

func _on_home_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if home_label: home_label.visible = false

func _on_job_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "job"
		if RunState.completed_dialogues.has("street_" + RunState.current_phase) and job_label: job_label.visible = true

func _on_job_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if job_label: job_label.visible = false

func _on_school_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = "school"
		if RunState.completed_dialogues.has("street_" + RunState.current_phase) and school_label: school_label.visible = true

func _on_school_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_door = ""
		if school_label: school_label.visible = false
