extends Control

const COLS = 6
const ROWS = 5
const SYMBOLS = ["👸", "✋", "🤰", "🐈‍⬛", "🪼", "🐔", "🙀"]
const WIN_THRESHOLD = 8
const CELL_SIZE = 64
const GAP = 8

@onready var bet_dropdown = $HBoxContainer/PanelContainer/VBoxContainer/BetDropdown
var bet_amounts: Array[int] = [10, 100, 500, 1000, 5000]

@onready var game_board = $HBoxContainer/GameBoard
@onready var balance_label = $HBoxContainer/PanelContainer/VBoxContainer/BalanceLabel
@onready var win_label = $HBoxContainer/PanelContainer/VBoxContainer/WinLabel
@onready var spin_button = $HBoxContainer/PanelContainer/VBoxContainer/SpinButton

@onready var real_exit_button = $HBoxContainer/PanelContainer/VBoxContainer/RealExitButton

@onready var withdrawal_overlay = $WithdrawalOverlay
@onready var panic_label = $WithdrawalOverlay/PanicLabel
@onready var thought_label = $WithdrawalOverlay/IntrusiveThoughtLabel
@onready var moving_exit_btn = $WithdrawalOverlay/MovingExitButton
@onready var fake_buttons_container = $WithdrawalOverlay/FakeButtonsContainer

var is_spinning: bool = false
var withdrawal_active: bool = false
var required_exit_clicks: int = 0
var current_exit_clicks: int = 0
var move_timer: Timer

var current_bet: int = 1000
var grid_nodes: Array = []
var spin_total_win: int = 0
var scatter_count: int = 0
var rig_state: String = "NORMAL"
var spins_this_session: int = 0
var starting_money: int = 0
var is_exiting: bool = false

func _ready() -> void:
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
	real_exit_button.pressed.connect(_on_real_exit_pressed)
	
	GameState.sugal_opened = true
	GameState.sugal_session_active = true
	update_ui()
	starting_money = GameState.hand
	
	withdrawal_overlay.hide()
	
	move_timer = Timer.new()
	move_timer.wait_time = 1.2
	move_timer.timeout.connect(_move_all_buttons)
	add_child(move_timer)
	
	moving_exit_btn.pressed.connect(_on_moving_exit_pressed)
	
	for fake_btn in fake_buttons_container.get_children():
		if fake_btn is Button:
			fake_btn.pressed.connect(_on_trap_button_pressed)
			
	
	# Setup the betting dropdown
	for amount in bet_amounts:
		bet_dropdown.add_item("₱" + str(amount))
	
	# Connect the dropdown selection to our custom function
	bet_dropdown.item_selected.connect(_on_bet_selected)
	
	# Set the initial bet to the first tier (₱10) instead of the hardcoded 1000
	current_bet = bet_amounts[0]
	
	# Fetch the current difficulty, then increment it for the next visit
	required_exit_clicks = GameState.sugal_visits
	GameState.sugal_visits += 1

func get_cell_pos(col: int, row: int) -> Vector2:
	return Vector2(col * (CELL_SIZE + GAP), row * (CELL_SIZE + GAP))

func _on_spin_pressed() -> void:
	if withdrawal_active: return
	
	if GameState.hand < current_bet:
		win_label.text = "Insufficient funds. Take a loan?"
		return
	
	GameState.has_gambled = true
	
	GameState.deduct_money(current_bet)
	GameState.sugal_total_lost += current_bet
	win_label.text = "Spinning..."
	
	spin_button.disabled = true
	real_exit_button.disabled = true
	
	spin()

func spin() -> void:
	is_spinning = true
	spin_total_win = 0
	win_label.add_theme_color_override("font_color", Color.WHITE)
	
	# --- NEW: PREDATORY LOGIC SETUP ---
	spins_this_session += 1
	scatter_count = 0
	
	# The Honeymoon Hook: Force a massive win on their very first spin ever
	if GameState.sugal_visits == 1 and spins_this_session == 1:
		rig_state = "HONEYMOON"
	# The Mercy Drop: They are about to go broke, give them a fake lifeline
	elif GameState.hand <= current_bet and GameState.hand > 0:
		rig_state = "MERCY"
	else:
		rig_state = "NORMAL"
	# ----------------------------------
	
	var has_old_symbols = false
	var clear_tween = create_tween().set_parallel(true)
	
	for c in range(COLS):
		for r in range(ROWS):
			var lbl = grid_nodes[c][r]
			if lbl:
				has_old_symbols = true
				clear_tween.tween_property(lbl, "scale", Vector2.ZERO, 0.2)
			
	if has_old_symbols:
		await clear_tween.finished
		
		for child in game_board.get_children():
			if child is Label:
				child.queue_free()
				
		for c in range(COLS):
			for r in range(ROWS):
				grid_nodes[c][r] = null

	var drop_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	for c in range(COLS):
		for r in range(ROWS):
			var lbl = spawn_symbol(c, r)
			lbl.position.y -= 500 + (r * 50)
			
			var drop_speed = 0.6 + (r * 0.1) + randf_range(0.0, 0.3)
			drop_tween.tween_property(lbl, "position", get_cell_pos(c, r), drop_speed)
	
	await drop_tween.finished
	_shake_board()
	await process_cascades()

