extends Node2D

@onready var dialogue_box = $DialogueBox

func _ready() -> void:
	var dialogue_lines = []
	
	match GameState.current_part:
		3: # The night shift where you get paid
			GameState.receive_paycheck()
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Another night shift of staring at the wall." },
				{ "speaker": "System", "text": "[ Paycheck Received: ₱6,500 ]" },
				{ "speaker": "Dominador", "text": "₱16,000 total. The tuition is safe." },
				{ "speaker": "Dominador", "text": "The relief is making me crash. I can't fall asleep on shift." },
				{ "speaker": "Dominador", "text": "I've got an extra ₱1,000 sitting there." },
				{ "speaker": "Dominador", "text": "Just a few low bets to pass the time. Nothing crazy. I know when to stop." }
			]
			
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	GameState.advance_scene()
