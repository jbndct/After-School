extends ParallaxBackground

# Finds the player node sitting right above it in the tree
@onready var player: CharacterBody3D = $"../CharacterBody3D"

func _process(_delta: float) -> void:
	if not player:
		return
		
	# Takes your player's physical 3D X position and slides the 2D background
	scroll_base_offset.x = -player.global_transform.origin.x
