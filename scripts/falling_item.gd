extends Area2D

@export var is_hazard: bool = false
@export var fall_speed: float = 300.0

# Used to give each item a slight, unique spin
var rotation_speed: float 

func _ready() -> void:
	# Polish: Randomize rotation direction and speed so they don't look completely uniform
	rotation_speed = randf_range(-3.0, 3.0)

func _process(delta: float) -> void:
	# Move downward
	position.y += fall_speed * delta
	# Apply the spin
	rotation += rotation_speed * delta

# Signal callback for cleanup
func _on_screen_exited() -> void:
	queue_free()
	
func _on_body_entered(body: Node2D) -> void:
	# Check if the thing we hit is the player
	if body.name == "InterviewPlayer":
		# Tell the main scene that an item was caught
		var main_scene = get_tree().current_scene
		if main_scene.has_method("on_item_caught"):
			main_scene.on_item_caught(is_hazard)
		
		# Delete the item so it doesn't pass through the player
		queue_free()
