# res://scripts/poster.gd
extends Area2D

@onready var choice_ui = $ChoiceUI
@onready var btn_yes = $ChoiceUI/Panel/Margin/VBox/HBox/BtnYes
@onready var btn_no = $ChoiceUI/Panel/Margin/VBox/HBox/BtnNo
@onready var interact_prompt = $InteractPrompt

var player_in_zone: bool = false
var player_ref: Node2D = null

enum State { IDLE, READING_INTRO, WAITING_FOR_CHOICE, READING_OUTRO }
var current_state: State = State.IDLE

var intro_lines: Array[String] = [
	"SugalHub: Gawing milyon ang barya mo! Play now, approved by your favorite vloggers!",
	"Lahat ng kaklase ko, puro ganito ang inaatupag. Nakaka-pressure.",
	"Kung palaguin ko kaya 'tong 3,000 ko? Baka magkaroon ako ng 'breathing room'.",
	"Mababayaran ko yung 15,000 na tuition bukas nang hindi namamatay sa gutom kinabukasan...",
	"Pero paano kung matalo? Masisira yung sakto kong budget. Hindi ako makaka-enroll."
]

var outro_lines: Array[String] = [
	"Hindi. Hindi ngayon.",
	"Kaya ko itong itawid nang hindi nagpapalamon sa sistema ng sugal.",
	"Kailangan kong mag-focus."
]

func _ready() -> void:
	choice_ui.hide()
	
	btn_yes.pressed.connect(_on_yes_pressed)
	btn_no.pressed.connect(_on_no_pressed)
	
	if not DialogManager.dialog_finished.is_connected(_on_dialog_finished):
		DialogManager.dialog_finished.connect(_on_dialog_finished)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_zone = true
		player_ref = body
		if current_state == State.IDLE:
			interact_prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_zone = false
		player_ref = null
		interact_prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.IDLE:
		return
		
	if player_in_zone and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		start_interaction()

func start_interaction() -> void:
	current_state = State.READING_INTRO
	interact_prompt.hide()
	
	if player_ref:
		player_ref.current_state = player_ref.State.LOCKED
		
	DialogManager.start_dialog(global_position, intro_lines)

func _on_dialog_finished() -> void:
	if current_state == State.READING_INTRO:
		current_state = State.WAITING_FOR_CHOICE
		choice_ui.show()
		
	elif current_state == State.READING_OUTRO:
		current_state = State.IDLE
		if player_ref:
			player_ref.current_state = player_ref.State.FREE

func _on_yes_pressed() -> void:
	choice_ui.hide()
	current_state = State.IDLE
	
	# Save the exact position on the street to return to later
	RunState.interruption_return_x = global_position.x
	SceneManager.load_scene("sugal")

func _on_no_pressed() -> void:
	choice_ui.hide()
	current_state = State.READING_OUTRO
	DialogManager.start_dialog(global_position, outro_lines)
