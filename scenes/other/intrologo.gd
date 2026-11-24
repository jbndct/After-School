extends Control

const NEXT_SCENE := "res://scenes/other/Advisory.tscn"

@export var fade_time: float = 0.8
@export var hold_time: float = 2.0

var _done := false

func _ready() -> void:
	print("IntroLogo ready")
	var logo := get_node_or_null("Logo") as CanvasItem
	if logo:
		logo.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(logo, "modulate:a", 1.0, fade_time)
		tween.tween_interval(hold_time)
		tween.tween_property(logo, "modulate:a", 0.0, fade_time)
		tween.finished.connect(go_next)
	else:
		push_warning("No node named 'Logo' found, moving on anyway")
		get_tree().create_timer(hold_time).timeout.connect(go_next)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
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