func spawn_symbol(col: int, row: int) -> Label:
	var lbl = Label.new()
	# --- NEW: RIGGED RNG LOGIC ---
	var chosen_symbol = ""
	
	if rig_state == "HONEYMOON":
		# 60% chance to spawn the jackpot symbol (👸) for a guaranteed massive cascade
		chosen_symbol = "👸" if randf() < 0.6 else SYMBOLS.pick_random()
	elif rig_state == "MERCY":
		# 40% chance to spawn a mid-tier symbol (✋) to prevent them from hitting exactly 0
		chosen_symbol = "✋" if randf() < 0.4 else SYMBOLS.pick_random()
	else:
		# NORMAL PREDATORY RNG
		chosen_symbol = SYMBOLS.pick_random()
		
		# The Near-Miss Scatter Tease
		if chosen_symbol == "👸":
			if scatter_count >= 2:
				# 90% chance to actively deny the 3rd scatter if they already have 2
				if randf() < 0.90:
					var non_scatters = SYMBOLS.duplicate()
					non_scatters.erase("👸")
					chosen_symbol = non_scatters.pick_random()
				else:
					scatter_count += 1
			else:
				scatter_count += 1
				
	lbl.text = chosen_symbol
	# -----------------------------
	lbl.text = SYMBOLS.pick_random()
	
	
	lbl.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 38)
	
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
		
		var explode_tween = create_tween().set_parallel(true)
		for c in range(COLS):
			for r in range(ROWS):
				var lbl = grid_nodes[c][r]
				if lbl and lbl.text in winning_symbols:
					explode_tween.tween_property(lbl, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
					
		await explode_tween.finished
		
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
			
			# --- NEW: LOSSES DISGUISED AS WINS ---
			if spin_total_win < current_bet:
				# They LOST money overall, but the machine celebrates anyway
				win_label.text = "MEGA WIN! ₱" + str(spin_total_win)
				win_label.add_theme_color_override("font_color", Color.YELLOW)
				
				# Add a manipulative pulse animation to the UI text
				win_label.pivot_offset = win_label.size / 2.0
				var pulse = create_tween().set_loops(4)
				pulse.tween_property(win_label, "scale", Vector2(1.3, 1.3), 0.1)
				pulse.tween_property(win_label, "scale", Vector2(1.0, 1.0), 0.1)
			else:
				# A true mathematical win
				win_label.text = "TOTAL WIN: ₱" + str(spin_total_win)
				win_label.add_theme_color_override("font_color", Color.GREEN)
			# -------------------------------------
		else:
			win_label.text = "No win."
			win_label.add_theme_color_override("font_color", Color.GRAY)

		update_ui()
		is_spinning = false # Unlock the board here
		
		if not withdrawal_active:
			spin_button.disabled = false
			real_exit_button.disabled = false

func apply_gravity() -> void:
	var gravity_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var has_movement = false
	
	for c in range(COLS):
		var empty_spaces = 0
		for r in range(ROWS - 1, -1, -1):
			var lbl = grid_nodes[c][r]
			if lbl == null:
				empty_spaces += 1
			elif empty_spaces > 0:
				var new_row = r + empty_spaces
				grid_nodes[c][new_row] = lbl
				grid_nodes[c][r] = null
				gravity_tween.tween_property(lbl, "position", get_cell_pos(c, new_row), 0.25)
				has_movement = true
		
		for i in range(empty_spaces):
			var new_row = (empty_spaces - 1) - i
			var lbl = spawn_symbol(c, new_row)
			lbl.position.y -= 400 + (i * 50)
			gravity_tween.tween_property(lbl, "position", get_cell_pos(c, new_row), 0.3 + (i * 0.1)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
			has_movement = true

	if has_movement:
		await gravity_tween.finished
		_shake_board()
		await get_tree().create_timer(0.2).timeout
	

func update_ui() -> void:
	balance_label.text = "E-Pera: ₱" + str(GameState.hand)
	

func _on_real_exit_pressed() -> void:
	if withdrawal_active: return
	
	# NEW: Instant exit on the first visit
	if required_exit_clicks <= 0:
		execute_exit()
		GameState.sugal_session_active = false
		
		# THE FIX: Load the previous scene instead of deleting the current one
		if GameState.last_scene_path != "":
			get_tree().change_scene_to_file(GameState.last_scene_path)
		else:
			print("CRITICAL ERROR: last_scene_path was empty! Falling back to room.")
			get_tree().change_scene_to_file("res://scenes/room.tscn")
		return
	
	withdrawal_active = true
	current_exit_clicks = 0
	thought_label.text = ""
	
	spin_button.disabled = true
	real_exit_button.disabled = true
	
	withdrawal_overlay.show()
	
	# Make the text dynamic instead of hardcoded to 10
	panic_label.text = "CLICK 'CONFIRM EXIT' " + str(required_exit_clicks) + " TIMES TO LEAVE\nPROGRESS: 0/" + str(required_exit_clicks)
	
	_move_all_buttons()
	move_timer.start()
	
func _move_all_buttons() -> void:
	var screen_size = get_viewport_rect().size
	
	var real_x = randf_range(50, screen_size.x - moving_exit_btn.size.x - 50)
	var real_y = randf_range(100, screen_size.y - moving_exit_btn.size.y - 100)
	moving_exit_btn.position = Vector2(real_x, real_y)
	
	for fake_btn in fake_buttons_container.get_children():
		if fake_btn is Button:
			var fx = randf_range(50, screen_size.x - fake_btn.size.x - 50)
			var fy = randf_range(100, screen_size.y - fake_btn.size.y - 100)
			fake_btn.position = Vector2(fx, fy)
	
func _on_moving_exit_pressed() -> void:
	current_exit_clicks += 1
	panic_label.text = "CLICK 'CONFIRM EXIT' " + str(required_exit_clicks) + " TIMES TO LEAVE\nPROGRESS: " + str(current_exit_clicks) + "/" + str(required_exit_clicks)
	
	if current_exit_clicks >= required_exit_clicks:
		execute_exit()
		move_timer.stop()
		GameState.sugal_session_active = false
		
		# THE FIX: Add error handling
		if GameState.last_scene_path != "":
			get_tree().change_scene_to_file(GameState.last_scene_path)
		else:
			print("CRITICAL ERROR: last_scene_path was empty! Falling back to room.")
			get_tree().change_scene_to_file("res://scenes/room.tscn")
	else:
		_move_all_buttons()
		move_timer.start()

func _on_trap_button_pressed() -> void:
	
	# Reset their escape pros
	current_exit_clicks = 0
	panic_label.text = "CLICK 'CONFIRM EXIT' " + str(required_exit_clicks) + " TIMES TO LEAVE\nPROGRESS: 0/" + str(required_exit_clicks)
	
	# ACTUALLY spin the board in the background to show the money burning
	if not is_spinning:
		win_label.text = "FORCED SPIN!"
		spin()
	
	# Reset their escape progress
	current_exit_clicks = 0
	panic_label.text = "CLICK 'CONFIRM EXIT' 10 TIMES TO LEAVE\nPROGRESS: 0/10"
	
	var intrusive_thoughts = [
		"Juan: Damn it, my hand slipped... just one more.",
		"Juan: I didn't mean to click that! Give it back!",
		"Juan: I have to win that back now.",
		"Juan: Why won't it just let me leave?!"
	]
	thought_label.text = intrusive_thoughts.pick_random()
	
	if GameState.hand <= 0:
		execute_exit()
	else:
		_move_all_buttons()
		move_timer.start()

func _pulse_fake_buttons() -> void:
	for fake_btn in fake_buttons_container.get_children():
		if fake_btn is Button:
			# Center the pivot so it scales from the middle
			fake_btn.pivot_offset = fake_btn.size / 2.0 
			
			var pulse_tween = create_tween().set_loops()
			# Randomize the speed slightly so they don't pulse in unison
			var speed = randf_range(0.3, 0.6) 
			pulse_tween.tween_property(fake_btn, "scale", Vector2(1.05, 1.05), speed).set_trans(Tween.TRANS_SINE)
			pulse_tween.tween_property(fake_btn, "scale", Vector2(1.0, 1.0), speed).set_trans(Tween.TRANS_SINE)

func _shake_screen() -> void:
	var original_pos = withdrawal_overlay.position
	var shake_tween = create_tween()
	
	# Jerk the screen back and forth quickly
	for i in range(5):
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		shake_tween.tween_property(withdrawal_overlay, "position", original_pos + offset, 0.05)
		
	# Return to normal
	shake_tween.tween_property(withdrawal_overlay, "position", original_pos, 0.05)

func _on_bet_selected(index: int) -> void:
	current_bet = bet_amounts[index]
	
func _shake_board() -> void:
	var target = $HBoxContainer
	# Store the baseline position so it doesn't drift away
	var original_pos = target.position 
	var shake_tween = create_tween()
	
	# Jerk it around rapidly
	for i in range(4):
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		shake_tween.tween_property(target, "position", original_pos + offset, 0.04)
		
	# Snap it exactly back to normal
	shake_tween.tween_property(target, "position", original_pos, 0.04)


# --- NEW: UNIFIED EXIT HANDLER ---
func execute_exit() -> void:
	if is_exiting:
		return
	is_exiting = true
	
	GameState.sugal_session_active = false
	move_timer.stop()
	
	if GameState.has_gambled:
		GameState.gambling_profit = GameState.hand - starting_money
		print("Gambling locked. Net profit/loss: ", GameState.gambling_profit)
	
	# --- THE BULLETPROOF FIX ---
	# We ask the global GameState to change the scene safely at the end of the frame.
	if GameState.last_scene_path != "":
		GameState.get_tree().call_deferred("change_scene_to_file", GameState.last_scene_path)
	else:
		GameState.get_tree().call_deferred("change_scene_to_file", "res://scenes/room.tscn")
