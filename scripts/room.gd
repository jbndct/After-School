extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var objective_label = $ObjectiveLabel
@onready var interact_prompt = $InteractPrompt
@onready var door_prompt = $DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false
var has_talked: bool = false

func _ready() -> void:
	# Hide interaction prompts by default
	interact_prompt.visible = false
	door_prompt.visible = false
	
	# Set the initial objective based on the part
	match GameState.current_part:
		1: objective_label.text = "Objective: Figure out what to do about tuition."
		2: objective_label.text = "Objective: Prepare to look for a job."
		3: objective_label.text = "Objective: Get ready for work."
		4: objective_label.text = "Objective: Check your balance."

# Use _unhandled_input so the dialogue box gets priority if it's open
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_in_interact_zone and not has_talked:
			# Hide the prompt once they interact
			interact_prompt.visible = false 
			play_room_dialogue()
		elif player_at_door:
			if has_talked:
				GameState.advance_scene()
			else:
				# Temporarily change objective text to warn the player
				objective_label.text = "I shouldn't leave until I clear my head."
				await get_tree().create_timer(2.0).timeout
				_ready() # Reset objective text

func play_room_dialogue() -> void:
	var dialogue_lines = []
	
	match GameState.current_part:
		1: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Tuition is ₱15,000. Deadline is today." },
				{ "speaker": "Dominador", "text": "Current balance: ₱2,000. Paycheck clearing tonight: ₱6,500." },
				{ "speaker": "Dominador", "text": "That's ₱8,500. I'm still drastically short." },
				{ "speaker": "Dominador", "text": "[ Text - Mama: Anak, pasensya na. Wala kaming maipadala para sa tuition mo ngayon. ]" },
				{ "speaker": "Dominador", "text": "I know, Ma. I'll figure it out." },
				{ "speaker": "Dominador", "text": "[ Text - Mark: Bro, check this link. SugalHub. Easiest money I ever made. ]" },
				{ "speaker": "Dominador", "text": "Mark has been pushing that sketchy app all week. Claimed he doubled his pay in ten minutes." },
				{ "speaker": "Dominador", "text": "It's a trap. I know it is." },
				{ "speaker": "Dominador", "text": "I just need to keep my head down, finish this night shift, and not do anything stupid." }
			]
		# (Keep your other match cases 2, 3, 4 the exact same as before)
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	has_talked = true
	objective_label.text = "Objective: Head out."
	
	# If they are already standing at the door when the dialogue finishes
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
		# Only show the exit prompt if they've finished the mandatory interaction
		if has_talked:
			door_prompt.visible = true

func _on_exit_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = false
		door_prompt.visible = false
