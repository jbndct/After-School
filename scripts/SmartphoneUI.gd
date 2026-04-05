extends CanvasLayer

@onready var phone_bg = $PhoneBackground
@onready var home_screen = $PhoneBackground/HomeScreen
@onready var app_epera = $PhoneBackground/AppEpera
@onready var app_todo = $PhoneBackground/AppToDo
@onready var app_messages = $PhoneBackground/AppMessages
@onready var app_sugal = $PhoneBackground/AppSugal

@onready var balance_label = $PhoneBackground/AppEpera/BalanceLabel
@onready var objective_label = $PhoneBackground/AppToDo/ObjectiveLabel
@onready var btn_sugal_app = $PhoneBackground/HomeScreen/AppGrid/BtnSugal
@onready var launch_sugal_btn = $PhoneBackground/AppSugal/LaunchSugalBtn

func _ready() -> void:
	phone_bg.show()
	show_home_screen()
	
	# Connect to GameState signals to keep UI updated
	launch_sugal_btn.pressed.connect(_on_launch_sugal_pressed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.sugal_unlocked.connect(_on_sugal_unlocked)
	
	
	# Initial UI Setup based on existing state
	_on_money_changed(GameState.hand)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_phone"):
		if phone_bg.visible:
			phone_bg.hide()
			# Optionally resume game execution here if you pause the tree
		else:
			update_todo_app()
			phone_bg.show()

# --- Navigation ---
func show_home_screen() -> void:
	home_screen.show()
	app_epera.hide()
	app_todo.hide()
	app_messages.hide()
	app_sugal.hide()

func _on_BtnHome_pressed() -> void:
	show_home_screen()

# --- App Openers ---
func _on_BtnEPera_pressed() -> void:
	show_home_screen()
	home_screen.hide()
	app_epera.show()

func _on_BtnToDo_pressed() -> void:
	show_home_screen()
	home_screen.hide()
	update_todo_app()
	app_todo.show()

func _on_BtnSugal_pressed() -> void:
	GameState.last_scene_path = get_tree().current_scene.scene_file_path
	
	# Add this debug print to check your output console
	print("SAVED RETURN PATH: ", GameState.last_scene_path) 
	
	get_tree().change_scene_to_file("res://scenes/SugalHub.tscn")

func _on_BtnMessages_pressed() -> void:
	show_home_screen()
	home_screen.hide()
	app_messages.show()
	# Here you would populate the VBoxContainer with GameState.notifications

# --- Data Updating ---
func _on_money_changed(new_amount: int) -> void:
	balance_label.text = "Balance: ₱" + str(new_amount)

func _on_sugal_unlocked() -> void:
	btn_sugal_app.disabled = false

func update_todo_app() -> void:
	objective_label.text = "Current Objective:\n" + GameState.get_current_objective()
	

func _on_launch_sugal_pressed() -> void:
	# Load the minigame and add it to the root so it covers the whole screen
	var sugal_scene = load("res://scenes/SugalHub.tscn").instantiate()
	get_tree().root.add_child(sugal_scene)
	
	# Hide the phone while playing
	phone_bg.hide()
