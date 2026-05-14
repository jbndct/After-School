# res://scripts/settings.gd
extends CanvasLayer

# find_child("Name", recursive=true, owned=false) 
# This bypasses all pathing issues and hunts down the node globally within this scene.
@onready var overlay = find_child("Overlay", true, false)
@onready var master_slider = find_child("MasterSlider", true, false)
@onready var resume_button = find_child("ResumeButton", true, false)
@onready var menu_button = find_child("MenuButton", true, false)
@onready var exit_button = find_child("ExitButton", true, false)

var master_bus_index: int

func _ready() -> void:
	# Final check. If this fails, the node simply doesn't exist in the scene tree.
	if not overlay or not master_slider or not resume_button or not menu_button or not exit_button:
		push_error("SETTINGS FATAL: Recursive search failed. Check exact spelling (e.g., 'MasterSlider').")
		return

	overlay.hide()
	
	master_slider.value_changed.connect(_on_master_value_changed)
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	master_bus_index = AudioServer.get_bus_index("Master")
	var current_db = AudioServer.get_bus_volume_db(master_bus_index)
	master_slider.value = db_to_linear(current_db)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if overlay and overlay.visible:
			_close_menu()
		else:
			_open_menu()

func _open_menu() -> void:
	if not overlay: 
		return

	var is_on_menu = false
	var current_scene = get_tree().current_scene
	
	if is_instance_valid(current_scene) and current_scene.scene_file_path != "":
		if current_scene.scene_file_path == SceneManager.SCENES["menu"]:
			is_on_menu = true

	if is_on_menu:
		menu_button.hide()
		resume_button.text = "Back"
	else:
		menu_button.show()
		resume_button.text = "Resume Game"
		
	overlay.show()
	get_tree().paused = true

func _close_menu() -> void:
	if overlay:
		overlay.hide()
	get_tree().paused = false

func _on_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus_index, value <= 0.0)

func _on_resume_pressed() -> void:
	_close_menu()

func _on_menu_pressed() -> void:
	_close_menu()
	SceneManager.load_scene("menu")

func _on_exit_pressed() -> void:
	get_tree().quit()
