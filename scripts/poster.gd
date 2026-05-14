# res://scripts/poster.gd
extends Area2D

@onready var choice_ui: Control = $UILayer/ChoiceUI
@onready var yes_button: Button = $UILayer/ChoiceUI/BottomMargin/BackgroundPanel/Padding/VBox/HBox/YesButton
@onready var no_button: Button = $UILayer/ChoiceUI/BottomMargin/BackgroundPanel/Padding/VBox/HBox/NoButton
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_player: CharacterBody2D = null
var has_triggered: bool = false

func _ready() -> void:
	choice_ui.hide()
	
	yes_button.focus_mode = Control.FOCUS_NONE
	no_button.focus_mode = Control.FOCUS_NONE
	
	body_entered.connect(_on_body_entered)
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	
	if not DialogManager.dialog_finished.is_connected(_on_dialog_finished):
		DialogManager.dialog_finished.connect(_on_dialog_finished)
		
	# Prevent spawn-trapping when returning from SugalHub
	call_deferred("_check_initial_overlap")

func _check_initial_overlap() -> void:
	# If the player spawns directly inside the poster, disable it immediately
	for body in get_overlapping_bodies():
		if body.is_in_group("Player"):
			has_triggered = true
			collision_shape.set_deferred("disabled", true)
			return

func _on_body_entered(body: Node2D) -> void:
	if has_triggered:
		return
		
	if body.is_in_group("Player"):
		current_player = body
		has_triggered = true
		
		current_player.current_state = current_player.State.LOCKED
		choice_ui.show()

func _on_yes_pressed() -> void:
	choice_ui.hide()
	
	if current_player:
		RunState.interruption_return_x = current_player.global_position.x
		
	SceneManager.load_scene("sugal")

func _on_no_pressed() -> void:
	choice_ui.hide()
	
	var lines: Array[String] = [
		"Not now.",
		"I need to keep moving."
	]
	
	if current_player:
		DialogManager.start_dialog(current_player.global_position + Vector2(0, -60), lines)

func _on_dialog_finished() -> void:
	if current_player and choice_ui.visible == false and has_triggered:
		current_player.current_state = current_player.State.FREE
		current_player = null
		collision_shape.set_deferred("disabled", true)
