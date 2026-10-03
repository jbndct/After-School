extends Node2D

@onready var player = $Player
@onready var instruction_text = $TutorialUI/PanelContainer/InstructionText
@onready var desk_area = $InteractableItem
@onready var door_area = $ExitDoor

# The 4 strict steps
enum Step { WALK_LEFT, WALK_RIGHT, INTERACT_BED, EXIT_DOOR }
var current_step: Step = Step.WALK_LEFT

func _ready() -> void:
	# Hide the interact prompts initially so we control when they appear
	var desk_prompt = desk_area.get_node_or_null("InteractPrompt")
	if desk_prompt: desk_prompt.hide()
	
	var door_prompt = door_area.get_node_or_null("DoorPrompt")
	if door_prompt: door_prompt.hide()
	
	# Make sure the player can move
	if player and "current_state" in player:
		player.current_state = player.State.FREE
		
	_update_instructions()

func _process(_delta: float) -> void:
	if not is_instance_valid(player): return
	
	# Get the player's current X position
	var player_x = player.global_position.x
	
	# STEP 1: Walk to the far left
	if current_step == Step.WALK_LEFT:
		if player_x < 150: # Adjust this number if it's too far or too close to the left wall
			current_step = Step.WALK_RIGHT
			_update_instructions()
			
	# STEP 2: Walk to the far right
	elif current_step == Step.WALK_RIGHT:
		if player_x > 900: # Adjust this number if it's too far or too close to the right wall
			current_step = Step.INTERACT_BED
			_update_instructions()

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player): return
	
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		
		# STEP 3: Force interaction with the bed
		if current_step == Step.INTERACT_BED:
			# BULLETPROOF CHECK: Is the player physically inside the bed's Area2D right now?
			if desk_area.get_overlapping_bodies().has(player):
				var desk_prompt = desk_area.get_node_or_null("InteractPrompt")
				if desk_prompt: desk_prompt.hide()
				
				current_step = Step.EXIT_DOOR
				_update_instructions()
				
		# STEP 4: Exit through the door
		elif current_step == Step.EXIT_DOOR:
			# BULLETPROOF CHECK: Is the player physically inside the door's Area2D right now?
			if door_area.get_overlapping_bodies().has(player):
				# Load using the proper Enum to avoid string path crashes
				SceneManager.load_scene(SceneManager.GameScene.ROOM)

func _update_instructions() -> void:
	var tutorial_arrow = player.get_node_or_null("TutorialArrow")
	
	match current_step:
		Step.WALK_LEFT:
			instruction_text.text = "TUTORIAL 1/4: Maglakad pakaliwa (A key o Left Arrow) hanggang sa dulo."
			if tutorial_arrow: tutorial_arrow.set_target(null) # Hide arrow
			
		Step.WALK_RIGHT:
			instruction_text.text = "TUTORIAL 2/4: Maglakad pakanan (D key o Right Arrow) hanggang sa dulo."
			if tutorial_arrow: tutorial_arrow.set_target(null)
			
		Step.INTERACT_BED:
			instruction_text.text = "TUTORIAL 3/4: Sundan ang dilaw na arrow sa itaas mo. Lumapit sa kama at pindutin ang [E]."
			
			if tutorial_arrow: tutorial_arrow.set_target(desk_area) # Point to the bed
			var desk_prompt = desk_area.get_node_or_null("InteractPrompt")
			if desk_prompt: desk_prompt.show()
			
		Step.EXIT_DOOR:
			instruction_text.text = "TUTORIAL 4/4: Sundan ang arrow papunta sa pinto. Pindutin ang [E] para simulan ang laro."
			
			if tutorial_arrow: tutorial_arrow.set_target(door_area) # Point to the door
			var door_prompt = door_area.get_node_or_null("DoorPrompt")
			if door_prompt: door_prompt.show()
