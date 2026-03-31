extends Node2D

@onready var dialogue_box = $DialogueBox
@onready var canvas_modulate = $CanvasModulate # Make sure you added this node!

func _ready() -> void:
	setup_street_state()

func setup_street_state() -> void:
	var dialogue_lines = []
	
	# We check BOTH the part and the step index to know exactly where we are in the flow
	match GameState.current_part:
		1:
			if GameState.current_step_index == 1: # Going from Room to School
				set_time("day")
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "If I don't pass this scholarship exam, I'm getting dropped." }
				]
			elif GameState.current_step_index == 4: # Going from School back to Room
				set_time("night")
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Finally done. Need to head home." }
				]
		2:
			if GameState.current_step_index == 1: # Going from Room to School
				set_time("day")
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Another day. Need to find work later." }
				]
			elif GameState.current_step_index == 3: # Going from School to Workplace
				set_time("afternoon")
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Time for the interview. Hope I don't mess this up." }
				]
			elif GameState.current_step_index == 6: # Going from Workplace back home
				set_time("night")
				dialogue_lines = [
					{ "speaker": "Dominador", "text": "Exhausted. Let's just go home." }
				]
		# Add Part 3 and 4 logic here following the same pattern
				
	if dialogue_lines.size() > 0:
		dialogue_box.play(dialogue_lines)

func set_time(time_of_day: String) -> void:
	match time_of_day:
		"day":
			canvas_modulate.color = Color(1, 1, 1, 1) # Normal lighting
		"afternoon":
			canvas_modulate.color = Color(0.9, 0.7, 0.5, 1) # Orange/warm tint
		"night":
			canvas_modulate.color = Color(0.3, 0.3, 0.6, 1) # Dark blue tint

# Hook this up to the Area2D at the end of your street
func _on_exit_area_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameState.advance_scene()
