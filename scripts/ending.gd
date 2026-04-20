extends Control

@onready var dialogue_box = $DialogueBox

func _ready() -> void:
	# Add a tiny half-second delay before the text starts
	await get_tree().create_timer(0.5).timeout
	evaluate_ending()

func evaluate_ending() -> void:
	var dialogue_lines = []
	
	if GameState.failed_minigame:
		# Ending A: Failed the pressure
		dialogue_lines = [
			{ "speaker": "System", "text": "The exhaustion finally caught up to you." },
			{ "speaker": "Dominador", "text": "I couldn't keep my eyes open. My body just gave out." },
			{ "speaker": "System", "text": "You missed your shift. The paycheck never came." },
			{ "speaker": "Dominador", "text": "All that starving, all that hustling... and I fell short." },
			{ "speaker": "System", "text": "Without the 15,000 for tuition, the registrar turned you away." },
			{ "speaker": "Dominador", "text": "I'm sorry. I just couldn't do it." }
		]
	elif GameState.has_gambled:
		if GameState.gambling_profit > 0:
			# Ending B: Gambled, Won, Addicted
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "The screen flashed. The E-Pera balance skyrocketed." },
				{ "speaker": "System", "text": "You walked into the registrar's office and paid the tuition in full." },
				{ "speaker": "Dominador", "text": "I did it. I graduated. I should be happy." },
				{ "speaker": "Dominador", "text": "But walking across that stage... all I could think about was the spin." },
				{ "speaker": "System", "text": "The thrill never left. You spent the rest of your life chasing that high." },
				{ "speaker": "System", "text": "Trapped in a relentless cycle of addiction. You won the battle, but lost yourself." }
			]
		else:
			# Ending C: Gambled, Lost, Addicted
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "No... no, no, no. Give it back." },
				{ "speaker": "System", "text": "The Sugal Hub drained your account. The money was gone." },
				{ "speaker": "Dominador", "text": "I just needed a quick win. Just 50 pesos..." },
				{ "speaker": "System", "text": "Without the tuition money, graduation slipped through your fingers." },
				{ "speaker": "Dominador", "text": "I can win it back. I just need another loan. Just one more spin..." },
				{ "speaker": "System", "text": "You spiraled into a deep addiction. The house always wins." }
			]
	else:
		# Ending D: The Clean Run (The Zero-Sum Survival)
		dialogue_lines = [
			{ "speaker": "Dominador", "text": "Here it is. Exactly 15,000 pesos." },
			{ "speaker": "System", "text": "The registrar stamped your papers. You are officially cleared to graduate." },
			{ "speaker": "Dominador", "text": "It's over. I actually survived." },
			{ "speaker": "System", "text": "You open your E-Pera app one last time." },
			{ "speaker": "System", "text": "[ Balance: ₱0 | Outstanding Debt to Pepito: ₱7,500 ]" },
			{ "speaker": "Dominador", "text": "I'm starting my professional life completely broke and buried in debt." },
			{ "speaker": "Dominador", "text": "But I kept my soul intact. It's time to get a real job." }
		]

	# Play the multi-line array
	dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	GameState.reset() 
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
