# res://singleton/AudioManager.gd
extends Node

@onready var bgm_player_1 = $BGMPlayer1
@onready var bgm_player_2 = $BGMPlayer2
@onready var sfx_player = $SFXPlayer

var active_bgm_player = 1
var current_track_path: String = ""

func play_bgm(track_name: String) -> void:
	var path = "res://assets/audio/bgm/" + track_name + ".ogg"
	
	if current_track_path == path:
		return # Do not restart the track if it's already playing
		
	if not ResourceLoader.exists(path):
		push_error("AUDIO MANAGER: BGM track missing at " + path)
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
	var path = "res://assets/audio/sfx/" + sfx_name + ".ogg"
	if ResourceLoader.exists(path):
		# Spawns a temporary audio player so multiple SFX can overlap
		var temp_player = AudioStreamPlayer.new()
		temp_player.stream = load(path)
		temp_player.bus = "SFX"
		add_child(temp_player)
		temp_player.play()
		temp_player.finished.connect(temp_player.queue_free)
	else:
		push_error("AUDIO MANAGER: SFX missing at " + path)

# --- GLOBAL TRIGGERS ---
# You can call these anywhere in your project like this:
# AudioManager.play_bgm("bgm_sugal")
# AudioManager.play_sfx("sfx_ui_click")
