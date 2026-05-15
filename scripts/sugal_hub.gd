# res://scripts/sugal_hub.gd
extends MinigameBase

const COLS = 6
const ROWS = 5
const SYMBOLS = ["👸", "✋", "🤰", "🐈‍⬛", "🪼", "🐔", "🙀"]
const WIN_THRESHOLD = 8
const CELL_SIZE = 64
const GAP = 8

@onready var game_board = $HBoxContainer/GameBoard
@onready var balance_label = $HBoxContainer/PanelContainer/VBoxContainer/BalanceLabel
@onready var win_label = $HBoxContainer/PanelContainer/VBoxContainer/WinLabel
@onready var spin_button = $HBoxContainer/PanelContainer/VBoxContainer/SpinButton
@onready var bet_dropdown = $HBoxContainer/PanelContainer/VBoxContainer/BetDropdown
@onready var real_exit_button = $HBoxContainer/PanelContainer/VBoxContainer/RealExitButton

@onready var withdrawal_overlay = $WithdrawalOverlay
@onready var panic_label = $WithdrawalOverlay/PanicLabel
@onready var thought_label = $WithdrawalOverlay/IntrusiveThoughtLabel
@onready var moving_exit_btn = $WithdrawalOverlay/MovingExitButton
@onready var fake_buttons_container = $WithdrawalOverlay/FakeButtonsContainer

@onready var lobby_ui = $LobbyUI
@onready var sports_ui = $SportsUI

var bet_amounts: Array[int] = [10, 100, 500, 1000, 5000]
var current_bet: int = 1000

var grid_nodes: Array = []
var spin_total_win: int = 0
var starting_money: int = 0
var is_spinning: bool = false
var is_exiting: bool = false
var withdrawal_active: bool = false
var required_exit_clicks: int = 0
var current_exit_clicks: int = 0
var move_timer: Timer

# Sports Betting Vars (Conservative Math)
var sports_bet_amount: int = 500
var all_nba_teams: Array[String] = ["LAKERS", "WARRIORS", "BULLS", "HEAT", "CELTICS", "KNICKS", "SUNS", "BUCKS", "MAVS", "NUGGETS", "SPURS", "CLIPPERS", "NETS", "76ERS", "CAVS", "THUNDER"]
var sports_matches: Array = []
var parlay_selections: Dictionary = {}
# NERFED PAYOUTS: Extremely hard to get rich now.
var multipliers = [0.0, 1.05, 1.25, 1.6, 2.5, 4.0] 
var is_simulating: bool = false

# Casino Theme Styles
var style_bg = StyleBoxFlat.new()
var style_btn_normal = StyleBoxFlat.new()
var style_btn_pressed = StyleBoxFlat.new()

func setup_game() -> void:
	minigame_id = "sugal"
	reward_amount = 0
	
	# CRITICAL BUG FIX: Force-kill any lingering dialogue from the Autoload
	if "is_dialog_active" in DialogManager:
		DialogManager.is_dialog_active = false
	
	starting_money = RunState.money
	GameState.sugal_opened = true
	GameState.sugal_session_active = true
	
	_init_casino_theme()
	
	$HBoxContainer.hide()
	withdrawal_overlay.hide()
	build_lobby_ui()
	build_sports_ui()
	show_lobby()
	
	for c in range(COLS):
		grid_nodes.append([])
		for r in range(ROWS):
			grid_nodes[c].append(null)
			var slot = Panel.new()
			slot.position = get_cell_pos(c, r)
			slot.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.4)
			style.set_corner_radius_all(6)
			slot.add_theme_stylebox_override("panel", style)
			game_board.add_child(slot)

	spin_button.pressed.connect(_on_spin_pressed)
	spin_button.focus_mode = Control.FOCUS_NONE
	
	real_exit_button.text = "BACK TO LOBBY"
	real_exit_button.focus_mode = Control.FOCUS_NONE
	real_exit_button.pressed.connect(show_lobby)
	
	move_timer = Timer.new()
	move_timer.wait_time = 1.2
	move_timer.timeout.connect(_move_all_buttons)
	add_child(move_timer)
	
	moving_exit_btn.pressed.connect(_on_moving_exit_pressed)
	for fake_btn in fake_buttons_container.get_children():
		if fake_btn is Button:
			fake_btn.pressed.connect(_on_trap_button_pressed)
			
	for amount in bet_amounts:
		bet_dropdown.add_item("₱" + str(amount))
	
	bet_dropdown.item_selected.connect(func(idx): current_bet = bet_amounts[idx])
	bet_dropdown.focus_mode = Control.FOCUS_NONE
	
	required_exit_clicks = GameState.sugal_visits
	GameState.sugal_visits += 1
	
	start_game()

