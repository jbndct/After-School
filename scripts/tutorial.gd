extends Node2D

# Smart lookups: Finds the nodes automatically to prevent crashes
@onready var player = find_child("Player", true, false)
@onready var instruction_text = find_child("InstructionText", true, false)
@onready var desk_area = find_child("*Interact*", true, false)
@onready var door_area = find_child("*Door*", true, false)

# Added LEARN_SPRINT to the 5 strict steps
enum Step { WALK_LEFT, WALK_RIGHT, LEARN_SPRINT, INTERACT_BED, EXIT_DOOR }
var current_step: Step = Step.WALK_LEFT
var sprint_timer: float = 0.0
var is_exiting: bool = false

func _ready() -> void:
	AudioManager.play_bgm("bg1.mp3")

	# Hide all "Press E" prompts at the start
	if desk_area:
		var p = desk_area.find_child("*Prompt*", true, false)
		if p:
			p.hide()
	if door_area:
		var p = door_area.find_child("*Prompt*", true, false)
		if p:
			p.hide()

	# Ensure Player can move
	if player and "current_state" in player:
		player.current_state = player.State.FREE

	_update_instructions()

func _process(delta: float) -> void:
	if is_exiting or not is_instance_valid(player):
		return

	var player_x: float = player.global_position.x

	# STEP 1: Walk to the far left
	if current_step == Step.WALK_LEFT:
		if player_x < -450.0:
			current_step = Step.WALK_RIGHT
			_update_instructions()

	# STEP 2: Walk to the far right
	elif current_step == Step.WALK_RIGHT:
		if player_x > 700.0:
			current_step = Step.LEARN_SPRINT
			_update_instructions()

	# STEP 3: Learn to Sprint
	elif current_step == Step.LEARN_SPRINT:
		var is_moving: bool = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
		var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT)

		if is_moving and is_sprinting:
			sprint_timer += delta
			if sprint_timer > 3.0:
				current_step = Step.INTERACT_BED
				_update_instructions()

func _unhandled_input(event: InputEvent) -> void:
	if is_exiting or not is_instance_valid(player):
		return

	var pressed_interact: bool = event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_E)
	if not pressed_interact:
		return

	# STEP 4: Check if touching bed/chair area
	if current_step == Step.INTERACT_BED and desk_area:
		if desk_area.get_overlapping_bodies().has(player):
			var p = desk_area.find_child("*Prompt*", true, false)
			if p:
				p.hide()
			current_step = Step.EXIT_DOOR
			_update_instructions()

	# STEP 5: Check if touching door
	elif current_step == Step.EXIT_DOOR and door_area:
		if door_area.get_overlapping_bodies().has(player):
			is_exiting = true
			var tutorial_arrow = player.find_child("TutorialArrow", true, false)
			if tutorial_arrow and tutorial_arrow.has_method("set_target"):
				tutorial_arrow.set_target(null)
			RunState.current_phase = "morning"
			RunState.previous_location = "tutorial"
			SceneManager.load_scene("room")

func _update_instructions() -> void:
	if not instruction_text:
		return
	var tutorial_arrow = null
	if player:
		tutorial_arrow = player.find_child("TutorialArrow", true, false)

	match current_step:
		Step.WALK_LEFT:
			instruction_text.text = "TUTORYAL 1/5: Maglakad pakaliwa (A key o Left Arrow) papunta sa dulo."
			if tutorial_arrow and tutorial_arrow.has_method("set_target"):
				tutorial_arrow.set_target(null)

		Step.WALK_RIGHT:
			instruction_text.text = "TUTORYAL 2/5: Maglakad pakanan (D key o Right Arrow) papunta sa dulo."
			if tutorial_arrow and tutorial_arrow.has_method("set_target"):
				tutorial_arrow.set_target(null)

		Step.LEARN_SPRINT:
			instruction_text.text = "TUTORYAL 3/5: Pindutin nang matagal ang [SHIFT] habang naglalakad para tumakbo (Sprint)."
			if tutorial_arrow and tutorial_arrow.has_method("set_target"):
				tutorial_arrow.set_target(null)

		Step.INTERACT_BED:
			instruction_text.text = "TUTORYAL 4/5: Sundan ang dilaw na arrow. Lumapit sa mga upuan at pindutin ang [E]."
			if tutorial_arrow and desk_area and tutorial_arrow.has_method("set_target"):
				tutorial_arrow.set_target(desk_area)
			if desk_area:
				var p = desk_area.find_child("*Prompt*", true, false)
				if p:
					p.show()

		Step.EXIT_DOOR:
			instruction_text.text = "TUTORYAL 5/5: Mahusay! Sundan ang arrow papunta sa pinto. Pindutin ang [E] para simulan."
			if tutorial_arrow and door_area and tutorial_arrow.has_method("set_target"):
				tutorial_arrow.set_target(door_area)
			if door_area:
				var p = door_area.find_child("*Prompt*", true, false)
				if p:
					p.show()
