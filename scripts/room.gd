# res://scripts/room.gd
extends Node2D

@onready var player = $Player
@onready var objective_label = $Player/ObjectiveLabel
@onready var interact_prompt = $InteractableItem/InteractPrompt
@onready var door_prompt = $ExitDoor/DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false

func _ready() -> void:
	if RunState.previous_location == "street":
		player.global_position.x = 100 
		
	interact_prompt.visible = false
	door_prompt.visible = false
	
	if not DialogManager.dialog_finished.is_connected(_on_dialogue_finished):
		DialogManager.dialog_finished.connect(_on_dialogue_finished)
	
	update_objectives()

func update_objectives() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	var arrow = player.get_node_or_null("TutorialArrow")
	
	if not RunState.completed_dialogues.has(dialogue_id):
		objective_label.text = DialogManager.get_text("obj_room_clear_head")
		if arrow: arrow.set_target($InteractableItem)
	else:
		if phase == "morning":
			objective_label.text = DialogManager.get_text("obj_room_to_school")
			if arrow: arrow.set_target($ExitDoor)
		elif phase == "night":
			if RunState.has_meta("work_shift_done"):
				objective_label.text = DialogManager.get_text("obj_room_end_day")
				if arrow: arrow.set_target($ExitDoor)
			else:
				objective_label.text = DialogManager.get_text("obj_room_start_work")
				if arrow: arrow.set_target($InteractableItem)

func _unhandled_input(event: InputEvent) -> void:
	if DialogManager.is_dialog_active:
		return
		
	if event.is_action_pressed("interact"):
		if player_in_interact_zone:
			interact_prompt.visible = false
			trigger_interaction()
		elif player_at_door:
			var phase = RunState.current_phase
			var dialogue_id = "room_" + phase
			
			if RunState.completed_dialogues.has(dialogue_id):
				if phase == "night" and not RunState.has_meta("work_shift_done"):
					objective_label.text = DialogManager.get_text("warn_room_finish_shift")
					await get_tree().create_timer(2.0).timeout
					update_objectives()
					return
					
				var arrow = player.get_node_or_null("TutorialArrow")
				if arrow: arrow.set_target(null)
				SceneManager.advance_story("room")
			else:
				objective_label.text = DialogManager.get_text("warn_room_clear_head")
				await get_tree().create_timer(2.0).timeout
				update_objectives()

func trigger_interaction() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	
	if not RunState.completed_dialogues.has(dialogue_id):
		if player and "current_state" in player:
			player.current_state = player.State.LOCKED
			
		var json_id = "room_morning"
		if phase == "night":
			json_id = "room_night_passed" if RunState.scholarship_passed else "room_night_failed"
			
		DialogManager.start_world_dialog(json_id, player.global_position)
	else:
		if phase == "night":
			if RunState.has_meta("work_shift_done"):
				objective_label.text = DialogManager.get_text("warn_room_done_working")
				await get_tree().create_timer(2.0).timeout
				update_objectives()
			else:
				var arrow = player.get_node_or_null("TutorialArrow")
				if arrow: arrow.set_target(null)
				SceneManager.load_scene("work")
		elif phase == "morning":
			objective_label.text = DialogManager.get_text("warn_room_already_thought")
			await get_tree().create_timer(2.0).timeout
			update_objectives()

func _on_dialogue_finished() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	
	RunState.completed_dialogues[dialogue_id] = true
	if player and "current_state" in player:
		player.current_state = player.State.FREE
	update_objectives()
	
	if player_at_door:
		door_prompt.visible = true
	if player_in_interact_zone:
		interact_prompt.visible = true

func _on_interactable_item_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = true
		interact_prompt.visible = true

func _on_interactable_item_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = false
		interact_prompt.visible = false

func _on_exit_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = true
		if RunState.completed_dialogues.has("room_" + RunState.current_phase):
			door_prompt.visible = true

func _on_exit_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = false
		door_prompt.visible = false