func _init_casino_theme() -> void:
	style_bg.bg_color = Color("#0b1d3a")
	style_bg.border_width_left = 4
	style_bg.border_width_right = 4
	style_bg.border_width_top = 4
	style_bg.border_width_bottom = 4
	style_bg.border_color = Color("#d4af37")
	
	style_btn_normal.bg_color = Color("#112b56")
	style_btn_normal.border_width_left = 2
	style_btn_normal.border_width_right = 2
	style_btn_normal.border_width_top = 2
	style_btn_normal.border_width_bottom = 2
	style_btn_normal.border_color = Color("#d4af37")
	style_btn_normal.set_corner_radius_all(8)
	
	style_btn_pressed.bg_color = Color("#d4af37")
	style_btn_pressed.set_corner_radius_all(8)

func get_rig_state() -> String:
	var total_plays = RunState.get_meta("sugal_plays") if RunState.has_meta("sugal_plays") else 0
	RunState.set_meta("sugal_plays", total_plays + 1)
	
	if total_plays == 0: return "GUARANTEED_WIN"
	elif total_plays <= 3: return "SKEWED_WIN" if randf() < 0.5 else "BRUTAL_LOSS"
	elif total_plays % 9 == 0: return "HOPE_WIN" # Longer gap between hope wins
	else: return "BRUTAL_LOSS" if randf() < 0.90 else "SKEWED_WIN" # Much higher loss chance

func show_lobby() -> void:
	if is_simulating: return
	$HBoxContainer.hide()
	sports_ui.hide()
	lobby_ui.show()
	lobby_ui.add_theme_stylebox_override("panel", style_bg)
	update_ui()

func build_lobby_ui() -> void:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby_ui.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "SUGALHUB"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#d4af37"))
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Choose your Game"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	vbox.add_child(subtitle)
	
	var btn_spin = _create_styled_button("🎰 SKUTTER")
	btn_spin.pressed.connect(func(): lobby_ui.hide(); $HBoxContainer.show(); update_ui())
	vbox.add_child(btn_spin)
	
	var btn_sports = _create_styled_button("🏀 PARLEIGH")
	btn_sports.pressed.connect(func(): 
		_generate_random_matches()
		lobby_ui.hide()
		sports_ui.show()
		refresh_sports_ui()
	)
	vbox.add_child(btn_sports)
	
	var btn_exit = _create_styled_button("CASH OUT (EXIT)")
	btn_exit.pressed.connect(_on_real_exit_pressed)
	vbox.add_child(btn_exit)

func _create_styled_button(txt: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.focus_mode = Control.FOCUS_NONE # CRITICAL: Prevents ghost spacebar inputs
	btn.custom_minimum_size = Vector2(350, 70)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.BLACK)
	btn.add_theme_stylebox_override("normal", style_btn_normal)
	btn.add_theme_stylebox_override("hover", style_btn_normal)
	btn.add_theme_stylebox_override("pressed", style_btn_pressed)
	return btn

func _generate_random_matches() -> void:
	sports_matches.clear()
	parlay_selections.clear()
	var pool = all_nba_teams.duplicate()
	pool.shuffle()
	
	for i in range(5):
		sports_matches.append({"a": pool.pop_back(), "b": pool.pop_back()})

func build_sports_ui() -> void:
	sports_ui.add_theme_stylebox_override("panel", style_bg)
	
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	sports_ui.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.name = "SportsVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	center.add_child(vbox)

