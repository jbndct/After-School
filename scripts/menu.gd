# res://scripts/menu.gd
extends Node2D

@onready var play_button = $PlayButton 
@onready var quit_button = $QuitButton 

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	
	# THIS IS CRITICAL. Wipes all ending flags, sets phase to morning, sets money to 550.
	RunState.reset_run() 
	
	# Start the game
	SceneManager.load_scene("room")

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	get_tree().quit()
