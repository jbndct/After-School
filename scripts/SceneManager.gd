extends Node

# ==============================================================================
# THE SCENE DIRECTOR
# Maps explicit keys to your existing file paths. If you move a file, 
# you only update it here, nowhere else.
# ==============================================================================

const SCENES = {
	"room": "res://scenes/room.tscn",
	"street": "res://scenes/street.tscn",
	"school": "res://scenes/school.tscn",
	"scholarship": "res://scenes/MinigameScholarship.tscn",
	"work": "res://scenes/MinigameWork.tscn",
	"ending": "res://scenes/ending.tscn"
}

func load_scene(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("SCENE MANAGER FATAL: Unknown scene key -> " + scene_key)
		return
		
	var path = SCENES[scene_key]
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_error("SCENE MANAGER FATAL: File missing at -> " + path)

# ==============================================================================
# EXPLICIT NARRATIVE ROUTING
# Replaces GameState.advance_scene()
# ==============================================================================

func advance_story(current_location: String) -> void:
	var phase = RunState.current_phase
	RunState.previous_location = current_location
	
	match current_location:
		"room":
			if phase == "morning":
				load_scene("street")
			elif phase == "night":
				# After the night shift/dream minigame
				load_scene("ending")
				
		"street":
			if phase == "morning":
				load_scene("school")
			elif phase == "afternoon":
				RunState.current_phase = "night"
				load_scene("room")
				
		"school":
			# Scholarship sequence is done, time to go home
			RunState.current_phase = "afternoon"
			load_scene("street")
			
		"scholarship":
			load_scene("school") # Return to VN logic for the result
			
		"work":
			load_scene("room") # Return to room for late night VN
			
		_:
			push_error("SCENE MANAGER: Unhandled story advancement from -> " + current_location)
