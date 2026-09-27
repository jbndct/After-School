extends Node2D

@onready var player = $Player
@onready var instruction_label: Label = $TutorialUI/InstructionPanel/InstructionLabel
@onready var status_label: Label = $TutorialUI/GoalBox/StatusLabel
@onready var door_area: Area2D = $InteractDummyDoor

var walked_left: bool = false
var walked_right: bool = false
var player_at_door: bool = false

enum Step { MOVE, PHONE, DOOR }
var current_step = Step.MOVE

func _ready() -> void:
	if is_instance_valid(door_area):
		door_area.body_entered.connect(_on_door_entered)
		door_area.body_exited.connect(_on_door_exited)
	
	# Ensure Player starts in free movement mode
	if player and "current_state" in player:
		player.current_state = player.State.FREE
		
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
	if current_step == Step.PHONE:
		var pressed_phone = false
		if event.is_action_pressed("toggle_phone"):
			pressed_phone = true
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_TAB:
				pressed_phone = true
				
		if pressed_phone:
			current_step = Step.DOOR
			_update_ui()
			
	elif current_step == Step.DOOR and player_at_door:
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
			SceneManager.load_scene("room")

func _update_ui() -> void:
	if not is_instance_valid(instruction_label) or not is_instance_valid(status_label):
		return

	match current_step:
		Step.MOVE:
			instruction_label.text = "Hakbang 1: Gamitin ang A/D o LEFT/RIGHT Arrow Keys para gumalaw."
			status_label.text = "[ %s ] Lumakad pakaliwa\n[ %s ] Lumakad pakanan\n[  ] Buksan ang Smartphone (TAB)\n[  ] Pumasok sa Pinto (E)" % [
				"✓" if walked_left else " ",
				"✓" if walked_right else " "
			]
		Step.PHONE:
			instruction_label.text = "Hakbang 2: Pindutin ang [TAB] o ang Phone Icon para makita ang pera at gastusin."
			status_label.text = "[✓] Lumakad pakaliwa\n[✓] Lumakad pakanan\n[  ] Buksan ang Smartphone (TAB)\n[  ] Pumasok sa Pinto (E)"
		Step.DOOR:
			instruction_label.text = "Hakbang 3: Lumapit sa pinto sa kanan at pindutin ang [E] upang simulan ang araw."
			status_label.text = "[✓] Lumakad pakaliwa\n[✓] Lumakad pakanan\n[✓] Nasuri ang Smartphone\n[  ] Pumasok sa Pinto (E)"

func _on_door_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = true
		var prompt = door_area.get_node_or_null("DoorPrompt")
		if prompt: prompt.visible = true

func _on_door_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_at_door = false
		var prompt = door_area.get_node_or_null("DoorPrompt")
		if prompt: prompt.visible = false
