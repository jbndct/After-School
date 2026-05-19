# res://scripts/sugal_roulette.gd
extends Control

@onready var number_strip = $MainContainer/VBox/WheelWindow/StripContainer/NumberStrip
@onready var center_selector = $MainContainer/VBox/WheelWindow/CenterSelector
@onready var wheel_window = $MainContainer/VBox/WheelWindow

@onready var btn_red = $MainContainer/VBox/BettingGrid/BtnRed
@onready var btn_green = $MainContainer/VBox/BettingGrid/BtnGreen
@onready var btn_black = $MainContainer/VBox/BettingGrid/BtnBlack

@onready var balance_label = $MainContainer/VBox/BottomControls/StatsBox/BalanceLabel
@onready var result_label = $MainContainer/VBox/BottomControls/StatsBox/ResultLabel
@onready var bet_dropdown = $MainContainer/VBox/BottomControls/BetDropdown
@onready var btn_spin = $MainContainer/VBox/BottomControls/BtnSpin
@onready var btn_back = $MainContainer/VBox/TopBar/BtnBack

var hub_controller: Node = null
var bet_amounts: Array[int] = [10, 20, 50, 100]
var current_bet: int = 20
var selected_color: String = ""
var is_spinning: bool = false

const TILE_WIDTH = 80
const TILE_GAP = 4
const TOTAL_TILES = 60 

func _ready() -> void:
	_setup_ui()
	_update_balance()
	_generate_initial_strip()

func _setup_ui() -> void:
	for amount in bet_amounts:
		bet_dropdown.add_item("₱" + str(amount))
	bet_dropdown.select(1)
	
	btn_red.pressed.connect(_on_bet_selected.bind("RED", btn_red))
	btn_green.pressed.connect(_on_bet_selected.bind("GREEN", btn_green))
	btn_black.pressed.connect(_on_bet_selected.bind("BLACK", btn_black))
	
	bet_dropdown.item_selected.connect(func(idx): current_bet = bet_amounts[idx])
	btn_spin.pressed.connect(_on_spin_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	
	btn_spin.disabled = true

func _on_bet_selected(color: String, active_btn: Button) -> void:
	if is_spinning: return
	selected_color = color
	btn_spin.disabled = false
	
	btn_red.modulate = Color(1, 1, 1, 0.5)
	btn_green.modulate = Color(1, 1, 1, 0.5)
	btn_black.modulate = Color(1, 1, 1, 0.5)
	active_btn.modulate = Color(1, 1, 1, 1.0) 
	
	var tween = create_tween()
	tween.tween_property(active_btn, "modulate", Color("#d4af37"), 0.2)

func _update_balance() -> void:
	balance_label.text = "VIP BALANCE: ₱" + str(RunState.money)

func _on_back_pressed() -> void:
	if is_spinning: return
	if hub_controller: hub_controller.return_to_menu()

func _generate_initial_strip() -> void:
	_clear_strip()
	for i in range(15): 
		var color = _get_random_color()
		var num = str(randi_range(1, 36)) if color != "GREEN" else "0"
		_add_tile_to_strip(num, color)
	number_strip.position.x = 0

func _clear_strip() -> void:
	for child in number_strip.get_children():
		child.queue_free()

func _add_tile_to_strip(num: String, color: String) -> void:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(TILE_WIDTH, 140)
	
	var style = StyleBoxFlat.new()
	if color == "RED": style.bg_color = Color("#cc0000")
	elif color == "BLACK": style.bg_color = Color("#222222")
	else: style.bg_color = Color("#008800")
	
	style.set_corner_radius_all(8)
	style.border_width_bottom = 4
	style.border_color = Color(0,0,0,0.5)
	panel.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = num
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	
	panel.add_child(lbl)
	number_strip.add_child(panel)

func _get_random_color() -> String:
	var roll = randf()
	if roll < 0.027: return "GREEN" # Exactly 1/37 odds (insanely rare)
	elif roll < 0.5135: return "RED"
	else: return "BLACK"

func _on_spin_pressed() -> void:
	if is_spinning or RunState.money < current_bet: return
	
	RunState.money -= current_bet
	_update_balance()
	if hub_controller: hub_controller.increment_play_count()
	
	is_spinning = true
	btn_spin.disabled = true
	btn_back.disabled = true
	bet_dropdown.disabled = true
	result_label.text = "NO MORE BETS..."
	result_label.add_theme_color_override("font_color", Color.WHITE)
	
	var rtp = hub_controller.get_rigging_rtp() if hub_controller else 1.0
	var forced_loss = rtp < 1.0
	
	var target_color = ""
	var near_miss_color = ""
	
	if forced_loss:
		target_color = "BLACK" if selected_color == "RED" else "RED"
		near_miss_color = selected_color # Put what they bet right next to the loser
	else:
		target_color = selected_color
		near_miss_color = "BLACK" if selected_color == "RED" else "RED"
		
	_execute_spin(target_color, near_miss_color, forced_loss)

func _execute_spin(target_color: String, near_miss_color: String, forced_loss: bool) -> void:
	_clear_strip()
	
	# Generate random tiles for the blur
	for i in range(TOTAL_TILES - 5):
		var c = _get_random_color()
		var n = str(randi_range(1, 36)) if c != "GREEN" else "0"
		_add_tile_to_strip(n, c)
		
	# Target Index 55: The Tile it lands on
	var win_num = "0" if target_color == "GREEN" else str(randi_range(1, 36))
	_add_tile_to_strip(win_num, target_color)
	
	# Target Index 56: The Near Miss Tile
	var miss_num = "0" if near_miss_color == "GREEN" else str(randi_range(1, 36))
	_add_tile_to_strip(miss_num, near_miss_color)
	
	# Pad the end
	for i in range(3):
		var c = _get_random_color()
		var n = str(randi_range(1, 36)) if c != "GREEN" else "0"
		_add_tile_to_strip(n, c)
		
	number_strip.position.x = 0
	
	var target_index = TOTAL_TILES - 5
	var tile_total_width = TILE_WIDTH + TILE_GAP
	var window_center = wheel_window.size.x / 2.0
	
	# Calculate exactly where to place the strip to center Tile 55
	var final_x = -(target_index * tile_total_width) + window_center - (TILE_WIDTH / 2.0)
	
	var random_offset = 0.0
	if forced_loss:
		# Pushes the strip left so the selector line stops at the extreme right edge of the losing tile, barely missing the winning tile next to it.
		random_offset = randf_range(25.0, 38.0) 
	else:
		random_offset = randf_range(-15.0, 15.0)
		
	final_x -= random_offset
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(number_strip, "position:x", final_x, 5.0) 
	
	await tween.finished
	_end_spin(target_color)

func _end_spin(landed_color: String) -> void:
	if landed_color == selected_color:
		var multiplier = 7 if landed_color == "GREEN" else 2
		var win_amt = current_bet * multiplier
		RunState.money += win_amt
		result_label.text = "WINNER! +₱" + str(win_amt)
		result_label.add_theme_color_override("font_color", Color("#00ff00"))
	else:
		result_label.text = "LOSER. LANDED ON " + landed_color
		result_label.add_theme_color_override("font_color", Color("#ff3333"))
		
	_update_balance()
	is_spinning = false
	btn_spin.disabled = false
	btn_back.disabled = false
	bet_dropdown.disabled = false
