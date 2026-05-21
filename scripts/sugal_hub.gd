# res://scripts/sugal_hub.gd
extends MinigameBase

@onready var background = $Background
@onready var game_container = $GameContainer
@onready var menu_ui = $MenuUI
@onready var grid_container = $MenuUI/VBox/Grid
@onready var btn_slots = $MenuUI/VBox/Grid/BtnSlots
@onready var btn_parlay = $MenuUI/VBox/Grid/BtnParlay
@onready var btn_roulette = $MenuUI/VBox/Grid/BtnRoulette
@onready var btn_exit = $MenuUI/VBox/BtnExit

@onready var withdrawal_overlay = $WithdrawalOverlay
@onready var panic_label = $WithdrawalOverlay/PanicLabel
@onready var thought_label = $WithdrawalOverlay/IntrusiveThoughtLabel
@onready var moving_exit_btn = $WithdrawalOverlay/MovingExitButton
@onready var fake_buttons_container = $WithdrawalOverlay/FakeButtonsContainer

var required_exit_clicks: int = 0
var current_exit_clicks: int = 0
var withdrawal_active: bool = false
var is_exiting: bool = false
var move_timer: Timer

var active_game_instance: Node = null

func _ready() -> void:
	AudioManager.play_bgm("bgm_sugal")
	
	minigame_id = "sugal"
	reward_amount = 0
	is_active = true 
	
	if "is_dialog_active" in DialogManager:
		DialogManager.is_dialog_active = false
		
	GameState.sugal_opened = true
	GameState.sugal_session_active = true
	
	_setup_button_connections()
	_setup_withdrawal_system()
	
	withdrawal_overlay.hide()
	show_menu()

func _setup_button_connections() -> void:
	btn_slots.pressed.connect(_on_game_selected.bind("res://scenes/sugal_slots.tscn"))
	btn_parlay.pressed.connect(_on_game_selected.bind("res://scenes/sugal_parlay.tscn"))
	btn_roulette.pressed.connect(_on_game_selected.bind("res://scenes/sugal_roulette.tscn"))
	btn_exit.pressed.connect(_on_cash_out_pressed)
	
	var all_btns = [btn_slots, btn_parlay, btn_roulette, btn_exit]
	for btn in all_btns:
		btn.button_down.connect(func(): btn.add_theme_color_override("font_color", Color.BLACK))
		btn.button_up.connect(func(): btn.remove_theme_color_override("font_color"))

func _setup_withdrawal_system() -> void:
	move_timer = Timer.new()
	move_timer.wait_time = 1.0
	move_timer.timeout.connect(_move_all_buttons)
	add_child(move_timer)
	
	moving_exit_btn.pressed.connect(_on_moving_exit_pressed)
	for fake_btn in fake_buttons_container.get_children():
		if fake_btn is Button:
			fake_btn.pressed.connect(_on_trap_button_pressed)

func show_menu() -> void:
	menu_ui.show()
	menu_ui.modulate.a = 0.0
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(menu_ui, "modulate:a", 1.0, 0.6)

func _on_game_selected(scene_path: String) -> void:
	AudioManager.play_sfx("sfx_ui_click")
	if ResourceLoader.exists(scene_path):
		var game_scene = load(scene_path)
		active_game_instance = game_scene.instantiate()
		if "hub_controller" in active_game_instance:
			active_game_instance.hub_controller = self
		game_container.add_child(active_game_instance)
		menu_ui.hide()
	else:
		AudioManager.play_sfx("sfx_error_buzz")
		_shake_ui(menu_ui)

func return_to_menu() -> void:
	if active_game_instance:
		active_game_instance.queue_free()
		active_game_instance = null
	show_menu()

