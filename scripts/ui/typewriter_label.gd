class_name TypewriterLabel
extends RichTextLabel
## RichTextLabel that types its text out letter by letter with a blip sound.
## Usage: label.type_text("Hello [b]world[/b]")   label.skip()   await label.line_finished

signal line_finished

@export var chars_per_second: float = 45.0
@export var punctuation_pause: float = 0.12   # extra pause after , . ! ? ; :
@export var blip_every: int = 2               # play a blip every N letters
@export var pitch_variation: float = 0.08     # random pitch so it doesn't sound robotic
@export var blip_sound: AudioStream           # drag your short typing blip here
@export var blip_volume_db: float = -10.0
@export var blip_bus: StringName = &"SFX"     # falls back to Master if no bus has this name

var typing := false

var _plain := ""
var _total := 0
var _clock := 0.0
var _pause := 0.0
var _letters := 0
var _player: AudioStreamPlayer


func _ready() -> void:
	bbcode_enabled = true
	set_process(false)
	_player = AudioStreamPlayer.new()
	_player.stream = blip_sound
	_player.volume_db = blip_volume_db
	_player.max_polyphony = 3
	_player.bus = blip_bus if AudioServer.get_bus_index(blip_bus) != -1 else &"Master"
	add_child(_player)


## Sets the text immediately (so layouts size correctly) and types it out.
## delay = seconds to wait before the first letter appears.
func type_text(bbcode: String, delay: float = 0.0) -> void:
	text = bbcode
	_plain = get_parsed_text()
	_total = _plain.length()
	visible_characters = 0
	_clock = 0.0
	_pause = delay
	_letters = 0
	typing = _total > 0
	set_process(typing)
	if not typing:
		visible_characters = -1
		line_finished.emit()


## Instantly show the whole line.
func skip() -> void:
	if typing:
		_finish()


func _process(delta: float) -> void:
	if not typing:
		return
	if _pause > 0.0:
		_pause -= delta
		return
	_clock += delta
	var step := 1.0 / maxf(chars_per_second, 1.0)
	while _clock >= step and visible_characters < _total:
		_clock -= step
		var ch := _plain[visible_characters]
		visible_characters += 1
		_blip(ch)
		if ch in ",.!?;:":
			_pause = punctuation_pause
			break
	if visible_characters >= _total:
		_finish()


func _blip(ch: String) -> void:
	if blip_sound == null or ch.strip_edges() == "":
		return
	_letters += 1
	if _letters % maxi(blip_every, 1) != 0:
		return
	_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	_player.play()


func _finish() -> void:
	typing = false
	set_process(false)
	visible_characters = -1
	line_finished.emit()
