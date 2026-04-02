extends Node2D

@export var scene_name: String = "Scene Name"
@export var next_scene: String = ""
@export var auto_advance: bool = false
@export var auto_advance_time: float = 2.0

@onready var label = $CanvasLayer/VBoxContainer/Label
@onready var button = $CanvasLayer/VBoxContainer/Button

func _ready() -> void:
	label.text = scene_name
	
	if auto_advance:
		button.visible = false
		await get_tree().create_timer(auto_advance_time).timeout
		advance()
	else:
		button.visible = true
		button.pressed.connect(advance)

func advance() -> void:
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
		
func _on_play_button_pressed() -> void:
	# 1. WIPE ALL PROGRESS AND MONEY
	GameState.reset() 
	
	# 2. LOAD THE FIRST SCENE
	get_tree().change_scene_to_file("res://scenes/room.tscn")
