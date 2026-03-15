extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/street_day2.tscn"

func _ready() -> void:
	dialogue_box.play([
		{ "speaker": "", "text": "Oh no, I gambled all my money." },
		{ "speaker": "", "text": "I can't enroll anymore" },
		{ "speaker": "", "text": "I broke everyone's trust." },
		{ "speaker": "", "text": "Who am I anymore?" }
	], _on_dialogue_finished) # Pass the function as a callback

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
