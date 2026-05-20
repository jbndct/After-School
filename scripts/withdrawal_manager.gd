# res://singleton/WithdrawalManager.gd
extends CanvasLayer

@onready var overlay = $Overlay
@onready var danger_box = $Overlay/DangerBox
@onready var btn_play = $Overlay/DangerBox/MarginContainer/VBox/BtnContainer/BtnPlay
@onready var btn_resist = $Overlay/DangerBox/MarginContainer/VBox/BtnContainer/BtnResist
@onready var notif_sound = $NotifSound

var time_since_last_attack: float = 0.0
var next_attack_threshold: float = 9999.0
var valid_scenes: Array = ["room", "street", "school"]

func _ready() -> void:
	overlay.hide()
	btn_play.pressed.connect(_on_give_in)
	btn_resist.pressed.connect(_on_resist)
	_calculate_next_threshold()

func _process(delta: float) -> void:
	var visits = GameState.sugal_visits if "sugal_visits" in GameState else 0
	if visits == 0: return # Do nothing if they've never played
	
	var current_scene = get_tree().current_scene
	if not current_scene: return
	
	var scene_name = current_scene.name.to_lower()
	var in_valid_scene = false
	for valid in valid_scenes:
		if scene_name.begins_with(valid):
			in_valid_scene = true
			break
			
	if not in_valid_scene or overlay.visible: return
	
	# Do not interrupt if they are already in a dialogue
	if "is_dialog_active" in DialogManager and DialogManager.is_dialog_active:
		return
		
	time_since_last_attack += delta
	if time_since_last_attack >= next_attack_threshold:
		_trigger_attack()

func _calculate_next_threshold() -> void:
	time_since_last_attack = 0.0
	var visits = GameState.sugal_visits if "sugal_visits" in GameState else 0
	
	if visits <= 2:
		next_attack_threshold = randf_range(75.0, 105.0) # Approx 90s
	elif visits <= 4:
		next_attack_threshold = randf_range(45.0, 75.0) # Approx 60s
	else:
		next_attack_threshold = randf_range(20.0, 40.0) # Approx 30s

func _trigger_attack() -> void:
	overlay.show()
	overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.2)
	
	if notif_sound.stream != null:
		notif_sound.play()
		
	_shake_camera()

func _shake_camera() -> void:
	var cam = get_viewport().get_camera_2d()
	if cam:
		var orig_offset = cam.offset
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		for i in range(12):
			tween.tween_property(cam, "offset", orig_offset + Vector2(randf_range(-15, 15), randf_range(-15, 15)), 0.04)
		tween.tween_property(cam, "offset", orig_offset, 0.04)

func _on_give_in() -> void:
	overlay.hide()
	RunState.set_meta("withdrawal_debuff", false) # Cure the debuff
	_calculate_next_threshold()
	
	# Save position and teleport
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		RunState.interruption_return_x = players[0].global_position.x
		
	GameState.last_scene_path = get_tree().current_scene.scene_file_path
	SceneManager.load_scene("sugal")

func _on_resist() -> void:
	overlay.hide()
	RunState.set_meta("withdrawal_debuff", true) # Apply slow-walk penalty
	_calculate_next_threshold()
