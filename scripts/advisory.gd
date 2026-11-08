extends Control

func _ready() -> void:
	# 1. Force the screen to start completely invisible (transparent)
	self.modulate.a = 0.0
	
	# 2. Create one master Tween to handle the entire sequence
	var tween = create_tween()
	
	# 3. Fade IN: transition alpha from 0.0 to 1.0 over 1.5 seconds
	tween.tween_property(self, "modulate:a", 1.0, 1.5)
	
	# 4. HOLD: Keep it visible for 8 seconds so they can read the warning
	tween.tween_interval(8.0)
	
	# 5. Fade OUT: transition alpha from 1.0 back to 0.0 over 1.5 seconds
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	
	# 6. Once the entire sequence (fade in -> hold -> fade out) finishes, switch scenes
	tween.finished.connect(_on_fade_finished)

func _on_fade_finished() -> void:
	# Switch to Diego's 5-slide intro
	if ResourceLoader.exists("res://scenes/IntroStory.tscn"):
		get_tree().change_scene_to_file("res://scenes/IntroStory.tscn")
