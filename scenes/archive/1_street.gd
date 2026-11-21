extends Node3D

@onready var player: CharacterBody3D = $"../Character"

# Create a list for your cloud sprites
@onready var cloud_layers = [$Cloud1, $Cloud2, $Cloud3]

const SCROLL_SPEED_CLOUDS = 0.15
const SPRITE_WIDTH = 20.0 # Change this to match the actual width of your cloud sprite asset!

func _process(_delta: float) -> void:
	if not player:
		return
		
	var player_x = player.global_position.x
	var player_y = player.global_position.y
	
	# 1. Keep the main container perfectly locked onto the player
	global_position.x = player_x
	global_position.y = player_y
	
	# 2. Calculate a looping anchor position for the parallax effect
	var parallax_offset = fmod(-player_x * SCROLL_SPEED_CLOUDS, SPRITE_WIDTH)
	
	# 3. Position the three sprites relative to that anchor point
	# This creates an endless seamless conveyor belt!
	cloud_layers[0].position.x = parallax_offset - SPRITE_WIDTH
	cloud_layers[1].position.x = parallax_offset
	cloud_layers[2].position.x = parallax_offset + SPRITE_WIDTH
