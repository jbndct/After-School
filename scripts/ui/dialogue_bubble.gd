extends Control
## Speech bubble with typing animation.
##   $DialogueBubble.start(["Line one", "Line two"])             -> bubble at bottom-center of the screen
##   $DialogueBubble.start(["Line one"], some_node_3d_or_2d)      -> bubble floats above that node
## While a line is typing: Space / Enter / click shows the full line.
## When the line is finished: Space / Enter / click goes to the next line.

signal dialogue_started
signal line_changed(index: int)
signal dialogue_finished

@export var max_text_width: float = 520.0
@export var tail_gap: float = 6.0
@export var screen_bottom_margin: float = 90.0
@export var input_cooldown: float = 0.2                    # ignores input right after start (avoids the same Space press skipping line 1)
@export var skip_actions: Array[StringName] = [&"ui_accept"]
@export var offset_3d: Vector3 = Vector3(0, 2.0, 0)        # bubble anchor above a 3D target
@export var offset_2d: Vector2 = Vector2(0, -90)           # bubble anchor above a 2D target

@onready var bubble: Control = $Bubble
@onready var text: TypewriterLabel = %Text
@onready var skip_icon: Control = %SkipIcon

var is_active := false
var _lines: Array = []
var _index := -1
var _target: Node = null
var _cooldown := 0.0


func _ready() -> void:
	visible = false
	skip_icon.modulate.a = 0.0
	text.line_finished.connect(_on_line_finished)


func start(lines: Array, target: Node = null) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = -1
	_target = target
	_cooldown = input_cooldown
	is_active = true
	visible = true
	dialogue_started.emit()
	_next_line()


func _next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		_end()
		return
	line_changed.emit(_index)
	var raw := str(_lines[_index])

	# Size the bubble to the text so it hugs it like your design
	var font := text.get_theme_font("normal_font")
	var font_size := text.get_theme_font_size("normal_font_size")
	var w := font.get_string_size(raw, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	text.custom_minimum_size.x = clampf(w + 12.0, 80.0, max_text_width)

	skip_icon.modulate.a = 1.0   # arrow shows while the line is typing
	text.type_text("[center]%s[/center]" % raw)

	bubble.reset_size()
	await get_tree().process_frame
	if is_active:
		bubble.reset_size()


func _on_line_finished() -> void:
	skip_icon.modulate.a = 0.0   # arrow hides when the line is finished


func _end() -> void:
	is_active = false
	visible = false
	dialogue_finished.emit()


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if not is_active:
		return
	var vp := get_viewport_rect().size
	var tip := Vector2(vp.x * 0.5, vp.y - screen_bottom_margin)   # where the tail points
	if _target != null and is_instance_valid(_target):
		var p: Variant = _world_to_screen(_target)
		if p != null:
			tip = p
	bubble.position = Vector2(tip.x - bubble.size.x * 0.5, tip.y - bubble.size.y - tail_gap)
	bubble.position.x = clampf(bubble.position.x, 16.0, maxf(16.0, vp.x - bubble.size.x - 16.0))
	bubble.position.y = maxf(bubble.position.y, 16.0)


func _world_to_screen(n: Node) -> Variant:
	if n is Node3D:
		var cam := get_viewport().get_camera_3d()
		if cam == null:
			return null
		var world: Vector3 = (n as Node3D).global_position + offset_3d
		if cam.is_position_behind(world):
			return null
		return cam.unproject_position(world)
	if n is Node2D:
		return (n as Node2D).get_global_transform_with_canvas().origin + offset_2d
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or _cooldown > 0.0:
		return
	var pressed := false
	for a in skip_actions:
		if event.is_action_pressed(a):
			pressed = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if text.typing:
		text.skip()
	else:
		_next_line()
