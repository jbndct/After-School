extends Control

# Smart lookups to prevent crashes
@onready var background_image: TextureRect = find_child("BackgroundImage", true, false)
@onready var story_text: RichTextLabel = find_child("StoryText", true, false)
@onready var dialog_margin: MarginContainer = find_child("DialogMargin", true, false)

const TARGET_ASPECT: float = 4.0 / 3.0
const INNER_TEXT_PADDING: float = 24.0
const BOTTOM_MARGIN_PX: float = 10.0

var left_black_bar: Control
var right_black_bar: Control

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
var is_advancing: bool = false

func _ready() -> void:
	_setup_4_to_3_bars()
	_update_4_to_3_bars()
	if not get_viewport().size_changed.is_connected(_update_4_to_3_bars):
		get_viewport().size_changed.connect(_update_4_to_3_bars)

	if story_text:
		story_text.bbcode_enabled = true
		story_text.fit_content = true
		story_text.scroll_active = false
		story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		story_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		story_text.add_theme_constant_override("shadow_offset_x", 2)
		story_text.add_theme_constant_override("shadow_offset_y", 2)

	_display_page(0)
	AudioManager.play_bgm("bgm_hub")

func _setup_4_to_3_bars() -> void:
	left_black_bar = find_child("LeftBar", true, false) as Control
	if left_black_bar == null:
		left_black_bar = find_child("LeftBlackBar", true, false) as Control
	if left_black_bar == null:
		var bar := ColorRect.new()
		bar.name = "LeftBar"
		bar.color = Color.BLACK
		add_child(bar)
		left_black_bar = bar
	elif left_black_bar is ColorRect:
		(left_black_bar as ColorRect).color = Color.BLACK
	left_black_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	right_black_bar = find_child("RightBar", true, false) as Control
	if right_black_bar == null:
		right_black_bar = find_child("RightBlackBar", true, false) as Control
	if right_black_bar == null:
		var bar := ColorRect.new()
		bar.name = "RightBar"
		bar.color = Color.BLACK
		add_child(bar)
		right_black_bar = bar
	elif right_black_bar is ColorRect:
		(right_black_bar as ColorRect).color = Color.BLACK
	right_black_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Place bars above artwork/filters, and just below DialogMargin so StoryText sits in front
	if dialog_margin and dialog_margin.get_parent() == self:
		var dialog_idx := dialog_margin.get_index()
		move_child(left_black_bar, maxi(dialog_idx, 0))
		move_child(right_black_bar, maxi(dialog_idx, 0))
	elif story_text and story_text.get_parent() == self:
		var text_idx := story_text.get_index()
		move_child(left_black_bar, maxi(text_idx - 1, 0))
		move_child(right_black_bar, maxi(text_idx - 1, 0))

func _update_4_to_3_bars() -> void:
	var vp_size := get_viewport_rect().size
	var current_aspect := vp_size.x / maxf(vp_size.y, 1.0)
	var side_bar_width := 0.0

	if current_aspect > TARGET_ASPECT:
		var active_4_to_3_width := vp_size.y * TARGET_ASPECT
		side_bar_width = (vp_size.x - active_4_to_3_width) * 0.5

	if left_black_bar:
		left_black_bar.visible = side_bar_width > 0.0
		left_black_bar.position = Vector2.ZERO
		left_black_bar.size = Vector2(side_bar_width, vp_size.y)

	if right_black_bar:
		right_black_bar.visible = side_bar_width > 0.0
		right_black_bar.position = Vector2(vp_size.x - side_bar_width, 0.0)
		right_black_bar.size = Vector2(side_bar_width, vp_size.y)

	if dialog_margin:
		var total_side_margin := int(side_bar_width + INNER_TEXT_PADDING)
		dialog_margin.add_theme_constant_override("margin_left", total_side_margin)
		dialog_margin.add_theme_constant_override("margin_right", total_side_margin)
		dialog_margin.add_theme_constant_override("margin_bottom", int(BOTTOM_MARGIN_PX))
		dialog_margin.add_theme_constant_override("margin_top", int(maxf(0.0, vp_size.y * 0.65)))
	elif story_text:
		var active_width := vp_size.y * TARGET_ASPECT if side_bar_width > 0.0 else vp_size.x
		story_text.position.x = side_bar_width + INNER_TEXT_PADDING
		story_text.size.x = maxf(100.0, active_width - (INNER_TEXT_PADDING * 2.0))
		story_text.position.y = vp_size.y - BOTTOM_MARGIN_PX - story_text.size.y

func _input(event: InputEvent) -> void:
	if is_advancing:
		return

	# Advance story on Left Click, E, Space, or Enter
	var is_advance_input: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not is_advance_input:
		return

	if text_tween and text_tween.is_running():
		# If text is currently typing out, clicking/pressing instantly finishes the typing
		text_tween.kill()
		if story_text:
			story_text.visible_ratio = 1.0
	else:
		current_page += 1
		if current_page < story_pages.size():
			_display_page(current_page)
		else:
			is_advancing = true
			var tutorial_path: String = SceneManager.SCENES.get("tutorial", "")
			if not tutorial_path.is_empty() and ResourceLoader.exists(tutorial_path):
				SceneManager.load_scene("tutorial")
			else:
				SceneManager.load_scene("room")

func _display_page(index: int) -> void:
	var page_data = story_pages[index]

	if background_image:
		background_image.texture = page_data["image"]

	if story_text:
		story_text.text = page_data["text"]
		story_text.visible_ratio = 0.0

		if text_tween and text_tween.is_running():
			text_tween.kill()

		text_tween = create_tween()
		text_tween.tween_property(story_text, "visible_ratio", 1.0, 3.8)