func refresh_sports_ui() -> void:
	var vbox = sports_ui.get_node("CenterContainer/SportsVBox")
	for child in vbox.get_children(): child.queue_free()
		
	var bal = Label.new()
	bal.text = "VIP BALANCE: ₱" + str(RunState.money)
	bal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bal.add_theme_font_size_override("font_size", 28)
	bal.add_theme_color_override("font_color", Color("#d4af37"))
	vbox.add_child(bal)
	
	var legs = parlay_selections.size()
	var mult = multipliers[legs] if legs <= 5 else 0.0
	var title = Label.new()
	title.text = "BUILD YOUR PARLAY\n" + str(legs) + " Legs Selected | Potential Payout: x" + str(mult)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	for i in range(sports_matches.size()):
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 20)
		
		var btn_a = _create_styled_button(sports_matches[i]["a"])
		var btn_b = _create_styled_button(sports_matches[i]["b"])
		btn_a.custom_minimum_size = Vector2(200, 50)
		btn_b.custom_minimum_size = Vector2(200, 50)
		
		if parlay_selections.has(i) and parlay_selections[i] == 0: btn_a.add_theme_stylebox_override("normal", style_btn_pressed)
		if parlay_selections.has(i) and parlay_selections[i] == 1: btn_b.add_theme_stylebox_override("normal", style_btn_pressed)
		
		btn_a.pressed.connect(func(): _toggle_leg(i, 0))
		btn_b.pressed.connect(func(): _toggle_leg(i, 1))
		
		hbox.add_child(btn_a)
		var vs = Label.new()
		vs.text = " @ "
		hbox.add_child(vs)
		hbox.add_child(btn_b)
		vbox.add_child(hbox)
		
	var controls_hbox = HBoxContainer.new()
	controls_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_hbox.add_theme_constant_override("separation", 20)
	
	var back_btn = _create_styled_button("BACK")
	back_btn.custom_minimum_size = Vector2(150, 60)
	back_btn.pressed.connect(show_lobby)
	controls_hbox.add_child(back_btn)
	
	var place_btn = _create_styled_button("PLACE ₱" + str(sports_bet_amount) + " BET")
	place_btn.custom_minimum_size = Vector2(300, 60)
	if legs == 0 or RunState.money < sports_bet_amount: place_btn.disabled = true
	place_btn.pressed.connect(_start_live_ticker)
	controls_hbox.add_child(place_btn)
	
	vbox.add_child(controls_hbox)

func _toggle_leg(match_idx: int, team_idx: int) -> void:
	if parlay_selections.has(match_idx) and parlay_selections[match_idx] == team_idx:
		parlay_selections.erase(match_idx)
	else:
		parlay_selections[match_idx] = team_idx
	refresh_sports_ui()

func _start_live_ticker() -> void:
	if is_simulating: return
	is_simulating = true
	RunState.money -= sports_bet_amount
	RunState.gambling_attempted = true
	
	var state = get_rig_state()
	var legs = parlay_selections.size()
	var win_amount = int(sports_bet_amount * multipliers[legs])
	var is_winning_bet = (state == "GUARANTEED_WIN" or state == "HOPE_WIN" or state == "SKEWED_WIN")
	
	var match_targets = {}
	var selected_keys = parlay_selections.keys()
	
	for i in range(legs):
		var match_idx = selected_keys[i]
		var player_picked_b = parlay_selections[match_idx] == 1
		
		if not is_winning_bet and i == legs - 1:
			var base_score = randi_range(98, 110)
			if player_picked_b: match_targets[match_idx] = {"a": base_score + 1, "b": base_score}
			else: match_targets[match_idx] = {"a": base_score, "b": base_score + 1}
		else:
			var base_score = randi_range(100, 115)
			var margin = randi_range(5, 12)
			if player_picked_b: match_targets[match_idx] = {"a": base_score - margin, "b": base_score}
			else: match_targets[match_idx] = {"a": base_score, "b": base_score - margin}
	
	_build_live_ticker_ui(match_targets, is_winning_bet, win_amount)

