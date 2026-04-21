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
	
	if GameState.step_dialogue_finished:
		has_talked = true
		if GameState.current_step_index == 0:
			objective_label.text = "Objective: Head out."

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
					{ "speaker": "Dominador", "text": "750 pesos left. Just looking at the number makes my stomach turn." },
					{ "speaker": "Dominador", "text": "Tuition is 15,000. And just getting out of bed, paying fare, and eating costs me 350 a day." },
					{ "speaker": "Dominador", "text": "I absolutely need to pass that scholarship exam today. The 2,500 stipend is the only way I survive the week." }
				]
			2:
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Another day, another 350 pesos gone to fare and food. The math isn't mathing." },
					{ "speaker": "Dominador", "text": "Even with the scholarship, I'm barely scraping by. I have to look for a job today." },
					{ "speaker": "Dominador", "text": "If I skip lunch, maybe I can stretch this further... no, I need the energy for the interviews." }
				]
			3:
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "My head is pounding. Pepito's 7,500 loan is sitting in my account, but it feels like a ball and chain." },
					{ "speaker": "Dominador", "text": "Between classes and the night shift tonight, I don't know when I'll sleep. But I need that paycheck." },
					{ "speaker": "Dominador", "text": "Just one night. I just have to survive one grueling shift." }
				]
			4:
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "The shift is over. My body is completely numb." },
					{ "speaker": "Dominador", "text": "The paycheck cleared, but after three days of bleeding 350 just to live... I need to check the math." },
					{ "speaker": "Dominador", "text": "Whatever the bank app says right now... decides my entire future. Time to head to the registrar." }
				]
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	has_talked = true
	GameState.step_dialogue_finished = true
	
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
