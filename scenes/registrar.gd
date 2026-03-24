extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/ending.tscn"

func _ready() -> void:
	var dialogue_lines = []
	
	# Check if they have enough money for tuition
	if GameState.hand < 15000:
		dialogue_lines = [
			{ "speaker": "REGISTRAR", "text": "Good morning. Tuition payment?" },
			{ "speaker": "", "text": "..." },
			{ "speaker": "", "text": "The phone. The balance. The number. It is not enough." },
			{ "speaker": "REGISTRAR", "text": "I'm sorry. Without full payment we can't enroll you this semester."},
			{ "speaker": "FRIEND", "text": "Ginamble mo ba yung binigay ko sayo? Bakit mo yun ginawa?"},
			{ "speaker": "FRIEND", "text": "Don't talk to me. We're done."}
			
			]
	else:
		dialogue_lines = [
			{ "speaker": "REGISTRAR", "text": "Good morning. Tuition payment?" },
			{ "speaker": "KUYA", "text": "Po. ₱15,000." },
			{ "speaker": "", "text": "[ ₱15,000 sent ]" },
			{ "speaker": "REGISTRAR", "text": "You're enrolled. Good luck this semester." }
		]
		
	dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
