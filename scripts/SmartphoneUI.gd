# res://scripts/SmartphoneUI.gd
extends CanvasLayer

@onready var phone_bg = $PhoneBackground
@onready var home_screen = $PhoneBackground/HomeScreen
@onready var app_epera = $PhoneBackground/AppEpera
@onready var app_todo = $PhoneBackground/AppToDo
@onready var app_messages = $PhoneBackground/AppMessages

@onready var balance_label = $PhoneBackground/AppEpera/BalanceLabel
@onready var objective_label = $PhoneBackground/AppToDo/ObjectiveLabel
@onready var btn_sugal_app = $PhoneBackground/HomeScreen/AppGrid/BtnSugal

func _ready() -> void:
	phone_bg.show()
	show_home_screen()
	
	GameState.money_changed.connect(_on_money_changed)
	GameState.sugal_unlocked.connect(_on_sugal_unlocked)
	
	_on_money_changed(GameState.hand)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_phone"):
		if phone_bg.visible:
			AudioManager.play_sfx("sfx_ui_click")
			phone_bg.hide()
		else:
			AudioManager.play_sfx("sfx_phone_buzz")
			update_todo_app()
			phone_bg.show()

func show_home_screen() -> void:
	home_screen.show()
	app_epera.hide()
	app_todo.hide()
	app_messages.hide()

func _on_BtnHome_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	show_home_screen()

func _on_BtnEPera_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	show_home_screen()
	home_screen.hide()
	app_epera.show()

func _on_BtnToDo_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	show_home_screen()
	home_screen.hide()
	update_todo_app()
	app_todo.show()

func _on_BtnSugal_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	GameState.last_scene_path = get_tree().current_scene.scene_file_path
	print("SAVED RETURN PATH: ", GameState.last_scene_path) 
	get_tree().change_scene_to_file("res://scenes/SugalHub.tscn")

func _on_BtnMessages_pressed() -> void:
	AudioManager.play_sfx("sfx_ui_click")
	show_home_screen()
	home_screen.hide()
	app_messages.show()

func _on_money_changed(new_amount: int) -> void:
	balance_label.text = "Balance: ₱" + str(new_amount)

func _on_sugal_unlocked() -> void:
	btn_sugal_app.disabled = false

func update_todo_app() -> void:
	objective_label.text = "Current Objective:\n" + GameState.get_current_objective()
