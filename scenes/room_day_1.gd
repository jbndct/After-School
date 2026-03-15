extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/street_day_1_morning.tscn"

func _ready() -> void:
	dialogue_box.play([
		{ "speaker": "", "text": "Tuition: ₱15,000." },
		{ "speaker": "", "text": "I have ₱2,000. Paycheck tonight is ₱6,500." },
		{ "speaker": "", "text": "Deadline is today." }
	], _on_dialogue_finished) # Pass the function as a callback

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
