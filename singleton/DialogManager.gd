# res://singleton/DialogManager.gd
extends Node

@onready var text_box_scene = preload("res://ui/text_box.tscn")
var dialog_lines: Array[String] = []
var current_line_index = 0
var text_box
var text_box_position: Vector2
var is_dialog_active = false
var can_advance_line = false
var input_cooldown = 0.0

signal dialog_finished

func start_dialog(position: Vector2, lines: Array[String]):
	if is_dialog_active:
		return
	dialog_lines = lines
	text_box_position = position
	_show_text_box()
	is_dialog_active = true

func _show_text_box():
	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	
	get_tree().current_scene.add_child(text_box)
	text_box.z_index = 100 
	
	var target_pos = text_box_position + Vector2(-100, -200)
	text_box.global_position = target_pos
	
	text_box.display_text(dialog_lines[current_line_index])
	can_advance_line = false
	input_cooldown = 0.2 # 0.2 second lock out to prevent accidental double clicks

func _on_text_box_finished_displaying():
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
			
			if current_line_index >= dialog_lines.size():
				is_dialog_active = false
				current_line_index = 0
				dialog_finished.emit()
			else:
				_show_text_box()
		else:
			# Allows you to skip typing, but forces the system to recognize it finished
			if is_instance_valid(text_box) and text_box.has_method("finish_typing_instantly"):
				text_box.finish_typing_instantly()
				can_advance_line = true
				input_cooldown = 0.2
