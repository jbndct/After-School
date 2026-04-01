extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var objective_label = $ObjectiveLabel
@onready var interact_prompt = $InteractPrompt
@onready var door_prompt = $DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false
var has_talked: bool = false

func _ready() -> void:
	
	# --- DEBUG OVERRIDE: REMOVE THIS WHEN DONE TESTING ---
	GameState.current_part = 1
	GameState.current_step_index = 2 # This is the index for the School scene in Part 1
	# -----------------------------------------------------
	
	interact_prompt.visible = false
	door_prompt.visible = false
	
	# Set the initial objective based on the part
	match GameState.current_part:
		1: objective_label.text = "Objective: Take the scholarship exam."
		2: objective_label.text = "Objective: Check the bulletin board."
		3: objective_label.text = "Objective: Attend classes."
		4: objective_label.text = "Objective: Go to the registrar."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_in_interact_zone and not has_talked:
			interact_prompt.visible = false 
			play_school_dialogue()
		elif player_at_door:
			if has_talked:
				GameState.advance_scene()
			else:
				objective_label.text = "I need to finish what I came here for."
				await get_tree().create_timer(2.0).timeout
				_ready() # Reset objective text

func play_school_dialogue() -> void:
	var dialogue_lines = []
	
	match GameState.current_part:
		1: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "The scholarship exam is starting soon." },
				{ "speaker": "Dominador", "text": "If I pass this, I might not have to worry about the rest of the tuition." }
			]
		2: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Just checking the bulletin board for job postings." },
				{ "speaker": "Dominador", "text": "Nothing good today." }
			]
		3: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Classes are a blur when you're running on two hours of sleep." }
			]
		4: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "The registrar's office is just ahead." },
				{ "speaker": "Dominador", "text": "This is the moment of truth." }
			]
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	has_talked = true
	objective_label.text = "Objective: Head back to the street."
	
	if player_at_door:
		door_prompt.visible = true

# --- SIGNAL CALLBACKS ---
# These must match the node connections perfectly, just like in the room scene!

func _on_interactable_item_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not has_talked:
		player_in_interact_zone = true
		interact_prompt.visible = true

func _on_interactable_item_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = false
		interact_prompt.visible = false

func _on_exit_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = true
		if has_talked:
			door_prompt.visible = true

func _on_exit_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = false
		door_prompt.visible = false
