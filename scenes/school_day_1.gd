extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/street_day_1_evening.tscn"

func _ready() -> void:
	dialogue_box.play([
	{ "speaker": "PEPITO", "text": "Magkano ba talaga ang kulang mo para maka-enroll?" },
	{ "speaker": "JUAN", "text": "₱6,500 pa. Pare, nahihiya na ako. Pang-ilang beses na 'to." },
	{ "speaker": "PEPITO", "text": "Hayaan mo na. Padalhan kita ng ₱7,500 para may sobra ka pang-kain." },
	{ "speaker": "JUAN", "text": "PEPITO, ipon mo 'to para sa anak mo. Babayaran ko agad next cut-off, pangako." },
	{ "speaker": "", "text": "[ E-Pera: ₱7,500 received ]" },
	{ "speaker": "PEPITO", "text": "Mag-aral ka na lang nang mabuti. 'Wag mong sayangin 'to." }
], _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	# This injects the 7500 into the global state before the next scene
	GameState.receive_PEPITO_loan() 
	get_tree().change_scene_to_file(NEXT_SCENE)
