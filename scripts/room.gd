extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var objective_label = $Player/ObjectiveLabel
@onready var interact_prompt = $InteractableItem/InteractPrompt
@onready var door_prompt = $ExitDoor/DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false
var has_talked: bool = false

func _ready() -> void:
	interact_prompt.visible = false
	door_prompt.visible = false
	
	# --- TIME OF DAY CHECK ---
	if GameState.current_step_index != 0:
		objective_label.text = "Objective: Go to sleep."
	else:
		match GameState.current_part:
			1: objective_label.text = "Objective: Figure out what to do about tuition."
			2: objective_label.text = "Objective: Prepare to look for a job."
			3: objective_label.text = "Objective: Get ready for work."
			4: objective_label.text = "Objective: Check your balance."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_in_interact_zone and not has_talked:
			interact_prompt.visible = false 
			play_room_dialogue()
		elif player_at_door:
			if has_talked:
				GameState.advance_scene()
			else:
				objective_label.text = "I shouldn't leave until I clear my head."
				await get_tree().create_timer(2.0).timeout
				_ready()

func play_room_dialogue() -> void:
	var dialogue_lines = []
	
	# --- NIGHT TIME DIALOGUE ---
	if GameState.current_step_index != 0:
		dialogue_lines = [
			{ "speaker": "Dominador", "text": "Finally home. I'm completely drained." },
			{ "speaker": "Dominador", "text": "I just need to crash. Tomorrow is another day." }
		]
	else:
		# --- MORNING DIALOGUE ---
		match GameState.current_part:
			1: 
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
			2: 
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Morning already... I feel like I got hit by a jeepney." },
					{ "speaker": "Dominador", "text": "Still drastically short on the tuition." },
					{ "speaker": "Dominador", "text": "I need to find a second job today. Any side gig will do." },
					{ "speaker": "Dominador", "text": "[ Text - Mark: Bro, you're missing out. Just pulled 3k from SugalHub while brushing my teeth. ]" },
					{ "speaker": "Dominador", "text": "He's going to lose it all eventually. I just need to ignore him and focus on finding real work." }
				]
			3: 
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Three hours of sleep. A new personal record." },
					{ "speaker": "Dominador", "text": "Night shift starts soon. My body is running entirely on cheap coffee and panic." },
					{ "speaker": "Dominador", "text": "The deadline is closing in. The pressure is starting to mess with my head." },
					{ "speaker": "Dominador", "text": "Just need to clock in, stare at the wall, and secure that paycheck." }
				]
			4: 
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "This is it. The registrar's office opens in an hour." },
					{ "speaker": "Dominador", "text": "Let me check the bank app one last time to see where my balance stands." },
					{ "speaker": "Dominador", "text": "Whatever happens today... I made my choices." },
					{ "speaker": "Dominador", "text": "Time to head out and face the music." }
				]
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	has_talked = true
	
	# If it's night, instantly go to the next day!
	if GameState.current_step_index != 0:
		GameState.advance_scene()
	else:
		objective_label.text = "Objective: Head out."
		if player_at_door:
			door_prompt.visible = true

# --- SIGNAL CALLBACKS ---
func _on_interactable_item_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not has_talked:
		player_in_interact_zone = true
		interact_prompt.visible = true

func _on_interactable_item_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = false
		interact_prompt.visible = false

func _on_exit_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = true
		if has_talked and GameState.current_step_index == 0:
			door_prompt.visible = true

func _on_exit_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = false
		door_prompt.visible = false
