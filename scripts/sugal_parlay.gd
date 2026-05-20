# res://scripts/sugal_parlay.gd
extends Control

@onready var draft_phase = $MainContainer/VBox/DraftPhase
@onready var sim_phase = $MainContainer/VBox/SimPhase
@onready var matchups_list = $MainContainer/VBox/DraftPhase/MatchupsList
@onready var selected_teams_label = $MainContainer/VBox/DraftPhase/BetSlip/SlipVBox/SelectedTeams
@onready var odds_label = $MainContainer/VBox/DraftPhase/BetSlip/SlipVBox/OddsLabel
@onready var bet_dropdown = $MainContainer/VBox/DraftPhase/BetSlip/SlipVBox/BetDropdown
@onready var payout_label = $MainContainer/VBox/DraftPhase/BetSlip/SlipVBox/PayoutLabel
@onready var btn_lock_in = $MainContainer/VBox/DraftPhase/BetSlip/SlipVBox/BtnLockIn
@onready var btn_back = $MainContainer/VBox/TopBar/BtnBack

@onready var timer_label = $MainContainer/VBox/SimPhase/TimerLabel
@onready var live_games_list = $MainContainer/VBox/SimPhase/LiveGamesList
@onready var boost_container = $MainContainer/VBox/SimPhase/BoostContainer
@onready var btn_boost = $MainContainer/VBox/SimPhase/BoostContainer/BtnBoost
@onready var result_label = $MainContainer/VBox/SimPhase/ResultLabel

var hub_controller: Node = null
var bet_amounts: Array[int] = [10, 100, 500, 1000]
var current_bet: int = 100

var matchups: Array = []
var selected_picks: Dictionary = {}
var total_odds: float = 1.0

# Sim State
var is_simulating: bool = false
var time_remaining: float = 15.0
var live_bars: Array = []
var rigged_to_lose: bool = false
var heartbreaker_index: int = 4 
var has_boosted: bool = false

