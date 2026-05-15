# res://scripts/poster.gd
extends Area2D

@onready var choice_ui = $ChoiceUI
@onready var btn_yes = $ChoiceUI/Panel/Margin/VBox/HBox/BtnYes
@onready var btn_no = $ChoiceUI/Panel/Margin/VBox/HBox/BtnNo
@onready var interact_prompt = $InteractPrompt

var player_ref: Node2D = null
var has_read_poster: bool = false # Tracks if the player already read the long intro

enum State { IDLE, READING_INTRO, WAITING_FOR_CHOICE, READING_OUTRO }
var current_state: State = State.IDLE

var intro_lines: Array[String] = [
	"SugalHub: Gawing milyon ang barya mo! Play now, approved by your favorite vloggers!",
	"Lahat ng kaklase ko, puro ganito ang inaatupag. Nakaka-pressure.",
	"Kung palaguin ko kaya 'tong 3,000 ko? Baka magkaroon ako ng 'breathing room'.",
	"Mababayaran ko yung 15,000 na tuition bukas nang hindi namamatay sa gutom kinabukasan...",
	"Pero paano kung matalo? Masisira yung sakto kong budget. Hindi ako makaka-enroll."
]

var repeat_lines: Array[String] = [
	"Yung SugalHub ad nanaman. Nakaka-tempt subukan para lumaki 'tong pera ko."
]

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
		start_interaction()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_ref = null

func start_interaction() -> void:
	current_state = State.READING_INTRO
	
	if player_ref and "current_state" in player_ref:
		player_ref.current_state = player_ref.State.LOCKED
		
	# Check if we should play the long intro or the short repeat line
	if has_read_poster:
		DialogManager.start_dialog(player_ref.global_position, repeat_lines)
	else:
		DialogManager.start_dialog(player_ref.global_position, intro_lines)
		has_read_poster = true

func _on_dialog_finished() -> void:
	if current_state == State.READING_INTRO:
		current_state = State.WAITING_FOR_CHOICE
		choice_ui.show()
		
	elif current_state == State.READING_OUTRO:
		current_state = State.IDLE
		if player_ref and "current_state" in player_ref:
			player_ref.current_state = player_ref.State.FREE

func _on_yes_pressed() -> void:
	choice_ui.hide()
	current_state = State.IDLE
	
	RunState.interruption_return_x = global_position.x
	SceneManager.load_scene("sugal")

func _on_no_pressed() -> void:
	choice_ui.hide()
	current_state = State.READING_OUTRO
	if is_instance_valid(player_ref):
		DialogManager.start_dialog(player_ref.global_position, outro_lines)
	else:
		DialogManager.start_dialog(global_position, outro_lines)
