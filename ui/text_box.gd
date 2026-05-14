# res://ui/text_box.gd
extends MarginContainer

@onready var label = $MarginContainer/Label
@onready var timer = $LetterDisplayTimer

const MAX_WIDTH = 300
var text_to_show = ""
var letter_index = 0
var letter_time = 0.02
var space_time = 0.06
var punctuation_time = 0.2

signal finished_displaying()

func _ready() -> void:
	# Force connection via code to guarantee it works regardless of Editor settings
	if timer and not timer.timeout.is_connected(_on_letter_display_timer_timeout):
		timer.timeout.connect(_on_letter_display_timer_timeout)

func display_text(text_input: String):
	if not is_node_ready():
		await ready
		
	text_to_show = text_input
	letter_index = 0
	custom_minimum_size = Vector2.ZERO
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text = text_to_show
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized
		await resized
		custom_minimum_size.y = size.y
	
	label.text = ""
	_display_letter()
	
func _display_letter():
	if letter_index >= text_to_show.length():
		return
		
	label.text += text_to_show[letter_index]
	letter_index += 1
	
	if letter_index >= text_to_show.length():
		finished_displaying.emit()
		return
		
	match text_to_show[letter_index]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)

func finish_typing_instantly():
	if letter_index < text_to_show.length():
		label.text = text_to_show
		letter_index = text_to_show.length()
		timer.stop()
		finished_displaying.emit()
	
func _on_letter_display_timer_timeout() -> void:
	_display_letter()
