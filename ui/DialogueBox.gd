extends CanvasLayer

@onready var speaker_label = $PanelContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_text = $PanelContainer/VBoxContainer/DialogueText

var lines: Array = []
var current_line: int = 0
var is_typing: bool = false
var full_text: String = ""
var displayed_text: String = ""
var char_index: int = 0
var on_complete: Callable

var timer: Timer

signal dialogue_finished

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = 0.03
	timer.one_shot = false
	timer.timeout.connect(_on_timer_tick)
	add_child(timer)
	visible = false

func play(new_lines: Array, callback: Callable = Callable()) -> void:
	lines = new_lines
	current_line = 0
	on_complete = callback
	visible = true
	_show_line(0)

func _show_line(index: int) -> void:
	var line = lines[index]
	speaker_label.text = line.get("speaker", "")
	full_text = line.get("text", "")
	displayed_text = ""
	char_index = 0
	is_typing = true
	dialogue_text.text = ""
	timer.start()

func _on_timer_tick() -> void:
	if char_index < full_text.length():
		displayed_text += full_text[char_index]
		dialogue_text.text = displayed_text
		char_index += 1
	else:
		is_typing = false
		timer.stop()

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Check for left mouse click OR the 'E' key (interact action)
	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var is_interact_key = event.is_action_pressed("interact")
	
	if is_click or is_interact_key:
		# Consume the input so other nodes don't use it
		get_viewport().set_input_as_handled() 
		
		if is_typing:
			# skip to full text
			displayed_text = full_text
			dialogue_text.text = full_text
			is_typing = false
			timer.stop()
		else:
			# advance to next line
			current_line += 1
			if current_line < lines.size():
				_show_line(current_line)
			else:
				visible = false
				emit_signal("dialogue_finished")
				if on_complete.is_valid():
					on_complete.call()
