extends Node2D

@onready var dialogue_box = $DialogueBox

func _ready() -> void:
	var dialogue_lines = []
	
	match GameState.current_part:
		1: # Assuming Pepito loan happens in Part 1
			dialogue_lines = [
				{ "speaker": "PEPITO", "text": "Magkano ba talaga ang kulang mo para maka-enroll?" },
				{ "speaker": "Dominador", "text": "₱6,500 pa. Pare, nahihiya na ako. Pang-ilang beses na 'to." },
				{ "speaker": "PEPITO", "text": "Hayaan mo na. Padalhan kita ng ₱7,500 para may sobra ka pang-kain." },
				{ "speaker": "Dominador", "text": "PEPITO, ipon mo 'to para sa anak mo. Babayaran ko agad next cut-off, pangako." },
				{ "speaker": "System", "text": "[ E-Pera: ₱7,500 received ]" },
				{ "speaker": "PEPITO", "text": "Mag-aral ka na lang nang mabuti. 'Wag mong sayangin 'to." }
			]
		2: # Add your Part 2 school logic here
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Just passing by the school today." }
			]
	
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	if GameState.current_part == 1:
		GameState.receive_pepito_loan() 
		
	GameState.advance_scene()
