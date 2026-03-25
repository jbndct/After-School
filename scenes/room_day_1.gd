extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/street_day_1_morning.tscn"

func _ready() -> void:
	dialogue_box.play([
	{ "speaker": "", "text": "Tuition is ₱15,000. Deadline is today." },
	{ "speaker": "", "text": "Current balance: ₱2,000. Paycheck clearing tonight: ₱6,500." },
	{ "speaker": "", "text": "That's ₱8,500. I'm still drastically short." },
	{ "speaker": "", "text": "[ Text - Mama: Anak, pasensya na. Wala kaming maipadala para sa tuition mo ngayon. ]" },
	{ "speaker": "", "text": "I know, Ma. I'll figure it out." },
	{ "speaker": "", "text": "[ Text - Mark: Bro, check this link. SugalHub. Easiest money I ever made. ]" },
	{ "speaker": "", "text": "Mark has been pushing that sketchy app all week. Claimed he doubled his pay in ten minutes." },
	{ "speaker": "", "text": "It's a trap. I know it is." },
	{ "speaker": "", "text": "I just need to keep my head down, finish this night shift, and not do anything stupid." }
], _on_dialogue_finished) # Pass the function as a callback

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