func _ready() -> void:
	_setup_draft_ui()
	_generate_matchups()
	sim_phase.hide()
	boost_container.hide()
	btn_lock_in.disabled = true
	btn_lock_in.pressed.connect(_on_lock_in_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	btn_boost.pressed.connect(_on_boost_pressed)

func _setup_draft_ui() -> void:
	for amount in bet_amounts:
		bet_dropdown.add_item("₱" + str(amount))
	bet_dropdown.select(1)
	current_bet = bet_amounts[1]
	bet_dropdown.item_selected.connect(_on_bet_changed)

func _generate_matchups() -> void:
	var teams = ["Los Angeles", "Boston", "Miami", "New York", "Chicago", "Golden State", "Philadelphia", "Dallas", "Phoenix", "Denver"]
	teams.shuffle()
	
	for i in range(5):
		var team_a = teams.pop_back()
		var team_b = teams.pop_back()
		var odd_a = snapped(randf_range(1.2, 2.5), 0.01)
		var odd_b = snapped(randf_range(1.2, 2.5), 0.01)
		matchups.append({"a": team_a, "b": team_b, "odd_a": odd_a, "odd_b": odd_b})
		_create_matchup_ui(i, team_a, team_b, odd_a, odd_b)

func _create_matchup_ui(idx: int, team_a: String, team_b: String, odd_a: float, odd_b: float) -> void:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var btn_a = Button.new()
	btn_a.text = team_a + " (" + str(odd_a) + "x)"
	btn_a.custom_minimum_size = Vector2(250, 60)
	var lbl_vs = Label.new()
	lbl_vs.text = " VS "
	lbl_vs.add_theme_color_override("font_color", Color("#888888"))
	var btn_b = Button.new()
	btn_b.text = team_b + " (" + str(odd_b) + "x)"
	btn_b.custom_minimum_size = Vector2(250, 60)
	btn_a.pressed.connect(_on_pick_selected.bind(idx, team_a, odd_a, btn_a, btn_b))
	btn_b.pressed.connect(_on_pick_selected.bind(idx, team_b, odd_b, btn_b, btn_a))
	row.add_child(btn_a)
	row.add_child(lbl_vs)
	row.add_child(btn_b)
	matchups_list.add_child(row)

func _on_pick_selected(match_idx: int, team_name: String, odd: float, active_btn: Button, inactive_btn: Button) -> void:
	AudioManager.play_sfx("sfx_ui_click")
	active_btn.modulate = Color("#d4af37") 
	inactive_btn.modulate = Color("#ffffff")
	selected_picks[match_idx] = {"team": team_name, "odd": odd}
	_update_slip()

func _update_slip() -> void:
	selected_teams_label.text = str(selected_picks.size()) + "/5 Selected"
	total_odds = 1.0
	for pick in selected_picks.values():
		total_odds *= pick["odd"]
	total_odds = snapped(total_odds, 0.01)
	odds_label.text = "Total Odds: " + str(total_odds) + "x"
	_on_bet_changed(bet_dropdown.selected)
	btn_lock_in.disabled = selected_picks.size() < 5

func _on_bet_changed(idx: int) -> void:
	AudioManager.play_sfx("sfx_ui_click")
	current_bet = bet_amounts[idx]
	var payout = int(current_bet * total_odds)
	payout_label.text = "To Win: ₱" + str(payout)
	if RunState.money < current_bet:
		payout_label.text += " (INSUFFICIENT FUNDS)"
		payout_label.add_theme_color_override("font_color", Color.RED)
		btn_lock_in.disabled = true
	else:
		payout_label.add_theme_color_override("font_color", Color.WHITE)
		if selected_picks.size() == 5: btn_lock_in.disabled = false

func _on_back_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	if is_simulating: return
	if hub_controller: hub_controller.return_to_menu()

func _on_lock_in_pressed() -> void:
	if RunState.money < current_bet: 
		AudioManager.play_sfx("sfx_error_buzz")
		return
		
	AudioManager.play_sfx("sfx_ui_click")
	AudioManager.play_sfx("sfx_tension_tick")
	RunState.money -= current_bet
	if hub_controller: hub_controller.increment_play_count()
	
	var rtp = hub_controller.get_rigging_rtp() if hub_controller else 1.0
	rigged_to_lose = rtp < 1.0
	draft_phase.hide()
	btn_back.disabled = true
	sim_phase.show()
	_setup_live_bars()
	is_simulating = true

func _setup_live_bars() -> void:
	for i in range(5):
		var pick = selected_picks[i]
		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = pick["team"]
		lbl.custom_minimum_size = Vector2(150, 0)
		var bar = ProgressBar.new()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.min_value = -20
		bar.max_value = 20
		bar.value = 0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 30)
		var sb_bg = StyleBoxFlat.new()
		sb_bg.bg_color = Color("#ff3333") 
		bar.add_theme_stylebox_override("background", sb_bg)
		var sb_fill = StyleBoxFlat.new()
		sb_fill.bg_color = Color("#33ff33") 
		bar.add_theme_stylebox_override("fill", sb_fill)
		hbox.add_child(lbl)
		hbox.add_child(bar)
		live_games_list.add_child(hbox)
		live_bars.append(bar)

func _process(delta: float) -> void:
	if not is_simulating: return
	
	time_remaining -= delta
	timer_label.text = "LIVE: " + str(max(0, snapped(time_remaining, 0.1))) + "s"
	
	if int(time_remaining * 10) % 5 == 0:
		for i in range(5):
			var bar = live_bars[i]
			var is_trap = (rigged_to_lose and i == heartbreaker_index)
			if is_trap:
				if time_remaining > 5.0:
					bar.value = move_toward(bar.value, randf_range(-5, 2), 2)
				elif time_remaining > 1.0 and not has_boosted:
					bar.value = -8 
					boost_container.show()
				elif time_remaining <= 0.1:
					bar.value = -20 
			else:
				bar.value = move_toward(bar.value, randf_range(5, 15), 3)

	if time_remaining <= 0:
		_end_simulation()

func _on_boost_pressed() -> void:
	if RunState.money < 50: return
	AudioManager.play_sfx("sfx_correct_ding")
	RunState.money -= 50
	has_boosted = true
	boost_container.hide()
	var trap_bar = live_bars[heartbreaker_index]
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(trap_bar, "value", 5, 0.5)

func _end_simulation() -> void:
	is_simulating = false
	btn_back.disabled = false
	boost_container.hide()
	var won = true
	for bar in live_bars:
		if bar.value <= 0: won = false
		
	if won and not rigged_to_lose:
		AudioManager.play_sfx("sfx_coin_fountain")
		var payout = int(current_bet * total_odds)
		RunState.money += payout
		result_label.text = "PARLAY HIT! +₱" + str(payout)
		result_label.add_theme_color_override("font_color", Color("#00ff00"))
	else:
		AudioManager.play_sfx("sfx_error_buzz")
		result_label.text = "PARLAY BUSTED."
		result_label.add_theme_color_override("font_color", Color("#ff3333"))
