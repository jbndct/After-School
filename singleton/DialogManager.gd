# res://singleton/DialogManager.gd
extends Node

@onready var text_box_scene = preload("res://ui/text_box.tscn")

var all_dialogues: Dictionary = {}

# World-Space Dialogue State
var current_dialog_data: Array = []
var current_line_index: int = 0
var text_box
var text_box_position: Vector2
var is_dialog_active: bool = false
var can_advance_line: bool = false
var input_cooldown: float = 0.0

signal dialog_finished

func _ready() -> void:
	_load_dialogues()

func _load_dialogues() -> void:
	var file = FileAccess.open("res://data/dialogues.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			all_dialogues = json.data
		else:
			push_error("JSON Parse Error in dialogues.json: ", json.get_error_message())
	else:
		push_error("Missing res://data/dialogues.json")

# Call this to fetch a single UI string (like objectives/warnings)
func get_text(text_id: String) -> String:
	if all_dialogues.has(text_id):
		return str(all_dialogues[text_id])
	push_error("Text ID not found in JSON: " + text_id)
	return "MISSING TEXT"

# Call this to fetch data for CanvasLayer UI
func get_dialogue(dialogue_id: String) -> Array:
	if all_dialogues.has(dialogue_id):
		return all_dialogues[dialogue_id]
	push_error("Dialogue ID not found in JSON: " + dialogue_id)
	return []

# Call this to spawn World-Space floating text boxes
func start_world_dialog(dialogue_id: String, position: Vector2) -> void:
	if is_dialog_active:
		return
	if not all_dialogues.has(dialogue_id):
		push_error("Dialogue ID not found in JSON: " + dialogue_id)
		return
		
	current_dialog_data = all_dialogues[dialogue_id]
	text_box_position = position
	current_line_index = 0
	is_dialog_active = true
	_show_text_box()

func _show_text_box() -> void:
	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	
	get_tree().current_scene.add_child(text_box)
	text_box.z_index = 100 
	
	var target_pos = text_box_position + Vector2(-100, -200)
	text_box.global_position = target_pos
	
	var line_data = current_dialog_data[current_line_index]
	var text_to_show = line_data.get("text", "") if typeof(line_data) == TYPE_DICTIONARY else str(line_data)
	
	text_box.display_text(text_to_show)
	can_advance_line = false
	input_cooldown = 0.2 

func _on_text_box_finished_displaying() -> void:
	can_advance_line = true

func _process(delta: float) -> void:
	if input_cooldown > 0:
		input_cooldown -= delta
		
	if is_dialog_active and Input.is_action_just_pressed("interact"):
		if input_cooldown > 0:
			return
			
		if can_advance_line:
			if is_instance_valid(text_box):
				text_box.queue_free()
					
			current_line_index += 1
			
			if current_line_index >= current_dialog_data.size():
				is_dialog_active = false
				current_line_index = 0
				dialog_finished.emit()
			else:
				_show_text_box()
		else:
			if is_instance_valid(text_box) and text_box.has_method("finish_typing_instantly"):
				text_box.finish_typing_instantly()
				can_advance_line = true
				input_cooldown = 0.2
