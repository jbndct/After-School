extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/SugalHub.tscn"

func _ready() -> void:
	# Give the player their salary so they have the 1000 peso cushion
	GameState.receive_paycheck()
	
	dialogue_box.play([
	{ "speaker": "", "text": "Another night shift of staring at the wall." },
	{ "speaker": "", "text": "[ Paycheck Received: ₱6,500 ]" },
	{ "speaker": "", "text": "₱16,000 total. The tuition is safe." },
	{ "speaker": "", "text": "The relief is making me crash. I can't fall asleep on shift." },
	{ "speaker": "", "text": "I've got an extra ₱1,000 sitting there." },
	{ "speaker": "", "text": "Just a few low bets to pass the time. Nothing crazy. I know when to stop." }
], _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
