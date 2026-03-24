extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/SugalHub.tscn"

func _ready() -> void:
	# Give the player their salary so they have the 1000 peso cushion
	GameState.receive_paycheck()
	
	dialogue_box.play([
		{ "speaker": "", "text": "Eight hours. Just me and the logbook." },
		{ "speaker": "", "text": "[ Paycheck Received: ₱6,500 ]" },
		{ "speaker": "", "text": "Total balance: ₱16,000. Tuition is ₱15,000." },
		{ "speaker": "", "text": "I have ₱1,000 to spare. And a lot of time to kill. Boringgggg"}
	], _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
