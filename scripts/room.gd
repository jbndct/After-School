# res://scripts/room.gd
extends Node2D

@onready var player = $Player
@onready var objective_label = $Player/ObjectiveLabel
@onready var interact_prompt = $InteractableItem/InteractPrompt
@onready var door_prompt = $ExitDoor/DoorPrompt

var player_in_interact_zone: bool = false
var player_at_door: bool = false

var room_dialogue = {
	"morning": [
		"3,000 pesos. Ito na lang ang laman ng wallet ko.",
		"15,000 ang tuition. Kung papasa ako sa scholarship exam mamaya, may 5,000 ako.",
		"Tapos makukuha ko mamayang gabi yung 7,000 na sweldo ko para sa dalawang linggong shift.",
		"Saktong 15,000. Pambayad lang talaga. Saktong zero ang maiiwan para makakain ako bukas.",
		"Napanood ko sa vlog ni idol kagabi, nanalo daw siya ng 10k sa SugalHub habang naka-tambay lang. Nakaka-tempt subukan para lang magkaroon ng breathing room."
	],
	"night": [] # Populated dynamically in _ready()
}

func _ready() -> void:
	_setup_night_dialogue()
	
	if RunState.previous_location == "street":
		player.global_position.x = 100 
		
	interact_prompt.visible = false
	door_prompt.visible = false
	
	if not DialogManager.dialog_finished.is_connected(_on_dialogue_finished):
		DialogManager.dialog_finished.connect(_on_dialogue_finished)
	
	update_objectives()

func _setup_night_dialogue() -> void:
	var night_lines: Array[String] = []
	
	night_lines.append("*Phone buzzes*")
	
	if RunState.scholarship_passed:
		night_lines.append("SMS: Congratulations, your scholarship application is approved. You have officially been granted ₱5,000.")
		night_lines.append("Salamat. May 5k na 'ko. Idagdag ko yung 7k na sweldo mamaya, saktong 15k na.")
		night_lines.append("Mababayaran ko yung tuition... pero paano ako bukas? Nakakapagod na 'tong saktong-sakto lagi.")
	else:
		night_lines.append("SMS: We regret to inform you that you did not pass the scholarship exam.")
		night_lines.append("...Wala na. Kahit makuha ko pa yung 7k na sweldo ko mamaya, kulang na kulang ang pera ko.")
		night_lines.append("...Kailangan ko ba sumugal para sa kinabukasan ko?")
		
	night_lines.append("Kailangan ko nang mag-log in sa shift. Sobrang nakaka-bore yung routine na 'to, pero kailangan.")
	
	room_dialogue["night"] = night_lines

func update_objectives() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	
	if not RunState.completed_dialogues.has(dialogue_id):
		objective_label.text = "Objective: Clear my head first (Interact with desk/bed)."
	else:
		if phase == "morning":
			objective_label.text = "Objective: Head to school for the exam."
		elif phase == "night":
			objective_label.text = "Objective: Open laptop to start work shift."

func _unhandled_input(event: InputEvent) -> void:
	if DialogManager.is_dialog_active:
		return
		
	if event.is_action_pressed("interact"):
		if player_in_interact_zone:
			interact_prompt.visible = false
			trigger_interaction()
		elif player_at_door:
			var phase = RunState.current_phase
			var dialogue_id = "room_" + phase
			
			# Gatekeeper: Cannot leave until dialogue is read
			if RunState.completed_dialogues.has(dialogue_id):
				SceneManager.advance_story("room")
			else:
				objective_label.text = "I shouldn't leave until I clear my head."
				await get_tree().create_timer(2.0).timeout
				update_objectives()

func trigger_interaction() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	
	if not RunState.completed_dialogues.has(dialogue_id) and room_dialogue.has(phase):
		# Lock player movement and start talking
		player.current_state = player.State.LOCKED
		var lines: Array[String] = []
		lines.assign(room_dialogue[phase])
		DialogManager.start_dialog(player.global_position, lines)
	else:
		# If dialogue is already finished, trigger secondary interactions
		if phase == "night":
			# Laptop interaction routes to the minigame
			SceneManager.load_scene("work")
		elif phase == "morning":
			objective_label.text = "I already thought about this. I should head out."
			await get_tree().create_timer(2.0).timeout
			update_objectives()

func _on_dialogue_finished() -> void:
	var phase = RunState.current_phase
	var dialogue_id = "room_" + phase
	
	RunState.completed_dialogues[dialogue_id] = true
	player.current_state = player.State.FREE
	update_objectives()
	
	if player_at_door:
		door_prompt.visible = true
	if player_in_interact_zone:
		interact_prompt.visible = true

func _on_interactable_item_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = true
		interact_prompt.visible = true

func _on_interactable_item_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_interact_zone = false
		interact_prompt.visible = false

func _on_exit_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = true
		if RunState.completed_dialogues.has("room_" + RunState.current_phase):
			door_prompt.visible = true

func _on_exit_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = false
		door_prompt.visible = false
