extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var objective_label = $Player/ObjectiveLabel
@onready var interact_prompt = $InteractableItem/InteractPrompt
@onready var door_prompt = $ExitDoor/DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false
var has_talked: bool = false

func _ready() -> void:
	interact_prompt.visible = false
	door_prompt.visible = false
	
	# --- POST-MINIGAME CHECK ---
	# Index 6 is the return point after both Workplace minigames
	if (GameState.current_part == 2 and GameState.current_step_index == 6) or \
	   (GameState.current_part == 3 and GameState.current_step_index == 6):
		has_talked = true
		objective_label.text = "Objective: Head back out."
		return

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
				_ready()

func play_workplace_dialogue() -> void:
	var dialogue_lines = []
	match GameState.current_part:
		2: dialogue_lines = [
				{ "speaker": "Dominador", "text": "I'm here for the night guard position." },
				{ "speaker": "Dominador", "text": "I don't care about the hours. I just desperately need the 5,500." }
			]
		3: dialogue_lines = [
				{ "speaker": "Dominador", "text": "I am literally falling asleep standing up. Just stare at the wall." },
				{ "speaker": "System", "text": "[ Paycheck Received: ₱5,500 ]" },
				{ "speaker": "Dominador", "text": "It cleared. Okay, let's run the final calculation..." },
				{ "speaker": "Dominador", "text": "550 to start. Add the 2,500 stipend, the 7,500 loan, and this 5,500 paycheck." },
				{ "speaker": "Dominador", "text": "Minus the 1,050 I bled over the last three days for food and fare..." },
				{ "speaker": "Dominador", "text": "15,000. Exactly. Down to the very last peso." },
				{ "speaker": "Dominador", "text": "The tuition is safe. I can graduate." },
				{ "speaker": "Dominador", "text": "But my bank account is at zero, and I owe Pepito 7,500. I'm starting my life buried in debt." },
				{ "speaker": "Dominador", "text": "The Sugal Hub is right there on my phone. One lucky spin and I could clear the debt entirely. Just one spin..." }
			]
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	has_talked = true
	
	# --- MINIGAME TRIGGERS ---
	if GameState.current_part == 2 and GameState.current_step_index == 4:
		GameState.advance_scene() # Instantly go to Interview Minigame
	elif GameState.current_part == 3 and GameState.current_step_index == 4:
		if not GameState.paycheck_received_flag:
			GameState.receive_paycheck()
		GameState.advance_scene() # Instantly go to Work Minigame
	else:
		objective_label.text = "Objective: Head back out."
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
