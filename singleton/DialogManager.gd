extends Node

@onready var text_box_scene = preload("res://ui/text_box.tscn")
var dialog_lines: Array[String] = []
var current_line_index = 0
var text_box
var text_box_position: Vector2
var is_dialog_active = false
var can_advance_line = false
var cached_screen_pos: Vector2

signal dialog_finished

func start_dialog(position: Vector2, lines: Array[String]):
	if is_dialog_active:
		return
	dialog_lines = lines
	text_box_position = position
	
	var camera = get_viewport().get_camera_2d()
	cached_screen_pos = position - camera.get_screen_center_position() + get_viewport().get_visible_rect().size / 2
	_show_text_box()
	is_dialog_active = true

func _show_text_box():
	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	get_tree().root.add_child(canvas)
	canvas.add_child(text_box)
	
	var target_pos = cached_screen_pos + Vector2(-100, -200)
	target_pos.y = min(target_pos.y, 400)
	text_box.position = target_pos
	
	text_box.display_text(dialog_lines[current_line_index])
	can_advance_line = false
	
	



func _on_text_box_finished_displaying():
	can_advance_line = true

func _unhandled_input(event):
	if (
		event.is_action_pressed("interact") &&
		is_dialog_active &&
		can_advance_line
	):
		text_box.queue_free()
		text_box.get_parent().queue_free()
		current_line_index += 1
		if current_line_index >= dialog_lines.size():
			is_dialog_active = false
			current_line_index = 0
			emit_signal("dialog_finished")
			return
		_show_text_box()
