extends Control

@onready var background_image: TextureRect = $BackgroundImage
@onready var story_text: RichTextLabel = $DialogMargin/PanelContainer/MarginContainer/StoryText

# We pair a text string with a background image for each click!
var story_pages: Array[Dictionary] = [
	{
		"text": "[center]May 15,000 pesos na tuition deadline si Diego bago matapos ang araw na ito.\n\nKasalukuyang laman ng pitaka: [color=#ff5555]₱3,000[/color].[/center]",
		"image": preload("res://assets/sprites/Envi/room.png") # Uses your room sprite
	},
	{
		"text": "[center]Ang plano:\n1. Pumasa sa scholarship exam mamaya.\n2. Tapusin ang graveyard shift sa call center ₱7,000.\n\nSaktong pera lang. Walang labis, walang kulang.[/center]",
		"image": preload("res://assets/sprites/Envi/school1.png") # Uses your school sprite
	},
	{
		"text": "[center]Ngunit sa bawat kanto, iisang tukso ang sumasalubong:\nSugalHub — instant pera, mabilisang solusyon sa gipit.\n\nMaging alerto. Harapin ang araw na ito.[/center]",
		"image": preload("res://assets/sprites/street better.png") # Uses your street sprite
	}
]

var current_page: int = 0
var text_tween: Tween

func _ready() -> void:
	_display_page(0)

func _input(event: InputEvent) -> void:
	# Advance story on Left Click, Space, or Enter
	if event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if text_tween and text_tween.is_running():
			# If text is typing, finish it instantly
			text_tween.kill()
			story_text.visible_ratio = 1.0
		else:
			# Move to next page
			current_page += 1
			if current_page < story_pages.size():
				_display_page(current_page)
			else:
				# Once done, go to the tutorial
				SceneManager.load_scene("tutorial")

func _display_page(index: int) -> void:
	var page_data = story_pages[index]
	story_text.text = page_data["text"]
	background_image.texture = page_data["image"]
	
	story_text.visible_ratio = 0.0
	text_tween = create_tween()
	text_tween.tween_property(story_text, "visible_ratio", 1.0, 1.5) # Types out over 1.5 seconds
