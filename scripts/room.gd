extends Node2D

@onready var dialogue_box = $DialogueBox

func _ready() -> void:
	var dialogue_lines = []
	
	match GameState.current_part:
		1: # Part 1: Start of the game (Previously Day 1)
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Tuition is ₱15,000. Deadline is today." },
				{ "speaker": "Dominador", "text": "Current balance: ₱2,000. Paycheck clearing tonight: ₱6,500." },
				{ "speaker": "Dominador", "text": "That's ₱8,500. I'm still drastically short." },
				{ "speaker": "Dominador", "text": "[ Text - Mama: Anak, pasensya na. Wala kaming maipadala para sa tuition mo ngayon. ]" },
				{ "speaker": "Dominador", "text": "I know, Ma. I'll figure it out." },
				{ "speaker": "Dominador", "text": "[ Text - Mark: Bro, check this link. SugalHub. Easiest money I ever made. ]" },
				{ "speaker": "Dominador", "text": "Mark has been pushing that sketchy app all week. Claimed he doubled his pay in ten minutes." },
				{ "speaker": "Dominador", "text": "It's a trap. I know it is." },
				{ "speaker": "Dominador", "text": "I just need to keep my head down, finish this night shift, and not do anything stupid." }
			]
		2: # Part 2: Looking for a job
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "I need to find a job today." } # Placeholder, add your own
			]
		3: # Part 3: Going to work
			dialogue_lines = [
				{ "speaker": "Dominador", "text": "Time to head to work." } # Placeholder, add your own
			]
		4: # Part 4: The morning after the night shift (Previously Day 2)
			if GameState.hand < 15000:
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "No... no, no, no. Where did it all go?" },
					{ "speaker": "Dominador", "text": "Balance: ₱" + str(GameState.hand) + ". This can't be right. I just had it." },
					{ "speaker": "Dominador", "text": "I was just trying to get the rest of the tuition. What did I just do?" },
					{ "speaker": "Dominador", "text": "How am I supposed to tell Ma? I'm completely screwed." }
				]
			else:
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Shift's finally over. My head is pounding." },
					{ "speaker": "Dominador", "text": "Total balance: ₱" + str(GameState.hand) + "." },
					{ "speaker": "Dominador", "text": "It's enough. I actually held on to it." },
					{ "speaker": "Dominador", "text": "I just need to drag myself to the registrar before I collapse." }
				]
				
	# Play the dialogue and pass the advance_scene function as the callback
	dialogue_box.play(dialogue_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	# Let the GameState figure out where to go next!
	GameState.advance_scene()
