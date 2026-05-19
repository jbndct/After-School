# res://scripts/sugal_slots.gd
extends Control

const COLS = 6
const ROWS = 5
const CELL_SIZE = 64
const GAP = 8
const SYMBOLS = ["👸", "✋", "🤰", "🐈‍⬛", "🪼", "🐔", "🙀"]
const WIN_THRESHOLD = 8

@onready var game_board = $MainVBox/GridCenter/GridFrame/GameBoard
@onready var balance_label = $MainVBox/BottomBar/MarginContainer/HBoxContainer/StatsBox/BalanceLabel
@onready var win_label = $MainVBox/BottomBar/MarginContainer/HBoxContainer/StatsBox/WinLabel
@onready var bet_dropdown = $MainVBox/BottomBar/MarginContainer/HBoxContainer/BetDropdown
@onready var btn_spin = $MainVBox/BottomBar/MarginContainer/HBoxContainer/BtnSpin
@onready var btn_back = $MainVBox/BottomBar/MarginContainer/HBoxContainer/BtnBack

var hub_controller: Node = null
var grid_nodes: Array = []
var bet_amounts: Array[int] = [10, 100, 500, 1000, 5000]
var current_bet: int = 100
var spin_total_win: int = 0
var is_spinning: bool = false

func _ready() -> void:
	_setup_grid()
	_setup_ui()
	_update_balance_display()
	
	_drop_new_symbols()

func _setup_grid() -> void:
	for c in range(COLS):
		grid_nodes.append([])
		for r in range(ROWS):
			grid_nodes[c].append(null)
			var slot_bg = Panel.new()
			slot_bg.position = get_cell_pos(c, r)
			slot_bg.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.6)
			style.set_corner_radius_all(6)
			slot_bg.add_theme_stylebox_override("panel", style)
			game_board.add_child(slot_bg)

func _setup_ui() -> void:
	for amount in bet_amounts:
		bet_dropdown.add_item("₱" + str(amount))
	
	# Set default to index 1 (₱100)
	bet_dropdown.select(1)
	current_bet = bet_amounts[1]
	
	bet_dropdown.item_selected.connect(func(idx): current_bet = bet_amounts[idx])
	btn_spin.pressed.connect(_on_spin_pressed)
	btn_back.pressed.connect(_on_back_pressed)

func _update_balance_display() -> void:
	balance_label.text = "VIP BALANCE: ₱" + str(RunState.money)

func get_cell_pos(col: int, row: int) -> Vector2:
	return Vector2(col * (CELL_SIZE + GAP), row * (CELL_SIZE + GAP))

func _on_back_pressed() -> void:
	if is_spinning: return
	if hub_controller:
		hub_controller.return_to_menu()

func _on_spin_pressed() -> void:
	if is_spinning: return
	if RunState.money < current_bet:
		win_label.text = "INSUFFICIENT FUNDS"
		win_label.add_theme_color_override("font_color", Color.RED)
		return
		
	RunState.money -= current_bet
	_update_balance_display()
	
	if hub_controller:
		hub_controller.increment_play_count()
		
	is_spinning = true
	spin_total_win = 0
	win_label.text = "SPINNING..."
	win_label.add_theme_color_override("font_color", Color.WHITE)
	btn_spin.disabled = true
	btn_back.disabled = true
	bet_dropdown.disabled = true
	
	_clear_board()

func _clear_board() -> void:
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
			
	_drop_new_symbols()

# --- PSYCHOLOGICAL RIGGING & DROP ---
func _drop_new_symbols() -> void:
	var rtp = hub_controller.get_rigging_rtp() if hub_controller else 1.0
	var force_win = rtp > 1.0
	var force_loss = rtp < 1.0
	
	var symbol_pool = _generate_rigged_pool(force_win, force_loss)
	
	var drop_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	for c in range(COLS):
		for r in range(ROWS):
			var sym = symbol_pool.pop_front()
			var lbl = _create_symbol_label(c, r, sym)
			lbl.position.y -= 500 + (r * 50)
			drop_tween.tween_property(lbl, "position", get_cell_pos(c, r), 0.5 + (c * 0.1)) # Cascading fall effect
	
	await drop_tween.finished
	await _process_cascades()

