extends Node2D

@onready var player = $Player
@onready var objective_label = $Player/ObjectiveLabel
@onready var interact_prompt = $InteractableItem/InteractPrompt
@onready var door_prompt = $ExitDoor/DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false

# ==============================================================================
# PHASE-BASED DIALOGUE DATA (Speech Bubbles)
# ==============================================================================
var room_dialogue = {
	"morning": [
		"750 pesos left. Just looking at the number makes my stomach turn.",
		"Tuition is 15,000. And just getting out of bed, paying fare, and eating costs me 350 a day.",
		"I absolutely need to pass that scholarship exam today. The stipend is my only lifeline."
	],
	"night": [
		"Finally home. My body is completely numb.",
		"I just need to finish this call center shift and crash."
	]
}

func _ready() -> void:
	# 1. SPATIAL ROUTING
	if RunState.previous_location == "street":
		player.global_position.x = 100 # Near the door
		
	# 2. HIDE UI PROMPTS
	interact_prompt.visible = false
	door_prompt.visible = false
	
	# 3. CONNECT DIALOG MANAGER
	if not DialogManager.dialog_finished.is_connected(_on_dialogue_finished):
		DialogManager.dialog_finished.connect(_on_dialogue_finished)
	
	update_objectives()

func update_objectives() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	
	if not RunState.completed_dialogues.has(dialogue_id):
		objective_label.text = "Objective: Clear my head first (Interact with desk/bed)."
	else:
		if phase == "morning":
			objective_label.text = "Objective: Head to school for the exam."
		elif phase == "night":
			objective_label.text = "Objective: Open laptop to start work shift."

# ==============================================================================
# INPUT HANDLING
# ==============================================================================

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
			
			# Gatekeeper: Cannot leave until dialogue is read
			if RunState.completed_dialogues.has(dialogue_id):
				SceneManager.advance_story("room")
			else:
				objective_label.text = "I shouldn't leave until I clear my head."
				await get_tree().create_timer(2.0).timeout
				update_objectives()

func trigger_interaction() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	
	if not RunState.completed_dialogues.has(dialogue_id) and room_dialogue.has(phase):
		# Lock player movement and start talking
		player.current_state = player.State.LOCKED 
		var lines: Array[String] = []
		lines.assign(room_dialogue[phase])
		DialogManager.start_dialog(player.global_position, lines)
	else:
		# If dialogue is already finished, trigger secondary interactions
		if phase == "night":
			# Laptop interaction routes to the minigame
			SceneManager.load_scene("work")
		elif phase == "morning":
			objective_label.text = "I already thought about this. I should head out."
			await get_tree().create_timer(2.0).timeout
			update_objectives()

func _on_dialogue_finished() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	
	RunState.completed_dialogues[dialogue_id] = true
	player.current_state = player.State.FREE
	update_objectives()
	
	if player_at_door:
		door_prompt.visible = true
	if player_in_interact_zone:
		interact_prompt.visible = true

# ==============================================================================
# TRIGGER ZONES
# ==============================================================================

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
