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
	# GameState.current_part = 2
	# GameState.current_step_index = 4 # This is the index for Workplace in Part 2
	# -----------------------------------------------------

	interact_prompt.visible = false
	door_prompt.visible = false
	
	match GameState.current_part:
		2: objective_label.text = "Objective: Do the job interview."
		3: objective_label.text = "Objective: Work the night shift."
		_: objective_label.text = "Objective: Talk to the manager."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_in_interact_zone and not has_talked:
			interact_prompt.visible = false 
			play_workplace_dialogue()
		elif player_at_door:
			if has_talked:
				GameState.advance_scene()
			else:
				objective_label.text = "I need to clock in first."
				await get_tree().create_timer(2.0).timeout
				_ready() # Reset objective text

func play_workplace_dialogue() -> void:
	var dialogue_lines = []
	
	match GameState.current_part:
		2: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "I'm here for the night guard position." },
				{ "speaker": "Dominador", "text": "I just need to get through this interview." }
			]
		3: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Another night shift of staring at the wall." },
				{ "speaker": "System", "text": "[ Paycheck Received: ₱6,500 ]" },
				{ "speaker": "Dominador", "text": "₱16,000 total. The tuition is safe." },
				{ "speaker": "Dominador", "text": "The relief is making me crash. I can't fall asleep on shift." },
				{ "speaker": "Dominador", "text": "I've got an extra ₱1,000 sitting there." },
				{ "speaker": "Dominador", "text": "Just a few low bets to pass the time. Nothing crazy. I know when to stop." }
			]
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	has_talked = true
	objective_label.text = "Objective: Head back out."
	
	# Give the player their money if it's Part 3
	if GameState.current_part == 3 and not GameState.paycheck_received_flag:
		GameState.receive_paycheck()
	
	if player_at_door:
		door_prompt.visible = true

# --- SIGNAL CALLBACKS ---

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