func _generate_rigged_pool(force_win: bool, force_loss: bool) -> Array:
	var pool = []
	var total_slots = COLS * ROWS # 30
	
	if force_loss:
		# NEAR MISS GENERATOR: Create exactly 7 of one symbol, 6 of another. Total chaos for rest.
		var tease_sym = SYMBOLS.pick_random()
		var secondary_sym = SYMBOLS.pick_random()
		while secondary_sym == tease_sym: secondary_sym = SYMBOLS.pick_random()
		
		for i in range(7): pool.append(tease_sym)
		for i in range(6): pool.append(secondary_sym)
		
		var safe_symbols = SYMBOLS.duplicate()
		safe_symbols.erase(tease_sym)
		
		while pool.size() < total_slots:
			var rand_sym = safe_symbols.pick_random()
			# Ensure we don't accidentally create an 8-match
			if pool.count(rand_sym) < 7: 
				pool.append(rand_sym)
	
	elif force_win:
		# GUARANTEED HIT: Inject 8 to 11 of a single symbol
		var win_sym = SYMBOLS.pick_random()
		var win_count = randi_range(8, 11)
		for i in range(win_count): pool.append(win_sym)
		while pool.size() < total_slots:
			pool.append(SYMBOLS.pick_random())
			
	else:
		# True Random
		for i in range(total_slots): pool.append(SYMBOLS.pick_random())
		
	pool.shuffle()
	return pool

func _create_symbol_label(col: int, row: int, sym: String) -> Label:
	var lbl = Label.new()
	lbl.text = sym
	lbl.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 42)
	
	# Premium shadow for symbols
	lbl.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 4)
	
	lbl.position = get_cell_pos(col, row)
	game_board.add_child(lbl)
	grid_nodes[col][row] = lbl
	return lbl

func _process_cascades() -> void:
	var counts = {}
	for c in range(COLS):
		for r in range(ROWS):
			if grid_nodes[c][r]:
				var sym = grid_nodes[c][r].text
				counts[sym] = counts.get(sym, 0) + 1

	var winning = []
	for sym in counts:
		if counts[sym] >= WIN_THRESHOLD: winning.append(sym)

	if winning.size() > 0:
		for sym in winning: 
			# Multiplier based on how many extra symbols they got
			var overage = counts[sym] - WIN_THRESHOLD
			var payout = int(current_bet * (1.5 + (overage * 0.5)))
			spin_total_win += payout
			
		win_label.text = "SCATTER HIT! Win: ₱" + str(spin_total_win)
		win_label.add_theme_color_override("font_color", Color("#d4af37"))
		
		# Animate the pop
		var pop_tween = create_tween().set_parallel(true)
		for c in range(COLS):
			for r in range(ROWS):
				if grid_nodes[c][r] and grid_nodes[c][r].text in winning:
					pop_tween.tween_property(grid_nodes[c][r], "scale", Vector2(1.5, 1.5), 0.2)
					pop_tween.tween_property(grid_nodes[c][r], "modulate:a", 0.0, 0.3).set_delay(0.1)
					
		await pop_tween.finished
		
		for c in range(COLS):
			for r in range(ROWS):
				if grid_nodes[c][r] and grid_nodes[c][r].text in winning:
					grid_nodes[c][r].queue_free()
					grid_nodes[c][r] = null
					
		await _apply_gravity()
		await _process_cascades()
		
	else:
		_end_spin()

func _apply_gravity() -> void:
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
			var sym = SYMBOLS.pick_random() # New symbols falling in are true random
			var lbl = _create_symbol_label(c, new_r, sym)
			lbl.position.y -= 400 + (i * 60)
			gravity_tween.tween_property(lbl, "position", get_cell_pos(c, new_r), 0.35)
			has_movement = true

	if has_movement:
		await gravity_tween.finished
		await get_tree().create_timer(0.1).timeout

func _end_spin() -> void:
	if spin_total_win > 0:
		RunState.money += spin_total_win
		win_label.text = "TOTAL WIN: ₱" + str(spin_total_win)
		win_label.add_theme_color_override("font_color", Color("#00ff00"))
	else:
		win_label.text = "NO WIN"
		win_label.add_theme_color_override("font_color", Color("#888888"))

	_update_balance_display()
	is_spinning = false 
	btn_spin.disabled = false
	btn_back.disabled = false
	bet_dropdown.disabled = false
