extends Control

@onready var button = $Button

func _ready() -> void:
	# This automatically hooks up the button without needing the Godot editor's signal menu!
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	# Add any specific money/stat rewards here later if you want, 
	# but for now, just tell the GameState to move on!
	GameState.advance_scene()
