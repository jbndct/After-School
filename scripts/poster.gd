# res://scripts/poster.gd
extends Area2D

@onready var choice_ui = $ChoiceUI
@onready var btn_yes = $ChoiceUI/Panel/Margin/VBox/HBox/BtnYes
@onready var btn_no = $ChoiceUI/Panel/Margin/VBox/HBox/BtnNo
@onready var interact_prompt = $InteractPrompt

var player_ref: Node2D = null

enum State { IDLE, READING_INTRO, WAITING_FOR_CHOICE, READING_OUTRO }
var current_state: State = State.IDLE

# --- PHASE-BASED DIALOGUE DICTIONARIES ---
var intro_lines = {
	"morning": [
		"SugalHub: Gawing milyon ang barya mo! Play now, approved by your favorite vloggers!",
		"Aga-aga, ito agad bubungad. Pati yung mga nakasabay ko sa jeep kanina, spin nang spin sa phone nila.",
		"Kung palaguin ko kaya 'tong 3,000 ko bago ako pumasok? Baka sakaling magkaroon ako ng 'breathing room'.",
		"Mababayaran ko yung 15,000 na tuition bukas nang hindi namamatay sa gutom kinabukasan...",
		"Pero paano kung matalo? Masisira yung sakto kong budget. Hindi ako makaka-take ng exam."
	],
	"afternoon": [
		"SugalHub: Doblehin ang pera mo habang naghihintay! Wala nang talo!",
		"Tapos na yung exam. Habang nag-aantay pumasok sa shift mamayang gabi, sobrang nakaka-bore.",
		"Baka kung i-download ko yung app, may pampalipas oras ako. Malay mo, swertehin.",
		"Kahit paano madagdagan yung budget ko. Hirap ng puro saktong-sakto lang palagi.",
		"Pero delikado. Baka maubos yung naipon ko. Hindi ko mapapatawad sarili ko."
	]
}

var repeat_lines = {
	"morning": [
		"Yung SugalHub ad. Nakaka-tempt subukan, pero kailangan ko munang pumasa sa exam."
	],
	"afternoon": [
		"SugalHub nanaman. Magandang pampalipas oras sana... pero baka kung saan pa mapunta."
	]
}

var outro_lines: Array[String] = [
	"Hindi. Kailangan kong mag-focus sa ngayon."
]

func _ready() -> void:
	choice_ui.hide()
	
	if is_instance_valid(interact_prompt):
		interact_prompt.hide()
	
	btn_yes.focus_mode = Control.FOCUS_NONE
	btn_no.focus_mode = Control.FOCUS_NONE
	
	btn_yes.pressed.connect(_on_yes_pressed)
	btn_no.pressed.connect(_on_no_pressed)
	
	if not DialogManager.dialog_finished.is_connected(_on_dialog_finished):
		DialogManager.dialog_finished.connect(_on_dialog_finished)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and current_state == State.IDLE:
		player_ref = body
		
		var phase = RunState.current_phase
		var read_key = "poster_read_" + phase
		
		# Kung hindi pa nababasa sa current phase na ito, auto-trigger.
		if not RunState.completed_dialogues.has(read_key):
			start_interaction(false)
		else:
			# Kapag nabasa na sa phase na ito, ipakita na lang ang E prompt.
			if is_instance_valid(interact_prompt):
				interact_prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = null
		if is_instance_valid(interact_prompt):
			interact_prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.IDLE:
		return
		
	var phase = RunState.current_phase
	var read_key = "poster_read_" + phase
	
	# Payagan ang manual interaction kung nabasa na ang auto-trigger
	if player_ref and RunState.completed_dialogues.has(read_key) and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		start_interaction(true)

func start_interaction(is_repeat: bool) -> void:
	current_state = State.READING_INTRO
	var phase = RunState.current_phase
	
	if is_instance_valid(interact_prompt):
		interact_prompt.hide()
	
	if player_ref and "current_state" in player_ref:
		player_ref.current_state = player_ref.State.LOCKED
		
	# Fallback just in case phase isn't setup correctly
	if not intro_lines.has(phase):
		phase = "morning"
		
	# CRITICAL FIX: Convert generic Array to strictly typed Array[String]
	var lines_to_play: Array[String] = []
		
	if is_repeat:
		lines_to_play.assign(repeat_lines[phase])
	else:
		# Save this to RunState so it never auto-triggers again for this specific phase
		RunState.completed_dialogues["poster_read_" + phase] = true
		lines_to_play.assign(intro_lines[phase])
		
	DialogManager.start_dialog(player_ref.global_position, lines_to_play)

func _on_dialog_finished() -> void:
	if current_state == State.READING_INTRO:
		current_state = State.WAITING_FOR_CHOICE
		choice_ui.show()
		
	elif current_state == State.READING_OUTRO:
		current_state = State.IDLE
		if player_ref and "current_state" in player_ref:
			player_ref.current_state = player_ref.State.FREE
		
		# Ipakita muli ang E prompt pagkatapos piliin ang 'No' kung nakatayo pa rin sa poster
		if player_ref != null and is_instance_valid(interact_prompt):
			interact_prompt.show()

func _on_yes_pressed() -> void:
	choice_ui.hide()
	current_state = State.IDLE
	RunState.interruption_return_x = global_position.x
	
	# I-save ang kasalukuyang scene (street) para makabalik nang maayos
	GameState.last_scene_path = get_tree().current_scene.scene_file_path
	
	SceneManager.load_scene("sugal")

func _on_no_pressed() -> void:
	choice_ui.hide()
	current_state = State.READING_OUTRO
	if is_instance_valid(player_ref):
		DialogManager.start_dialog(player_ref.global_position, outro_lines)
	else:
		DialogManager.start_dialog(global_position, outro_lines)
