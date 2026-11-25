extends Control
## Top-center mission banner.
##   $MissionBanner.show_mission("Go outside.")     -> fades in with a notification sound
##   $MissionBanner.hide_mission()

signal mission_shown
signal mission_hidden

@export var fade_time: float = 0.25
@export var pop_sound: AudioStream = preload("res://assets/audio/sfx/mission.wav")

@onready var text: RichTextLabel = %Text

var _tween: Tween
var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	modulate.a = 0.0
	visible = false

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.stream = pop_sound
	add_child(_sfx_player)


func show_mission(message: String, title: String = "MISSION:") -> void:
	visible = true
	text.text = "[b]%s[/b] %s" % [title, message]

	if pop_sound:
		_sfx_player.stream = pop_sound
		_sfx_player.play()

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_time)
	_tween.tween_callback(func() -> void: mission_shown.emit())


func hide_mission() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(_after_hide)


func _after_hide() -> void:
	visible = false
	mission_hidden.emit()
