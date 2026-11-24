extends Control

const NEXT_SCENE := "res://scenes/Menu.tscn"

@export var fade_time: float = 0.8
@export var hold_time: float = 6.0

var _done := false

func _ready() -> void:
	print("Advisory ready")
	var content := get_node_or_null("Content") as CanvasItem
	if content == null:
		content = self  # fallback: fade the whole scene
	content.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(content, "modulate:a", 1.0, fade_time)
	tween.tween_interval(hold_time)
	tween.tween_property(content, "modulate:a", 0.0, fade_time)
	tween.finished.connect(go_next)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		go_next()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		go_next()

func go_next() -> void:
	if _done:
		return
	_done = true
	print("Going to: ", NEXT_SCENE)
	if not ResourceLoader.exists(NEXT_SCENE):
		push_error("Scene not found: " + NEXT_SCENE)
		return
	get_tree().change_scene_to_file(NEXT_SCENE)