func _build_live_ticker_ui(targets: Dictionary, will_win: bool, win_amount: int) -> void:
	var vbox = sports_ui.get_node("CenterContainer/SportsVBox")
	for child in vbox.get_children(): child.queue_free()
		
	var title = Label.new()
	title.text = "LIVE MATCH TRACKER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	var labels_dict = {}
	
	for match_idx in targets.keys():
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var lbl = Label.new()
		lbl.text = sports_matches[match_idx]["a"] + " 0 - 0 " + sports_matches[match_idx]["b"]
		lbl.add_theme_font_size_override("font_size", 28)
		hbox.add_child(lbl)
		vbox.add_child(hbox)
		labels_dict[match_idx] = lbl
		
	for match_idx in targets.keys():
		var tween = create_tween()
		var final_a = targets[match_idx]["a"]
		var final_b = targets[match_idx]["b"]
		var player_picked_b = (parlay_selections[match_idx] == 1)
		
		tween.tween_method(
			func(progress: float): _update_score_label(labels_dict[match_idx], match_idx, progress * final_a, progress * final_b), 
			0.0, 1.0, 1.5
		)
		
		tween.tween_callback(func():
			var player_won_leg = (final_b > final_a) if player_picked_b else (final_a > final_b)
			if player_won_leg:
				labels_dict[match_idx].add_theme_color_override("font_color", Color.LIGHT_GREEN)
			else:
				labels_dict[match_idx].add_theme_color_override("font_color", Color.LIGHT_CORAL)
		)
		
		await tween.finished
		await get_tree().create_timer(0.3).timeout
	
	var result_lbl = Label.new()
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 36)
	
	if will_win:
		RunState.money += win_amount
		result_lbl.text = "PARLAY HIT! YOU WON ₱" + str(win_amount)
		result_lbl.add_theme_color_override("font_color", Color.GREEN)
	else:
		result_lbl.text = "BET LOST. SO CLOSE..."
		result_lbl.add_theme_color_override("font_color", Color.RED)
		
	vbox.add_child(result_lbl)
	
	var cont_btn = _create_styled_button("CONTINUE")
	cont_btn.pressed.connect(func(): is_simulating = false; parlay_selections.clear(); refresh_sports_ui())
	vbox.add_child(cont_btn)

func _update_score_label(lbl: Label, match_idx: int, score_a: float, score_b: float) -> void:
	lbl.text = sports_matches[match_idx]["a"] + " " + str(int(score_a)) + " - " + str(int(score_b)) + " " + sports_matches[match_idx]["b"]

func get_cell_pos(col: int, row: int) -> Vector2:
	return Vector2(col * (CELL_SIZE + GAP), row * (CELL_SIZE + GAP))

func _on_spin_pressed() -> void:
	if withdrawal_active: return
	if RunState.money < current_bet: return
	
	RunState.gambling_attempted = true
	RunState.money -= current_bet
	win_label.text = "Spinning..."
	spin_button.disabled = true
	real_exit_button.disabled = true
	
	spin()

func spin() -> void:
	is_spinning = true
	spin_total_win = 0
	win_label.add_theme_color_override("font_color", Color.WHITE)
	
	var state = get_rig_state()
	var clear_tween = create_tween().set_parallel(true)
	var has_old = false
	for c in range(COLS):
		for r in range(ROWS):
			if grid_nodes[c][r]:
				has_old = true
				clear_tween.tween_property(grid_nodes[c][r], "scale", Vector2.ZERO, 0.2)
			
	if has_old:
		await clear_tween.finished
		for child in game_board.get_children():
			if child is Label: child.queue_free()
		for c in range(COLS):
			for r in range(ROWS): grid_nodes[c][r] = null

	var drop_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	for c in range(COLS):
		for r in range(ROWS):
			var lbl = spawn_symbol(c, r, state)
			lbl.position.y -= 500 + (r * 50)
			drop_tween.tween_property(lbl, "position", get_cell_pos(c, r), 0.6 + randf_range(0.0, 0.3))
	
	await drop_tween.finished
	await process_cascades()

func spawn_symbol(col: int, row: int, state: String) -> Label:
	var lbl = Label.new()
	var sym = ""
	
	if state == "GUARANTEED_WIN" or state == "HOPE_WIN":
		sym = SYMBOLS[0] if randf() < 0.6 else SYMBOLS.pick_random()
	elif state == "BRUTAL_LOSS":
		var subset = SYMBOLS.duplicate()
		subset.shuffle()
		sym = subset[row % 3]
	else:
		sym = SYMBOLS.pick_random()
				
	lbl.text = sym
	lbl.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.position = get_cell_pos(col, row)
	
	game_board.add_child(lbl)
	grid_nodes[col][row] = lbl
	return lbl

