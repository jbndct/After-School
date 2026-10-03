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

func _ready() -> void:
	AudioManager.play_bgm("bg1.mp3")
	
	# Hide all "Press E" prompts at the start
	if desk_area:
		var p = desk_area.find_child("*Prompt*", true, false)
		if p: p.hide()
	if door_area:
		var p = door_area.find_child("*Prompt*", true, false)
		if p: p.hide()
		
	# Ensure Player can move
	if player and "current_state" in player:
		player.current_state = player.State.FREE
		
	_update_instructions()

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	
	var player_x = player.global_position.x
	
	# STEP 1: Walk to the far left (Adjusted to -450)
	if current_step == Step.WALK_LEFT:
		if player_x < -450: 
			current_step = Step.WALK_RIGHT
			_update_instructions()
			
	# STEP 2: Walk to the far right
	elif current_step == Step.WALK_RIGHT:
		if player_x > 900:
			current_step = Step.LEARN_SPRINT
			_update_instructions()
			
	# STEP 3: Learn to Sprint
	elif current_step == Step.LEARN_SPRINT:
		# Check if the player is pressing A/D while holding SHIFT
		var is_moving = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
		var is_sprinting = Input.is_key_pressed(KEY_SHIFT)
		
		if is_moving and is_sprinting:
			sprint_timer += delta
			if sprint_timer > 1.0: # They must run for 1 full second to pass this step
				current_step = Step.INTERACT_BED
				_update_instructions()

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player): return
	
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		
		# STEP 4: Check if touching bed
		if current_step == Step.INTERACT_BED and desk_area:
			# BULLETPROOF FIX: Only works if physically standing on it
			if desk_area.get_overlapping_bodies().has(player):
				var p = desk_area.find_child("*Prompt*", true, false)
				if p: p.hide()
				current_step = Step.EXIT_DOOR
				_update_instructions()
				
		# STEP 5: Check if touching door
		elif current_step == Step.EXIT_DOOR and door_area:
			# BULLETPROOF FIX: Only works if physically standing on it
			if door_area.get_overlapping_bodies().has(player):
				# Safely transition to the real game
				get_tree().change_scene_to_file("res://scenes/room.tscn")

func _update_instructions() -> void:
	if not instruction_text: return
	var tutorial_arrow = null
	if player: tutorial_arrow = player.find_child("TutorialArrow", true, false)
	
	match current_step:
		Step.WALK_LEFT:
			instruction_text.text = "TUTORIAL 1/5: Maglakad pakaliwa (A key o Left Arrow) papunta sa dulo."
			if tutorial_arrow: tutorial_arrow.set_target(null)
			
		Step.WALK_RIGHT:
			instruction_text.text = "TUTORIAL 2/5: Maglakad pakanan (D key o Right Arrow) papunta sa dulo."
			if tutorial_arrow: tutorial_arrow.set_target(null)
			
		Step.LEARN_SPRINT:
			instruction_text.text = "TUTORIAL 3/5: Pindutin nang matagal ang [SHIFT] habang naglalakad para tumakbo (Sprint)."
			if tutorial_arrow: tutorial_arrow.set_target(null)
			
		Step.INTERACT_BED:
			instruction_text.text = "TUTORIAL 4/5: Sundan ang dilaw na arrow. Lumapit sa kama at pindutin ang [E]."
			if tutorial_arrow and desk_area: tutorial_arrow.set_target(desk_area)
			if desk_area:
				var p = desk_area.find_child("*Prompt*", true, false)
				if p: p.show()
				
		Step.EXIT_DOOR:
			instruction_text.text = "TUTORIAL 5/5: Mahusay! Sundan ang arrow papunta sa pinto. Pindutin ang [E] para simulan."
			if tutorial_arrow and door_area: tutorial_arrow.set_target(door_area)
			if door_area:
				var p = door_area.find_child("*Prompt*", true, false)
				if p: p.show()
