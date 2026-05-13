extends Node2D

@onready var play_button = $PlayButton # Change path based on your scene tree
@onready var quit_button = $QuitButton 

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	# THIS IS CRITICAL. Wipes all ending flags, sets phase to morning, sets money to 550.
	RunState.reset_run() 
	
	# Start the game
	SceneManager.load_scene("room")

func _on_quit_pressed() -> void:
	get_tree().quit()
