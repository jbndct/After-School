extends Node2D

@export var next_scene: String = "res://scenes/room.tscn"
@export var auto_advance: bool = false
@export var auto_advance_time: float = 2.0

@onready var play_button = $CanvasLayer/VBoxContainer/Play
@onready var settings_button = $CanvasLayer/VBoxContainer2/Settings
@onready var title = $CanvasLayer/Title
@onready var background = $CanvasLayer/Background

func _ready() -> void:
	if auto_advance:
		play_button.visible = false
		await get_tree().create_timer(auto_advance_time).timeout
		_on_play_button_pressed() 
	else:
		play_button.visible = true
		
		# FORCES the button to connect to the function below, guaranteeing it works
		if not play_button.pressed.is_connected(_on_play_button_pressed):
			play_button.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed() -> void:
	# Wipe progress and money (Checks if GameState exists first to prevent crashes)
	if GameState and GameState.has_method("reset"):
		GameState.reset() 
	
	# Load the next scene
	if next_scene != "" and is_inside_tree():
		get_tree().change_scene_to_file(next_scene)
