extends Node2D

@onready var player = $Player
@onready var objective_label = $Player/ObjectiveLabel
@onready var interact_prompt = $InteractableItem/InteractPrompt
@onready var door_prompt = $ExitDoor/DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false

# ==============================================================================
# MINIGAME BRIDGE DIALOGUE
# ==============================================================================
var school_dialogue = {
	"arrival": [
		"The testing room. My entire semester hinges on a piece of paper.",
		"I need to check the bulletin board and start the exam."
	],
	"passed": [
		"I passed... The stipend is secured.",
		"It's a relief, but I still have my shift tonight. Time to head home."
	],
	"failed": [
		"I failed. No stipend.",
		"I don't know how I'm going to survive. Let's just go home."
	]
}

func _ready() -> void:
	# 1. SPATIAL ROUTING
	if RunState.previous_location == "scholarship":
		player.global_position.x = 500 # Adjust to put him near the bulletin board
	else:
		player.global_position.x = 100 # Adjust to put him near the entrance door

	interact_prompt.visible = false
	door_prompt.visible = false
	
	# 2. CONNECT DIALOG MANAGER
	if not DialogManager.dialog_finished.is_connected(_on_dialogue_finished):
		DialogManager.dialog_finished.connect(_on_dialogue_finished)
		
	update_state()

func update_state() -> void:
	if RunState.previous_location == "scholarship":
		# We just finished the minigame
		objective_label.text = "Objective: Head back to the street."
		var result_key = "school_result"
		
		if not RunState.completed_dialogues.has(result_key):
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
		# We just arrived from the street
		objective_label.text = "Objective: Take the scholarship exam at the board."
		var arrival_key = "school_arrival"
		
		if not RunState.completed_dialogues.has(arrival_key):
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
				# Start the exam!
				SceneManager.load_scene("scholarship")
			else:
				objective_label.text = "I already took the exam. Time to leave."
				await get_tree().create_timer(2.0).timeout
				update_state()
				
		elif player_at_door:
			if RunState.previous_location == "scholarship":
				SceneManager.advance_story("school")
			else:
				objective_label.text = "I can't leave without taking the exam."
				await get_tree().create_timer(2.0).timeout
				update_state()

func _on_dialogue_finished() -> void:
	player.current_state = player.State.FREE
	if player_at_door and RunState.previous_location == "scholarship":
		door_prompt.visible = true
	if player_in_interact_zone and RunState.previous_location != "scholarship":
		interact_prompt.visible = true

# ==============================================================================
# TRIGGER ZONES
# ==============================================================================

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
