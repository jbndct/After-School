extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/street_day2.tscn"

func _ready() -> void:
	var dialogue_lines = []
	
	# Evaluate if the player retained enough money after the night shift
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
		
	dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
