extends Node2D

@onready var dialogue_box = $DialogueBox
const NEXT_SCENE = "res://scenes/menu.tscn"

func _ready() -> void:
	var dialogue_lines = []
	
	# Check if they have enough money for tuition
	if GameState.hand < 15000:
		dialogue_lines = [
	{ "speaker": "REGISTRAR", "text": "Next. Payment for Juan? You're still short." },
	{ "speaker": "JUAN", "text": "...I had it. I swear, I had the full amount last night." },
	{ "speaker": "REGISTRAR", "text": "The system doesn't care about 'almost,' Mr. Juan. Without the balance, your slot is forfeited. Please step out of the line." },
	{ "speaker": "JUAN", "text": "(My chest feels tight... I haven't slept in forty hours. My hands won't stop shaking. Was one more spin worth my degree?)" },
	{ "speaker": "MAMA (Text)", "text": "Anak, did you pay the tuition? I'm so proud of you for working so hard. God bless." },
	{ "speaker": "JUAN", "text": "(I can't even reply. I've become a ghost in my own home. I stole her peace of mind for a digital jackpot that never dropped.)" },
	{ "speaker": "PEPITO", "text": "I checked the group chat, Juan. You blocked everyone because you couldn't pay us back, didn't you?" },
	{ "speaker": "PEPITO", "text": "Ginamble mo ba yung pang-tuition mo? After everything we did to help you? You’re pathetic. Don't ever call me again." },
	{ "speaker": "JUAN", "text": "(The screen blinks in my pocket. A new notification from SugalHub: 'We miss you! Here is ₱50 free bet.' It’s the only thing I have left.)" }
]
	else:
		dialogue_lines = [
			{ "speaker": "REGISTRAR", "text": "Good morning. Tuition payment?" },
			{ "speaker": "KUYA", "text": "Here po. ₱15,000." },
			{ "speaker": "", "text": "[ ₱15,000 sent ]" },
			{ "speaker": "REGISTRAR", "text": "You're enrolled. Good luck this semester." }
		]
		
	dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
