extends Control

@onready var chapter_title: Label = $MarginContainer/ContentVBox/ChapterTitle
@onready var story_text: RichTextLabel = $MarginContainer/ContentVBox/StoryText
@onready var next_button: Button = $MarginContainer/ContentVBox/ButtonRow/NextButton
@onready var skip_button: Button = $MarginContainer/ContentVBox/ButtonRow/SkipButton

var story_pages: Array[String] = [
	"[p]May 15,000 pesos na tuition deadline si [b]Ador[/b] bago matapos ang araw na ito.[/p]\n\n[p]Kasalukuyang laman ng pitaka: [color=#ff5555][b]₱3,000[/b][/color].[/p]\n\n[p]Ang plano:\n• Pumasa sa scholarship exam mamayang umaga ([color=#55ff55]+₱5,000[/color]).\n• Matapos ang graveyard call center shift mamayang gabi ([color=#55ff55]+₱7,000[/color]).[/p]",
	"[p]Saktong [color=#ffd700]₱15,000[/color] ang mabubuo kapag nagawa ang lahat. Walang labis, walang kulang.[/p]\n\n[p]Eksaktong zero ang maiiwan para sa pagkain at pamasahe bukas.[/p]\n\n[p]Sa bawat kanto, jeep, at poster sa daan, iisang tukso ang sumasalubong:\n[color=#ffd700][b]SugalHub[/b][/color] — instant pera, mabilisang solusyon sa gipit.[/p]",
	"[p]Isang maling pindot, isang 'subok lang', ay kayang sunugin ang perang pinaghirapan mo bago pa man mabayaran ang eskwela.[/p]\n\n[p][color=#55ff55][b]Alamin ang iyong prayoridad. Harapin ang araw na ito.[/b][/color][/p]"
]

var current_page: int = 0
var is_typing: bool = false
var text_tween: Tween

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	if not next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.connect(_on_next_pressed)
	if not skip_button.pressed.is_connected(_on_skip_pressed):
		skip_button.pressed.connect(_on_skip_pressed)
		
	_display_page(0)

func _display_page(index: int) -> void:
	current_page = index
	story_text.text = story_pages[current_page]
	story_text.visible_ratio = 0.0
	is_typing = true
	
	if text_tween and text_tween.is_valid():
		text_tween.kill()
		
	text_tween = create_tween()
	text_tween.tween_property(story_text, "visible_ratio", 1.0, 1.2)
	text_tween.finished.connect(func(): is_typing = false)
	
	if current_page >= story_pages.size() - 1:
		next_button.text = "PROCEED >"
	else:
		next_button.text = "CONTINUE >"

func _on_next_pressed() -> void:
	if is_typing:
		if text_tween and text_tween.is_valid():
			text_tween.kill()
		story_text.visible_ratio = 1.0
		is_typing = false
		return
		
	if current_page < story_pages.size() - 1:
		_display_page(current_page + 1)
	else:
		_proceed()

func _on_skip_pressed() -> void:
	_proceed()

func _proceed() -> void:
	if ResourceLoader.exists("res://scenes/TutorialScene.tscn"):
		get_tree().change_scene_to_file("res://scenes/TutorialScene.tscn")
	else:
		SceneManager.load_scene(SceneManager.GameScene.ROOM)
