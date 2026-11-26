# res://scripts/menu.gd
extends Node2D

@onready var play_button: Button = find_child("PlayButton", true, false)
@onready var quit_button: Button = find_child("QuitButton", true, false)
@onready var credits_button: Button = find_child("Credits", true, false)
@onready var settings_button: Button = find_child("Settings", true, false)

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
		
	AudioManager.play_bgm("bgm_menu")

func _on_play_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	
	# THIS IS CRITICAL. Wipes all ending flags, sets phase to morning, sets money to 550.
	RunState.reset_run() 
	
	# Start the game
	SceneManager.load_scene("intro")

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	get_tree().quit()
	
func _on_settings_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	SettingsMenu._open_menu()
