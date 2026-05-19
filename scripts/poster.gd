# res://scripts/poster.gd
extends Area2D

@onready var choice_ui = $ChoiceUI
@onready var btn_yes = $ChoiceUI/Panel/Margin/VBox/HBox/BtnYes
@onready var btn_no = $ChoiceUI/Panel/Margin/VBox/HBox/BtnNo
@onready var interact_prompt = $InteractPrompt

var player_ref: Node2D = null

enum State { IDLE, READING_INTRO, WAITING_FOR_CHOICE, READING_OUTRO }
var current_state: State = State.IDLE

func _ready() -> void:
	choice_ui.hide()
	
	if is_instance_valid(interact_prompt):
		interact_prompt.hide()
	
	btn_yes.focus_mode = Control.FOCUS_NONE
	btn_no.focus_mode = Control.FOCUS_NONE
	
	btn_yes.pressed.connect(_on_yes_pressed)
	btn_no.pressed.connect(_on_no_pressed)
	
	if not DialogManager.dialog_finished.is_connected(_on_dialog_finished):
		DialogManager.dialog_finished.connect(_on_dialog_finished)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and current_state == State.IDLE:
		player_ref = body
		
		var phase = RunState.current_phase
		var read_key = "poster_read_" + phase
		
		if not RunState.completed_dialogues.has(read_key):
			start_interaction(false)
		else:
			if is_instance_valid(interact_prompt):
				interact_prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = null
		if is_instance_valid(interact_prompt):
			interact_prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.IDLE:
		return
		
	var phase = RunState.current_phase
	var read_key = "poster_read_" + phase
	
	if player_ref and RunState.completed_dialogues.has(read_key) and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		start_interaction(true)

func start_interaction(is_repeat: bool) -> void:
	current_state = State.READING_INTRO
	var phase = RunState.current_phase
	
	if is_instance_valid(interact_prompt):
		interact_prompt.hide()
	
	if player_ref and "current_state" in player_ref:
		player_ref.current_state = player_ref.State.LOCKED
		
	if phase not in ["morning", "afternoon"]:
		phase = "morning"
		
	var dialog_id = ""
	if is_repeat:
		dialog_id = "poster_repeat_" + phase
	else:
		RunState.completed_dialogues["poster_read_" + phase] = true
		dialog_id = "poster_intro_" + phase
		
	DialogManager.start_world_dialog(dialog_id, player_ref.global_position)

func _on_dialog_finished() -> void:
	if current_state == State.READING_INTRO:
		current_state = State.WAITING_FOR_CHOICE
		choice_ui.show()
		
	elif current_state == State.READING_OUTRO:
		current_state = State.IDLE
		if player_ref and "current_state" in player_ref:
			player_ref.current_state = player_ref.State.FREE
		
		if player_ref != null and is_instance_valid(interact_prompt):
			interact_prompt.show()

func _on_yes_pressed() -> void:
	choice_ui.hide()
	current_state = State.IDLE
	RunState.interruption_return_x = global_position.x
	
	GameState.last_scene_path = get_tree().current_scene.scene_file_path
	SceneManager.load_scene("sugal")

func _on_no_pressed() -> void:
	choice_ui.hide()
	current_state = State.READING_OUTRO
	var target_pos = player_ref.global_position if is_instance_valid(player_ref) else global_position
	DialogManager.start_world_dialog("poster_outro", target_pos)
