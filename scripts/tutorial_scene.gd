extends Node2D

@onready var player = $Player
@onready var instruction_text = $TutorialUI/PanelContainer/InstructionText
@onready var desk_area = $InteractableItem
@onready var door_area = $ExitDoor

var walked_left: bool = false
var walked_right: bool = false
var near_desk: bool = false
var near_door: bool = false

# The 4 strict steps
enum Step { LEARN_MOVE, LEARN_INTERACT, LEARN_PHONE, GO_TO_DOOR }
var current_step: Step = Step.LEARN_MOVE

func _ready() -> void:
	# Hide the interact prompts initially so we control when they appear
	$InteractableItem/InteractPrompt.hide()
	$ExitDoor/DoorPrompt.hide()
	
	# Detect when player is near the desk
	desk_area.body_entered.connect(func(b): if b.is_in_group("Player"): near_desk = true; if current_step == Step.LEARN_INTERACT: $InteractableItem/InteractPrompt.show())
	desk_area.body_exited.connect(func(b): if b.is_in_group("Player"): near_desk = false; $InteractableItem/InteractPrompt.hide())
	
	# Detect when player is near the door
	door_area.body_entered.connect(func(b): if b.is_in_group("Player"): near_door = true; if current_step == Step.GO_TO_DOOR: $ExitDoor/DoorPrompt.show())
	door_area.body_exited.connect(func(b): if b.is_in_group("Player"): near_door = false; $ExitDoor/DoorPrompt.hide())
	
	# Disable the bouncing tutorial arrow for the tutorial scene to avoid clutter
	var arrow = player.get_node_or_null("TutorialArrow")
	if arrow: arrow.queue_free()
	
	_update_instructions()

func _process(_delta: float) -> void:
	# STEP 1: Wait for A and D
	if current_step == Step.LEARN_MOVE:
		if Input.is_action_pressed("move_left"): walked_left = true
		if Input.is_action_pressed("move_right"): walked_right = true
		
		if walked_left and walked_right:
			current_step = Step.LEARN_INTERACT
			_update_instructions()

func _unhandled_input(event: InputEvent) -> void:
	# STEP 2: Force interaction with the desk
	if current_step == Step.LEARN_INTERACT:
		if event.is_action_pressed("interact") and near_desk:
			$InteractableItem/InteractPrompt.hide()
			current_step = Step.LEARN_PHONE
			_update_instructions()
			
	# STEP 3: Force opening the phone
	elif current_step == Step.LEARN_PHONE:
		if event.is_action_pressed("toggle_phone") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
			current_step = Step.GO_TO_DOOR
			_update_instructions()
			
	# STEP 4: Exit through the door
	elif current_step == Step.GO_TO_DOOR:
		if event.is_action_pressed("interact") and near_door:
			# Tutorial is done! Send them to the real Day 1 Room.
			SceneManager.load_scene("room")

func _update_instructions() -> void:
	match current_step:
		Step.LEARN_MOVE:
			instruction_text.text = "TUTORIAL 1/4: Gamitin ang A / D o Left / Right Arrows para maglakad."
		Step.LEARN_INTERACT:
			instruction_text.text = "TUTORIAL 2/4: Lumapit sa desk at pindutin ang [E] para mag-interact."
		Step.LEARN_PHONE:
			instruction_text.text = "TUTORIAL 3/4: Pindutin ang [TAB] para makita ang iyong Smartphone."
		Step.GO_TO_DOOR:
			instruction_text.text = "TUTORIAL 4/4: Magaling! Lumapit sa pinto at pindutin ang [E] para simulan ang laro."
