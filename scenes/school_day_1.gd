extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/street_day_1_evening.tscn"

func _ready() -> void:
	dialogue_box.play([
		{ "speaker": "DANTE", "text": "Magkano kulang mo?" },
		{ "speaker": "KUYA", "text": "₱6,500. Hindi ko alam kung saan kukuhanin." },
		{ "speaker": "DANTE", "text": "Padalhan na kita ng ₱7,500. Para may sobra ka pa." },
		{ "speaker": "", "text": "[ E-Pera: ₱7,500 received ]" },
		{ "speaker": "DANTE", "text": "Alam mo naman na magtitiwala ako sayo." }
	], _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	# This injects the 7500 into the global state before the next scene
	GameState.receive_dante_loan() 
	get_tree().change_scene_to_file(NEXT_SCENE)
