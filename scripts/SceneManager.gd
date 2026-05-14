# res://scripts/SceneManager.gd
extends Node

const SCENES = {
	"menu": "res://scenes/Menu.tscn",
	"room": "res://scenes/room.tscn",
	"street": "res://scenes/street.tscn",
	"school": "res://scenes/school.tscn",
	"scholarship": "res://scenes/MinigameScholarship.tscn",
	"work": "res://scenes/workplace.tscn",
	"ending": "res://scenes/ending.tscn",
	"sugal": "res://scenes/SugalHub.tscn"
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

func advance_story(current_location: String) -> void:
	var phase = RunState.current_phase
	RunState.previous_location = current_location
	
	match current_location:
		"room":
			if phase == "morning":
				load_scene("street")
			elif phase == "night":
				load_scene("ending")
				
		"street":
			if phase == "morning":
				load_scene("school")
			elif phase == "afternoon":
				RunState.current_phase = "night"
				load_scene("room")
				
		"school":
			RunState.current_phase = "afternoon"
			load_scene("street")
			
		"scholarship":
			load_scene("school") 
			
		"work":
			load_scene("room")
			
		_:
			push_error("SCENE MANAGER: Unhandled story advancement from -> " + current_location)
