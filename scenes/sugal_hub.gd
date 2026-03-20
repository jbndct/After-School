extends Control

const COLS = 6
const ROWS = 5
const SYMBOLS = ["🍋", "🍊", "🍇", "💎", "7️⃣", "⭐"]
const WIN_THRESHOLD = 8
const CELL_SIZE = 64
const GAP = 8

@onready var game_board = $HBoxContainer/GameBoard
@onready var balance_label = $HBoxContainer/PanelContainer/VBoxContainer/BalanceLabel
@onready var win_label = $HBoxContainer/PanelContainer/VBoxContainer/WinLabel
@onready var spin_button = $HBoxContainer/PanelContainer/VBoxContainer/SpinButton
@onready var exit_button = $HBoxContainer/PanelContainer/VBoxContainer/ExitButton

var current_bet: int = 100
var grid_nodes: Array = [] # 2D array to track [col][row]
var spin_total_win: int = 0

func _ready() -> void:
	# 1. Setup the 2D array and draw the static background slots
	for c in range(COLS):
		grid_nodes.append([])
		for r in range(ROWS):
			grid_nodes[c].append(null)
			
			var slot = Panel.new()
			slot.position = get_cell_pos(c, r)
			slot.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0.4)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			slot.add_theme_stylebox_override("panel", style)
			game_board.add_child(slot)

	spin_button.pressed.connect(_on_spin_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	GameState.sugal_opened = true
	GameState.sugal_session_active = true
	update_ui()

# Math helper to find the exact pixel location of a grid coordinate
func get_cell_pos(col: int, row: int) -> Vector2:
	return Vector2(col * (CELL_SIZE + GAP), row * (CELL_SIZE + GAP))

func _on_spin_pressed() -> void:
	if GameState.hand < current_bet:
		win_label.text = "Insufficient funds. Take a loan?"
		return

	GameState.deduct_money(current_bet)
	GameState.sugal_total_lost += current_bet
	win_label.text = "Spinning..."
	spin_button.disabled = true
	spin()

func spin() -> void:
	spin_total_win = 0
	win_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Clear existing board visuals with an explosive scale tween
	var clear_tween = create_tween().set_parallel(true)
	for c in range(COLS):
		for r in range(ROWS):
			var lbl = grid_nodes[c][r]
			if lbl:
				clear_tween.tween_property(lbl, "scale", Vector2.ZERO, 0.2)
				lbl.queue_free()
			grid_nodes[c][r] = null
			
	if clear_tween.get_tween_count() > 0:
		await clear_tween.finished

	# Spawn the initial grid falling from above
	var drop_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	for c in range(COLS):
		for r in range(ROWS):
			var lbl = spawn_symbol(c, r)
			# Teleport it high above the screen
			lbl.position.y -= 500 + (r * 50) 
			# Tween it down to its actual position
			drop_tween.tween_property(lbl, "position", get_cell_pos(c, r), 0.6 + (r * 0.1))
	
	await drop_tween.finished
	await process_cascades()

func spawn_symbol(col: int, row: int) -> Label:
	var lbl = Label.new()
	lbl.text = SYMBOLS.pick_random()
	lbl.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 38)
	
	# Pivot in the center so it scales neatly when exploding
	lbl.pivot_offset = Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
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

	var winning_symbols = []
	for sym in counts:
		if counts[sym] >= WIN_THRESHOLD:
			winning_symbols.append(sym)

	if winning_symbols.size() > 0:
		for sym in winning_symbols:
			var multiplier = 1.0 + ((counts[sym] - WIN_THRESHOLD) * 0.5)
			spin_total_win += int(current_bet * multiplier)
			
		win_label.text = "CASCADE! Win so far: ₱" + str(spin_total_win)
		await get_tree().create_timer(0.4).timeout
		
		# Explode winning symbols visually
		var explode_tween = create_tween().set_parallel(true)
		for c in range(COLS):
			for r in range(ROWS):
				var lbl = grid_nodes[c][r]
				if lbl and lbl.text in winning_symbols:
					explode_tween.tween_property(lbl, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
					
		await explode_tween.finished
		
		# Delete them from memory and the 2D array
		for c in range(COLS):
			for r in range(ROWS):
				var lbl = grid_nodes[c][r]
				if lbl and lbl.text in winning_symbols:
					lbl.queue_free()
					grid_nodes[c][r] = null
					
		await apply_gravity()
		await process_cascades()
		
	else:
		if spin_total_win > 0:
			GameState.add_money(spin_total_win)
			win_label.text = "TOTAL WIN: ₱" + str(spin_total_win)
			win_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			win_label.text = "No win."
			win_label.add_theme_color_override("font_color", Color.GRAY)

		update_ui()
		spin_button.disabled = false

func apply_gravity() -> void:
	var gravity_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var has_movement = false
	
	for c in range(COLS):
		var empty_spaces = 0
		# Read column bottom to top
		for r in range(ROWS - 1, -1, -1):
			var lbl = grid_nodes[c][r]
			if lbl == null:
				empty_spaces += 1
			elif empty_spaces > 0:
				# Move existing symbol down
				var new_row = r + empty_spaces
				grid_nodes[c][new_row] = lbl
				grid_nodes[c][r] = null
				gravity_tween.tween_property(lbl, "position", get_cell_pos(c, new_row), 0.25)
				has_movement = true
		
		# Spawn new symbols to fill the empty void at the top
		for i in range(empty_spaces):
			var new_row = (empty_spaces - 1) - i
			var lbl = spawn_symbol(c, new_row)
			lbl.position.y -= 400 + (i * 50) # Start above screen
			gravity_tween.tween_property(lbl, "position", get_cell_pos(c, new_row), 0.3 + (i * 0.1)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
			has_movement = true

	if has_movement:
		await gravity_tween.finished
		await get_tree().create_timer(0.2).timeout # Brief pause before checking new wins

func update_ui() -> void:
	balance_label.text = "E-Pera: ₱" + str(GameState.hand)

func _on_exit_pressed() -> void:
	GameState.sugal_session_active = false
	get_tree().change_scene_to_file("res://scenes/guardpost.tscn")
