extends Node2D

@onready var dialogue_box = $DialogueBox

func _ready() -> void:
	dialogue_box.play([
		{ "speaker": "", "text": "Tuition: ₱15,000." },
		{ "speaker": "", "text": "I have ₱2,000. Paycheck tonight is ₱6,500." },
		{ "speaker": "", "text": "Deadline is today." }
	])
