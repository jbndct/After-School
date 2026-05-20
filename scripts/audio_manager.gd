# res://singleton/AudioManager.gd
extends Node

@onready var bgm_player_1 = $BGMPlayer1
@onready var bgm_player_2 = $BGMPlayer2
@onready var sfx_player = $SFXPlayer

var active_bgm_player = 1
var current_track_path: String = ""

# Helper to find the correct file extension
func _get_valid_path(base_path: String) -> String:
	if ResourceLoader.exists(base_path + ".ogg"): return base_path + ".ogg"
	if ResourceLoader.exists(base_path + ".wav"): return base_path + ".wav"
	if ResourceLoader.exists(base_path + ".mp3"): return base_path + ".mp3"
	return ""

func play_bgm(track_name: String) -> void:
	var path = _get_valid_path("res://assets/audio/bgm/" + track_name)
	
	if path == "":
		push_error("AUDIO MANAGER: BGM track missing for " + track_name)
		return
		
	if current_track_path == path:
		return 
		
	current_track_path = path
	var stream = load(path)
	
	var fade_out_player = bgm_player_1 if active_bgm_player == 1 else bgm_player_2
	var fade_in_player = bgm_player_2 if active_bgm_player == 1 else bgm_player_1
	
	fade_in_player.stream = stream
	fade_in_player.volume_db = -80.0
	fade_in_player.play()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(fade_out_player, "volume_db", -80.0, 1.5)
	tween.tween_property(fade_in_player, "volume_db", 0.0, 1.5)
	
	active_bgm_player = 2 if active_bgm_player == 1 else 1

func play_sfx(sfx_name: String) -> void:
	var path = _get_valid_path("res://assets/audio/sfx/" + sfx_name)
	
	if path != "":
		var temp_player = AudioStreamPlayer.new()
		temp_player.stream = load(path)
		temp_player.bus = "SFX"
		add_child(temp_player)
		temp_player.play()
		temp_player.finished.connect(temp_player.queue_free)
	else:
		push_error("AUDIO MANAGER: SFX missing for " + sfx_name)
