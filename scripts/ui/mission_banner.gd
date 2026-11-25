extends Control
## Top-center mission banner.
##   $MissionBanner.show_mission("Go outside.")     -> fades in, types "Mission: Go outside."
##   $MissionBanner.hide_mission()

signal mission_shown   # emitted when typing finishes
signal mission_hidden

@export var fade_time: float = 0.25

@onready var text: TypewriterLabel = %Text

var _tween: Tween


func _ready() -> void:
	modulate.a = 0.0
	visible = false
	text.line_finished.connect(func() -> void: mission_shown.emit())


func show_mission(message: String, title: String = "Mission:") -> void:
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_time)
	# text is set right away (so the box is sized), typing starts after the fade
	text.type_text("[b]%s[/b] %s" % [title, message], fade_time)


func hide_mission() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(_after_hide)


func _after_hide() -> void:
	visible = false
	mission_hidden.emit()
