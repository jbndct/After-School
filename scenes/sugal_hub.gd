extends Control

const COLS = 6
const ROWS = 5
const SYMBOLS = ["🍋", "🍊", "🍇", "💎", "7️⃣", "⭐"]
const WIN_THRESHOLD = 8 # Need 8 or more matching symbols anywhere to win

@onready var grid_container = $HBoxContainer/GridContainer
@onready var balance_label = $HBoxContainer/PanelContainer/VBoxContainer/BalanceLabel
@onready var win_label = $HBoxContainer/PanelContainer/VBoxContainer/WinLabel
@onready var spin_button = $HBoxContainer/PanelContainer/VBoxContainer/SpinButton
@onready var exit_button = $HBoxContainer/PanelContainer/VBoxContainer/ExitButton

var current_bet: int = 100
var grid_cells: Array = []

func _ready() -> void:
	# 1. Setup the physical grid cells
	grid_container.columns = COLS
	for i in range(COLS * ROWS):
		var cell = Label.new()
		cell.custom_minimum_size = Vector2(64, 64)
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_theme_font_size_override("font_size", 32)
		# Optional: Add a dark background to each cell
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.6)
		cell.add_theme_stylebox_override("normal", style)
		
		grid_container.add_child(cell)
		grid_cells.append(cell)

	# 2. Connect signals
	spin_button.pressed.connect(_on_spin_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Mark the session active in GameState
	GameState.sugal_opened = true
	GameState.sugal_session_active = true
	update_ui()

func _on_spin_pressed() -> void:
	if GameState.hand < current_bet:
		win_label.text = "Insufficient funds. Take a loan?"
		return

	# Deduct bet and track losses
	GameState.deduct_money(current_bet)
	GameState.sugal_total_lost += current_bet
	win_label.text = "Spinning..."
	spin_button.disabled = true
	
	spin()

func spin() -> void:
	# 1. Randomize grid and count symbols
	var symbol_counts = {}
	for cell in grid_cells:
		var random_sym = SYMBOLS.pick_random()
		cell.text = random_sym
		symbol_counts[random_sym] = symbol_counts.get(random_sym, 0) + 1

	# 2. Evaluate scatter wins
	evaluate_wins(symbol_counts)
	
	update_ui()
	spin_button.disabled = false

func evaluate_wins(counts: Dictionary) -> void:
	var total_win = 0
	var winning_symbols = []

	for sym in counts:
		if counts[sym] >= WIN_THRESHOLD:
			winning_symbols.append(sym)
			# Payout formula: Base multiplier + extra for every symbol over the threshold
			var multiplier = 1.0 + ((counts[sym] - WIN_THRESHOLD) * 0.5)
			total_win += int(current_bet * multiplier)

	if total_win > 0:
		GameState.add_money(total_win)
		win_label.text = "WIN: ₱" + str(total_win) + " (" + ", ".join(winning_symbols) + "x" + ")"
		win_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		win_label.text = "No win."
		win_label.add_theme_color_override("font_color", Color.GRAY)

func update_ui() -> void:
	balance_label.text = "E-Pera: ₱" + str(GameState.hand)

func _on_exit_pressed() -> void:
	GameState.sugal_session_active = false
	get_tree().change_scene_to_file("res://scenes/guardpost.tscn")
