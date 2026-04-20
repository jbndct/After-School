extends Control

@onready var dialogue_box = $DialogueBox

func _ready() -> void:
	# Add a tiny half-second delay so it doesn't instantly jump scare the player with text
	await get_tree().create_timer(0.5).timeout
	evaluate_ending()

func evaluate_ending() -> void:
	var final_story = ""
	
	if GameState.failed_minigame:
		final_story = "You succumbed to the pressure. Unable to balance the grueling demands of work and school, you failed to graduate on time."
	elif GameState.has_gambled:
		if GameState.gambling_profit > 0:
			final_story = "You made the money and graduated. But the thrill of the win never left. You spent the rest of your life chasing that high, trapped in a relentless cycle of addiction..."
		else:
			final_story = "You lost it all at the Sugal Hub. Without tuition, graduation slipped away. Desperate to win it back, you spiraled into a deep addiction. The house always wins."
	else:
		final_story = "You survived. It was exhausting, but you kept your head down, did the honest work, and graduated. Everyone is proud. You are finally free."

	# Format the text for your existing dialogue system. 
	# Leaving the speaker blank or naming it "System" or "Fate" works well here.
	var dialogue_lines = [
		{ "speaker": "", "text": final_story }
	]
	
	# Play the dialogue, and call our function when they click through it
	dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	GameState.reset() # Wipe the flags clean
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