func get_rigging_rtp() -> float:
	var total_plays = RunState.get_meta("sugal_plays") if RunState.has_meta("sugal_plays") else 0
	var phase = total_plays % 10

	# Win probability per phase
	var win_chance: float
	match phase:
		0: win_chance = 0.95  # near-guaranteed hook
		1: win_chance = 0.75  # still feels good
		2: win_chance = 0.50  # coin flip, player doesn't notice the drop yet
		3: win_chance = 0.20  # first cold streak hits
		4: win_chance = 0.10  # brutal drought
		5: win_chance = 0.10  # still nothing
		6: win_chance = 0.10  # rock bottom
		7: win_chance = 0.35  # tease — feels like it's coming back
		8: win_chance = 0.20  # rug pull — false hope crushed
		9: win_chance = 0.65  # strong close so cycle 2 feels promising
		_: win_chance = 0.10

	if randf() < win_chance:
		return 1.5  # win — whatever your standard payout multiplier is
	return 0.0      # loss

func increment_play_count() -> void:
	var total_plays = RunState.get_meta("sugal_plays") if RunState.has_meta("sugal_plays") else 0
	RunState.set_meta("sugal_plays", total_plays + 1)
	RunState.gambling_attempted = true

func _on_cash_out_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	if withdrawal_active: return
	
	# Increment the actual visit tracker first
	GameState.sugal_visits += 1
	
	# Add 2 so Visit 1 requires 3 clicks, Visit 2 requires 4, etc.
	required_exit_clicks = GameState.sugal_visits + 2
	
	if required_exit_clicks <= 0:
		execute_exit()
		return
	
	withdrawal_active = true
	current_exit_clicks = 0
	menu_ui.hide()
	withdrawal_overlay.show()
	withdrawal_overlay.modulate.a = 0
	AudioManager.play_sfx("sfx_heartbeat_fast")
	
	var tween = create_tween()
	tween.tween_property(withdrawal_overlay, "modulate:a", 1.0, 0.3)
	panic_label.text = "Ayoko pa umalis. Ansaya pala nito. \n CLICK 'CONFIRM EXIT' TO LEAVE\nPROGRESS: 0/" + str(required_exit_clicks)
	_move_all_buttons()
	move_timer.start()

func _move_all_buttons() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	moving_exit_btn.position = Vector2(randf_range(50, screen_size.x - 200), randf_range(100, screen_size.y - 100))
	for fake_btn in fake_buttons_container.get_children():
		if fake_btn is Button:
			fake_btn.position = Vector2(randf_range(50, screen_size.x - 200), randf_range(100, screen_size.y - 100))

func _on_moving_exit_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	current_exit_clicks += 1
	if current_exit_clicks >= required_exit_clicks: 
		execute_exit()
	else:
		panic_label.text = "Ayoko pa umalis. Ansaya pala nito. \n CLICK 'CONFIRM EXIT' TO LEAVE\nPROGRESS: " + str(current_exit_clicks) + "/" + str(required_exit_clicks)
		_move_all_buttons()
		move_timer.start()

func _on_trap_button_pressed() -> void:
	AudioManager.play_sfx("sfx_error_buzz")
	panic_label.text = "Ayoko pa umalis. Ansaya pala nito. \n CLICK 'CONFIRM EXIT' TO LEAVE\nPROGRESS: 0/" + str(required_exit_clicks)
	current_exit_clicks = 0
	thought_label.text = "Ador: Just one more bet... maybe I can win it back."
	_move_all_buttons()
	move_timer.start()
	_shake_ui(withdrawal_overlay)

func _shake_ui(node: Control) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var orig_pos = node.position
	tween.tween_property(node, "position:x", orig_pos.x - 10, 0.05)
	tween.tween_property(node, "position:x", orig_pos.x + 10, 0.05)
	tween.tween_property(node, "position:x", orig_pos.x - 10, 0.05)
	tween.tween_property(node, "position:x", orig_pos.x, 0.05)

func execute_exit() -> void:
	if is_exiting: return
	is_exiting = true
	GameState.sugal_session_active = false
	move_timer.stop()
	finish_game(true)
