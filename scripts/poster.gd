extends Node2D

@onready var choice_ui = $ChoiceUI
@onready var yes_button = $ChoiceUI/Panel/VBoxContainer/HBoxContainer/YesButton
@onready var no_button = $ChoiceUI/Panel/VBoxContainer/HBoxContainer/NoButton

var current_player: Node2D = null

func _ready() -> void:
	choice_ui.hide()
	
	# Connect Area2D signals
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	
	# Connect Button signals
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	
	# Listen to DialogManager to know when to unlock the player after a "No"
	if not DialogManager.dialog_finished.is_connected(_on_dialog_finished):
		DialogManager.dialog_finished.connect(_on_dialog_finished)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_player = body
		
		# Immediately lock the player and force the decision UI
		if current_player:
			current_player.current_state = current_player.State.LOCKED
		choice_ui.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		current_player = null

func _on_yes_pressed() -> void:
	choice_ui.hide()
	
	# Save the player's exact X coordinate so the street doesn't spawn them at a door
	if current_player:
		RunState.interruption_return_x = current_player.global_position.x
		
	# Route directly to the minigame
	SceneManager.load_scene("sugal")

func _on_no_pressed() -> void:
	choice_ui.hide()
	
	# Trigger the existing speech bubble system
	var lines: Array[String] = [
		"Not today. I have other things to focus on.",
		"I can't afford to lose anything right now."
	]
	DialogManager.start_dialog(global_position + Vector2(0, -50), lines)

func _on_dialog_finished() -> void:
	# Unlock the player once the "No" dialogue finishes
	# They must walk completely out of the Area2D before it can trigger again
	if current_player:
		current_player.current_state = current_player.State.FREE
