extends Node2D

@onready var dialogue_box = $DialogueBox

var player_in_interact_zone: bool = false
var has_talked: bool = false

func _ready() -> void:
	# We leave this empty now. The player must trigger the dialogue manually.
	pass

# Listens for the interact button
func _input(event: InputEvent) -> void:
	if player_in_interact_zone and not has_talked and event.is_action_pressed("ui_accept"):
		play_room_dialogue()

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
		2: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "I need to find a job today." } 
			]
		3: 
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Time to head to work." } 
			]
		4: 
			if GameState.hand < 15000:
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "No... no, no, no. Where did it all go?" },
					{ "speaker": "Dominador", "text": "Balance: ₱" + str(GameState.hand) + ". This can't be right. I just had it." },
					{ "speaker": "Dominador", "text": "I was just trying to get the rest of the tuition. What did I just do?" },
					{ "speaker": "Dominador", "text": "How am I supposed to tell Ma? I'm completely screwed." }
				]
			else:
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Shift's finally over. My head is pounding." },
					{ "speaker": "Dominador", "text": "Total balance: ₱" + str(GameState.hand) + "." },
					{ "speaker": "Dominador", "text": "It's enough. I actually held on to it." },
					{ "speaker": "Dominador", "text": "I just need to drag myself to the registrar before I collapse." }
				]
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	has_talked = true # Unlocks the door

# --- SIGNAL CALLBACKS ---

func _on_interactable_item_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = true

func _on_interactable_item_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = false

func _on_exit_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if has_talked:
			GameState.advance_scene()
		else:
			print("Player needs to interact first!") # Just for testing so you can see it in the console
