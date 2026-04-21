extends Node2D

@export var falling_item_scene: PackedScene
@onready var spawn_timer = $SpawnTimer
@onready var items_container = $ItemsContainer

# --- NEW: UI References ---
@onready var score_label = $UI/MarginContainer/HBoxContainer/ScoreLabel
@onready var stress_bar = $UI/MarginContainer/HBoxContainer/VBoxContainer/StressBar

var screen_width: float
var current_spawn_rate: float = 1.5
var current_fall_speed: float = 300.0

var score: int = 0
var stress: int = 0
var max_stress: int = 3
var win_score: int = 15

func _ready() -> void:
	screen_width = get_viewport_rect().size.x
	
	# Initialize UI
	stress_bar.max_value = max_stress
	stress_bar.value = 0
	score_label.text = "Composure: %d / %d" % [score, win_score]
	
	spawn_timer.wait_time = current_spawn_rate
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if not falling_item_scene:
		return
		
	var item = falling_item_scene.instantiate()
	var random_x = randf_range(50.0, screen_width - 50.0)
	item.position = Vector2(random_x, -150.0) 
	
	var is_bad = randf() < 0.30
	item.is_hazard = is_bad
	item.fall_speed = current_fall_speed
	
	var sprite = item.get_node("Sprite2D")
	if is_bad:
		sprite.modulate = Color(0.9, 0.2, 0.2) 
	else:
		sprite.modulate = Color(0.2, 0.8, 0.9) 
		
	items_container.add_child(item)
	ramp_difficulty()

func ramp_difficulty() -> void:
	if current_spawn_rate > 0.5:
		current_spawn_rate -= 0.02
		spawn_timer.wait_time = current_spawn_rate
	current_fall_speed += 5.0

func on_item_caught(is_hazard: bool) -> void:
	if is_hazard:
		stress += 1
		
		# POLISH: Smoothly fill the stress bar using a Tween
		var tween = create_tween()
		tween.tween_property(stress_bar, "value", stress, 0.3).set_trans(Tween.TRANS_SINE)
		
		if stress >= max_stress:
			game_over(false)
	else:
		score += 1
		# Update the label dynamically
		score_label.text = "Composure: %d / %d" % [score, win_score]
		
		if score >= win_score:
			game_over(true)

func game_over(won: bool) -> void:
	spawn_timer.stop() 
	
	if won:
		print("MINIGAME WON! Returning to Work.")
	else:
		print("MINIGAME LOST! Stress overwhelmed you.")
		GameState.failed_minigame = true # Trigger the failure flag
	
	GameState.advance_scene()
