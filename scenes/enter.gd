extends Area2D

# This allows you to set the destination scene directly in the Godot Inspector
@export var next_scene_path: String = "res://scenes/school_day1.tscn"

@onready var prompt_label = $Label
var can_interact: bool = false

func _ready() -> void:
	prompt_label.hide()
	
	# Connect the Area2D signals through code
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# Make sure it's the player triggering the area
	if body.name == "Player":
		can_interact = true
		prompt_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = false
		prompt_label.hide()

func _process(_delta: float) -> void:
	# If player is in the zone and presses 'E'
	if can_interact and Input.is_action_just_pressed("interact"):
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)
		else:
			print("Error: next_scene_path is empty!")
