extends MinigameBase

@onready var dialogue_box = $DialogueBox

var work_dialogue = [
	"The call center shift starts now.",
	"Just keep typing. Don't look at the clock.",
	"5,500 pesos. That's the goal."
]

func setup_game() -> void:
	minigame_id = "work"
	reward_amount = 5500
	
	start_game()
	
	if dialogue_box:
		dialogue_box.play(work_dialogue, Callable(self, "_on_intro_dialogue_finished"))
	else:
		_on_intro_dialogue_finished()

func _on_intro_dialogue_finished() -> void:
	# Add your typing minigame logic here later.
	# For now, it auto-completes to ensure the game loop doesn't break.
	simulate_typing_shift()

func simulate_typing_shift() -> void:
	await get_tree().create_timer(2.0).timeout
	if dialogue_box:
		dialogue_box.play(["Shift completed. The paycheck cleared."], Callable(self, "_on_shift_completed"))
	else:
		_on_shift_completed()

func _on_shift_completed() -> void:
	finish_game(true)
