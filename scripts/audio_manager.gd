# res://singleton/AudioManager.gd
extends Node

@onready var bgm_player_1 = $BGMPlayer1
@onready var bgm_player_2 = $BGMPlayer2
# We are ignoring the manual $SFXPlayer node in the scene. 
# We will generate a clean, fixed-size memory pool dynamically.

var active_bgm_player = 1
var current_track_path: String = ""

const MAX_SFX_PLAYERS = 12
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_index = 0

func _ready() -> void:
	# Pre-allocate our Audio Pool to prevent dynamic node leakage
	for i in range(MAX_SFX_PLAYERS):
		var p = AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		sfx_pool.append(p)

func play_bgm(track_name: String) -> void:
	# Strip extension if passed accidentally to prevent double extensions
	var clean_name = track_name.get_basename()
	var path = "res://assets/audio/bgm/" + clean_name + ".ogg"
	
	if current_track_path == path:
		return 
		
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
	# Strip extension to prevent .ogg.ogg or .wav.ogg traps
	var clean_name = sfx_name.get_basename()
	var base_path = "res://assets/audio/sfx/" + clean_name
	
	var path = ""
	# Check for .ogg first, fallback to .wav if it exists
	if ResourceLoader.exists(base_path + ".ogg"):
		path = base_path + ".ogg"
	elif ResourceLoader.exists(base_path + ".wav"):
		path = base_path + ".wav"
	else:
		push_error("AUDIO MANAGER: SFX missing at " + base_path)
		return
		
	var stream: AudioStream = load(path)
	
	# Brutal memory override: If an OGG slipped through with Loop enabled, forcefully kill the loop
	# so it doesn't hijack our Audio Pool voices forever.
	if stream is AudioStreamOggVorbis:
		stream.loop = false
		
	# Grab the next available player in the pool (Round-Robin assignment)
	var player = sfx_pool[sfx_pool_index]
	player.stream = stream
	player.play()
	
	# Advance index and wrap around
	sfx_pool_index = (sfx_pool_index + 1) % MAX_SFX_PLAYERS

# --- GLOBAL TRIGGERS ---
# You can call these anywhere in your project like this:
# AudioManager.play_bgm("bgm_sugal")
# AudioManager.play_sfx("sfx_ui_click")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		print("DEBUG: Spacebar pressed. Firing test SFX...")
		play_sfx("sfx_ui_click")
