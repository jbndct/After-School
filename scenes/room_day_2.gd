extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/street_day2.tscn"

func _ready() -> void:
	var dialogue_lines = []
	
	# Evaluate if the player retained enough money after the night shift
	if GameState.hand < 15000:
		dialogue_lines = [
			{ "speaker": "Dominador: ", "text": "Oh no, I gambled all my money." },
			{ "speaker": "Dominador: ", "text": "I can't enroll anymore." },
			{ "speaker": "Dominador: ", "text": "I broke everyone's trust." },
			{ "speaker": "Dominador: ", "text": "Who am I anymore?" }
		]
	else:
		dialogue_lines = [
			{ "speaker": "Dominador: ", "text": "I survived the night." },
			{ "speaker": "Dominador: ", "text": "I have ₱" + str(GameState.hand) + ". That's enough for tuition." },
			{ "speaker": "Dominador: ", "text": "I need to get to the registrar before it closes." }
		]
		
	dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
