extends Node2D

@onready var player = $Player
@onready var instruction_label = $TutorialUI/PanelContainer/InstructionLabel
@onready var status_label = $TutorialUI/GoalBox/StatusLabel
@onready var door_area = $InteractDummyDoor

var walked_left: bool = false
var walked_right: bool = false
var interacted_door: bool = false

enum Step { MOVE, PHONE, DOOR }
var current_step = Step.MOVE

func _ready() -> void:
	door_area.body_entered.connect(_on_door_entered)
	_update_ui()

func _process(_delta: float) -> void:
	if current_step == Step.MOVE:
		if Input.is_action_pressed("move_left"):
			walked_left = true
		if Input.is_action_pressed("move_right"):
			walked_right = true
			
		if walked_left and walked_right:
			current_step = Step.PHONE
			_update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if current_step == Step.PHONE and event.is_action_pressed("toggle_phone"):
		current_step = Step.DOOR
		_update_ui()

func _update_ui() -> void:
	match current_step:
		Step.MOVE:
			instruction_label.text = "Step 1: Use A/D or LEFT/RIGHT Arrow keys to move Ador."
			status_label.text = "[ %s ] Move Left\n[ %s ] Move Right\n[  ] Check Smartphone\n[  ] Interact with Door" % [
				"X" if walked_left else " ",
				"X" if walked_right else " "
			]
		Step.PHONE:
			instruction_label.text = "Step 2: Press [TAB] or click your phone icon to view tasks & finances."
			status_label.text = "[X] Move Left\n[X] Move Right\n[  ] Open Smartphone ([TAB])\n[  ] Interact with Door"
		Step.DOOR:
			instruction_label.text = "Step 3: Head right and press [E] at the door to begin your day."
			status_label.text = "[X] Move Left\n[X] Move Right\n[X] Check Smartphone\n[  ] Press [E] at Door"

func _on_door_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and current_step == Step.DOOR:
		SceneManager.load_scene("room")
