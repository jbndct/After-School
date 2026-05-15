# res://scripts/school.gd
extends Node2D

@onready var player = $Player
@onready var objective_label = $Player/ObjectiveLabel
@onready var interact_prompt = $InteractableItem/InteractPrompt
@onready var door_prompt = $ExitDoor/DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false

# ==============================================================================
# MINIGAME BRIDGE DIALOGUE (Tagalog)
# ==============================================================================
var school_dialogue = {
	"arrival": [
		"Ito na yun. Yung registrar... Huling chance ko na 'to para sa stipend.",
		"Kailangan kong i-check yung bulletin board at mag-exam. Focus, Ador."
	],
	"passed": [
		"Pasa ako... Salamat sa Diyos. Secured na yung stipend.",
		"Malaking tulong 'to, pero may shift pa 'ko mamaya. Makauwi na nga."
	],
	"failed": [
		"Bagsak... Walang stipend.",
		"Hindi ko alam paano ko tatawirin 'to. Makauwi na nga lang."
	]
}

func _ready() -> void:
	if RunState.previous_location == "scholarship":
		player.global_position.x = 500 
	else:
		player.global_position.x = 100 

	interact_prompt.visible = false
	door_prompt.visible = false
	
	if not DialogManager.dialog_finished.is_connected(_on_dialogue_finished):
		DialogManager.dialog_finished.connect(_on_dialogue_finished)
		
	update_state()

func update_state() -> void:
	var arrow = player.get_node_or_null("TutorialArrow")
	
	if RunState.previous_location == "scholarship":
		objective_label.text = "Objective: Head back to the street."
		if arrow: arrow.set_target($ExitDoor)
		
		var result_key = "school_result"
		if not RunState.completed_dialogues.has(result_key):
			if player and "current_state" in player:
				player.current_state = player.State.LOCKED
			var lines: Array[String] = []
			if RunState.scholarship_passed:
				lines.assign(school_dialogue["passed"])
			else:
				lines.assign(school_dialogue["failed"])
			DialogManager.start_dialog(player.global_position, lines)
			RunState.completed_dialogues[result_key] = true
		else:
			_on_dialogue_finished()
			
	else:
		objective_label.text = "Objective: Take the scholarship exam at the board."
		if arrow: arrow.set_target($InteractableItem)
		
		var arrival_key = "school_arrival"
		if not RunState.completed_dialogues.has(arrival_key):
			if player and "current_state" in player:
				player.current_state = player.State.LOCKED
			var lines: Array[String] = []
			lines.assign(school_dialogue["arrival"])
			DialogManager.start_dialog(player.global_position, lines)
			RunState.completed_dialogues[arrival_key] = true
		else:
			_on_dialogue_finished()

func _unhandled_input(event: InputEvent) -> void:
	if DialogManager.is_dialog_active: return
	
	if event.is_action_pressed("interact"):
		if player_in_interact_zone:
			if RunState.previous_location != "scholarship":
				var arrow = player.get_node_or_null("TutorialArrow")
				if arrow: arrow.set_target(null)
				SceneManager.load_scene("scholarship")
			else:
				objective_label.text = "I already took the exam. Time to leave."
				await get_tree().create_timer(2.0).timeout
				update_state()
				
		elif player_at_door:
			if RunState.previous_location == "scholarship":
				var arrow = player.get_node_or_null("TutorialArrow")
				if arrow: arrow.set_target(null)
				SceneManager.advance_story("school")
			else:
				objective_label.text = "I can't leave without taking the exam."
				await get_tree().create_timer(2.0).timeout
				update_state()

func _on_dialogue_finished() -> void:
	if player and "current_state" in player:
		player.current_state = player.State.FREE
	if player_at_door and RunState.previous_location == "scholarship":
		door_prompt.visible = true
	if player_in_interact_zone and RunState.previous_location != "scholarship":
		interact_prompt.visible = true

func _on_interactable_item_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = true
		if RunState.previous_location != "scholarship":
			interact_prompt.visible = true

func _on_interactable_item_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = false
		interact_prompt.visible = false

func _on_exit_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = true
		if RunState.previous_location == "scholarship":
			door_prompt.visible = true

func _on_exit_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = false
		door_prompt.visible = false
