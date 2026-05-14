# res://scripts/settings.gd
extends CanvasLayer

@onready var overlay = $Overlay
@onready var master_slider = $Overlay/PopupPanel/Padding/VBox/AudioBox/MasterSlider
@onready var resume_button = $Overlay/PopupPanel/Padding/VBox/ResumeButton
@onready var menu_button = $Overlay/PopupPanel/Padding/VBox/MenuButton
@onready var exit_button = $Overlay/PopupPanel/Padding/VBox/ExitButton

var master_bus_index: int

func _ready() -> void:
	overlay.hide()
	
	# Connect signals dynamically
	master_slider.value_changed.connect(_on_master_value_changed)
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Setup Audio
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# Initialize slider position based on actual bus volume
	var current_db = AudioServer.get_bus_volume_db(master_bus_index)
	master_slider.value = db_to_linear(current_db)

func _input(event: InputEvent) -> void:
	# Toggle menu with Escape
	if event.is_action_pressed("ui_cancel"):
		if overlay.visible:
			_close_menu()
		else:
			_open_menu()

func _open_menu() -> void:
	# Hide "Quit to Menu" if we are already on the Main Menu
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path == SceneManager.SCENES["menu"]:
		menu_button.hide()
		resume_button.text = "Back"
	else:
		menu_button.show()
		resume_button.text = "Resume Game"
		
	overlay.show()
	get_tree().paused = true

func _close_menu() -> void:
	overlay.hide()
	get_tree().paused = false

func _on_master_value_changed(value: float) -> void:
	# Convert linear slider (0 to 1) to Decibels
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	# Mute completely if slider is at 0
	AudioServer.set_bus_mute(master_bus_index, value <= 0.0)

func _on_resume_pressed() -> void:
	_close_menu()

func _on_menu_pressed() -> void:
	_close_menu()
	SceneManager.load_scene("menu")

func _on_exit_pressed() -> void:
	get_tree().quit()
