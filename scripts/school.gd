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
	# If we are in Part 1 and at Index 4, we just beat the Scholarship Minigame!
	if GameState.current_part == 1 and GameState.current_step_index == 4:
		has_talked = true
		objective_label.text = "Objective: Head back to the street."
		return # Stop reading here so it doesn't reset the objective

	# Normal first-visit setup
	match GameState.current_part:
		1: objective_label.text = "Objective: Take the scholarship exam."
		2: objective_label.text = "Objective: Check the bulletin board."
		3: objective_label.text = "Objective: Attend classes."
		4: objective_label.text = "Objective: Go to the registrar."

	# --- GLOBAL MEMORY CHECK ---
	# If we already talked for this specific step (e.g., returning from SugalHub)
	if GameState.step_dialogue_finished:
		has_talked = true
		objective_label.text = "Objective: Head back to the street."

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
				if is_inside_tree():
					_ready() # Reset objective text safely

func play_school_dialogue() -> void:
	var dialogue_lines = []
	match GameState.current_part:
		1:
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "The testing room. My entire semester hinges on a piece of paper." },
				{ "speaker": "Dominador", "text": "2,500 pesos. That's the stipend. It's barely a dent in the 15,000 I need, but it's a lifeline." },
				{ "speaker": "Dominador", "text": "Focus. Don't think about the empty wallet. Just answer the questions." }
			]
		2:
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Bulletin board. Let's see who's desperate enough to hire a student with zero free time." },
				{ "speaker": "Dominador", "text": "'Night Shift. 5,500 base pay.' ...It's going to absolutely destroy my sleep schedule." },
				{ "speaker": "Dominador", "text": "But 5,500 plus the scholarship, plus a loan from Pepito... it might just put me over the 15,000 line. I have to take it." }
			]
		3:
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "I can barely keep my eyes open in this lecture. The professor's voice is just background noise." },
				{ "speaker": "Dominador", "text": "My mind keeps recalculating the numbers. The loan, the upcoming paycheck, the daily 350 drain..." },
				{ "speaker": "Dominador", "text": "If I mess up the shift tonight, it's over. I just need to keep my eyes open." }
			]
		4:
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "The Registrar's Office. The end of the line." },
				{ "speaker": "Dominador", "text": "Three days of starving, begging for loans, and working until my bones ached." },
				{ "speaker": "Dominador", "text": "This is it. Let's find out if it was enough." }
			]
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	has_talked = true
	
	# If this is the scholarship exam day, instantly trigger the minigame!
	if GameState.current_part == 1 and GameState.current_step_index == 2:
		# Do NOT save step_dialogue_finished here, because we are leaving the scene 
		# for a required minigame progression step.
		GameState.advance_scene()
	else:
		# Otherwise, just let them walk out the door normally
		GameState.step_dialogue_finished = true # Mark it done for memory
		objective_label.text = "Objective: Head back to the street."
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