func process_cascades() -> void:
	var counts = {}
	for c in range(COLS):
		for r in range(ROWS):
			var sym = grid_nodes[c][r].text
			counts[sym] = counts.get(sym, 0) + 1

	var winning = []
	for sym in counts:
		if counts[sym] >= WIN_THRESHOLD: winning.append(sym)

	if winning.size() > 0:
		for sym in winning: spin_total_win += int(current_bet * 1.5)
			
		win_label.text = "CASCADE! Win so far: ₱" + str(spin_total_win)
		await get_tree().create_timer(0.4).timeout
		
		for c in range(COLS):
			for r in range(ROWS):
				if grid_nodes[c][r] and grid_nodes[c][r].text in winning:
					grid_nodes[c][r].queue_free()
					grid_nodes[c][r] = null
					
		await apply_gravity()
		await process_cascades()
		
	else:
		if spin_total_win > 0:
			RunState.money += spin_total_win
			win_label.text = "TOTAL WIN: ₱" + str(spin_total_win)
		else:
			win_label.text = "No win."

		update_ui()
		is_spinning = false 
		if not withdrawal_active:
			spin_button.disabled = false
			real_exit_button.disabled = false

func apply_gravity() -> void:
	var gravity_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var has_movement = false
	
	for c in range(COLS):
		var empty = 0
		for r in range(ROWS - 1, -1, -1):
			if grid_nodes[c][r] == null:
				empty += 1
			elif empty > 0:
				var new_r = r + empty
				grid_nodes[c][new_r] = grid_nodes[c][r]
				grid_nodes[c][r] = null
				gravity_tween.tween_property(grid_nodes[c][new_r], "position", get_cell_pos(c, new_r), 0.25)
				has_movement = true
		
		for i in range(empty):
			var new_r = (empty - 1) - i
			var lbl = spawn_symbol(c, new_r, "NORMAL")
			lbl.position.y -= 400 + (i * 50)
			gravity_tween.tween_property(lbl, "position", get_cell_pos(c, new_r), 0.3)
			has_movement = true

	if has_movement:
		await gravity_tween.finished
		await get_tree().create_timer(0.2).timeout

func update_ui() -> void:
	balance_label.text = "VIP BALANCE: ₱" + str(RunState.money)

func _on_real_exit_pressed() -> void:
	if withdrawal_active: return
	if required_exit_clicks <= 0:
		execute_exit()
		return
	
	withdrawal_active = true
	current_exit_clicks = 0
	$HBoxContainer.hide()
	lobby_ui.hide()
	sports_ui.hide()
	withdrawal_overlay.show()
	
	panic_label.text = "CLICK 'CONFIRM EXIT' " + str(required_exit_clicks) + " TIMES TO LEAVE\nPROGRESS: 0/" + str(required_exit_clicks)
	_move_all_buttons()
	move_timer.start()

func _move_all_buttons() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	moving_exit_btn.position = Vector2(randf_range(50, screen_size.x - 200), randf_range(100, screen_size.y - 100))
	for fake_btn in fake_buttons_container.get_children():
		if fake_btn is Button:
			fake_btn.position = Vector2(randf_range(50, screen_size.x - 200), randf_range(100, screen_size.y - 100))
	
func _on_moving_exit_pressed() -> void:
	current_exit_clicks += 1
	if current_exit_clicks >= required_exit_clicks: execute_exit()
	else:
		panic_label.text = "CLICK 'CONFIRM EXIT' " + str(required_exit_clicks) + " TIMES TO LEAVE\nPROGRESS: " + str(current_exit_clicks) + "/" + str(required_exit_clicks)
		_move_all_buttons()
		move_timer.start()

func _on_trap_button_pressed() -> void:
	current_exit_clicks = 0
	thought_label.text = "Juan: Hand slipped... just one more try."
	_move_all_buttons()
	move_timer.start()

func execute_exit() -> void:
	if is_exiting: return
	is_exiting = true
	GameState.sugal_session_active = false
	move_timer.stop()
	finish_game(true)
