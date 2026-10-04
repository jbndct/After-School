extends Control

# Smart lookups to prevent crashes
@onready var background_image: TextureRect = find_child("BackgroundImage", true, false)
@onready var story_text: RichTextLabel = find_child("StoryText", true, false)



# The 5-Slide Visual Novel Story for Diego
var story_pages: Array[Dictionary] = [
	{
		# Slide 1: Character Intro
		"text": "[center]Kilala mo ba siya? Siya si Diego. Si Diego at isang working student na pinipilit pagsabayin ang kolehiyo at ang paghahanap-buhay para sa kanyang pamilya.[/center]",
		"image": preload("res://assets/sprites/story1.png") 
	},
	{
		# Slide 2: His Story
		"text": "[center]Gabi-gabi siyang nakaharap sa computer, hindi dahil siya'y naglalaro, pero dahil sumasagot ng tawag bilang isang call center agent sa graveyard shift. Sa umaga, diretso siya sa klase. Walang pahinga.[/center]",
		"image": preload("res://assets/sprites/story2.png") 
	},
	{
		# Slide 3: The Problem
		"text": "[center]Ngunit may malaking problema. May ₱15,000 na tuition deadline si Diego bago matapos ang araw na ito. Kung hindi siya makakabayad, hindi siya makakapag-exam.\n\nKasalukuyang laman ng pitaka: [color=#ff5555]₱3,000[/color].[/center]",
		"image": preload("res://assets/sprites/story1.png") 
	},
	{
		# Slide 4: The Plan
		"text": "[center]Ang plano:\n1. Pumasa sa scholarship exam mamaya ([color=#55ff55]+₱5,000[/color]).\n2. Tapusin ang shift sa call center nang walang palya ([color=#55ff55]+₱7,000[/color]).\n\nSaktong ₱15,000. Eksaktong zero ang maiiwan para sa pagkain bukas.[/center]",
		"image": preload("res://assets/sprites/story2.png") 
	},
	{
		# Slide 5: The Temptation
		"text": "[center]Dahil sa desperasyon, isang tukso ang patuloy na sumasalubong kay Diego:\n[color=#ffd700]SugalHub[/color] — instant pera, mabilisang solusyon sa gipit.\n\nKung ikaw si Diego, ano ang pipiliin mo: ang mabagal at siguradong hirap ng pagiging marangal, o ang mabilisang sugal na pwedeng maging katapusan ng lahat?[/center]",
		"image": preload("res://assets/sprites/street better.png") 
	}
]

var current_page: int = 0
var text_tween: Tween

func _ready() -> void:
	_display_page(0)
	AudioManager.play_bgm("bgm_hub")

func _input(event: InputEvent) -> void:
	# Advance story on Left Click, E, Space, or Enter
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if text_tween and text_tween.is_running():
			# If text is currently typing out, clicking instantly finishes the typing
			text_tween.kill()
			if story_text: story_text.visible_ratio = 1.0
		else:
			# If text is fully typed, move to the next page
			current_page += 1
			if current_page < story_pages.size():
				_display_page(current_page)
			else:
				# Once the 5 slides are done, load the tutorial!
				if ResourceLoader.exists("res://scenes/tutorial.tscn"):
					get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
				else:
					get_tree().change_scene_to_file("res://scenes/room.tscn")

func _display_page(index: int) -> void:
	var page_data = story_pages[index]
	
	if background_image:
		background_image.texture = page_data["image"]
		
	if story_text:
		story_text.text = page_data["text"]
		story_text.visible_ratio = 0.0
		
		text_tween = create_tween()
		
		# TASK 3 FIX: Slowed down typing speed significantly.
		# Changed from 1.5 seconds to 3.8 seconds.
		text_tween.tween_property(story_text, "visible_ratio", 1.0, 3.8)
