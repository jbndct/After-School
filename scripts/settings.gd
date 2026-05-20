# res://scripts/settings.gd
extends CanvasLayer

@onready var overlay = find_child("Overlay", true, false)
@onready var master_slider = find_child("MasterSlider", true, false)
@onready var bgm_slider = find_child("BGMSlider", true, false) # Added
@onready var sfx_slider = find_child("SFXSlider", true, false) # Added

@onready var resume_button = find_child("ResumeButton", true, false)
@onready var menu_button = find_child("MenuButton", true, false)
@onready var exit_button = find_child("ExitButton", true, false)

var master_bus_idx = AudioServer.get_bus_index("Master")
var bgm_bus_idx = AudioServer.get_bus_index("BGM")
var sfx_bus_idx = AudioServer.get_bus_index("SFX")

func _ready() -> void:
	if not overlay or not resume_button:
		push_error("SETTINGS FATAL: Base UI nodes missing.")
		return

	overlay.hide()
	
	resume_button.pressed.connect(_on_resume_pressed)
	if menu_button: menu_button.pressed.connect(_on_menu_pressed)
	if exit_button: exit_button.pressed.connect(_on_exit_pressed)
	
	# Safely connect sliders if they exist in your UI
	if master_slider:
		master_slider.value_changed.connect(_on_master_slider_value_changed)
		master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_idx))
		
	if bgm_slider:
		bgm_slider.value_changed.connect(_on_bgm_slider_value_changed)
		bgm_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bgm_bus_idx))
		
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if overlay and overlay.visible:
			_close_menu()
		else:
			_open_menu()

func _open_menu() -> void:
	if not overlay: return
	
	var is_on_menu = false
	var current_scene = get_tree().current_scene
	if is_instance_valid(current_scene) and current_scene.scene_file_path == SceneManager.SCENES["menu"]:
		is_on_menu = true

	if is_on_menu:
		if menu_button: menu_button.hide()
		resume_button.text = "Back"
	else:
		if menu_button: menu_button.show()
		resume_button.text = "Resume Game"
		
	overlay.show()
	get_tree().paused = true

func _close_menu() -> void:
	if overlay: overlay.hide()
	get_tree().paused = false

# --- AUDIO BUS ROUTING ---
func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus_idx, value <= 0.01)

func _on_bgm_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bgm_bus_idx, linear_to_db(value))
	AudioServer.set_bus_mute(bgm_bus_idx, value <= 0.01)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus_idx, value <= 0.01)
	AudioManager.play_sfx("sfx_ui_click") # Audio feedback when dragging

# --- NAVIGATION ---
func _on_resume_pressed() -> void: _close_menu()
func _on_menu_pressed() -> void:
	_close_menu()
	SceneManager.load_scene("menu")
func _on_exit_pressed() -> void: get_tree().quit()
