extends Control

@onready var story_text: RichTextLabel = $MarginContainer/ContentVBox/StoryText
@onready var next_button: Button = $MarginContainer/ContentVBox/ButtonRow/NextButton
@onready var skip_button: Button = $MarginContainer/ContentVBox/ButtonRow/SkipButton
@onready var chapter_title: Label = $MarginContainer/ContentVBox/ChapterTitle

var story_pages: Array[String] = [
	"[p]May 15,000 pesos na tuition deadline si [b]Ador[/b] bago matapos ang linggong ito.[/p]\n\n[p]Kasalukuyang laman ng pitaka: [color=#ff5555][b]₱3,000[/b][/color].[/p]\n\n[p]Ang tanging pag-asa: makapasa sa scholarship exam mamayang umaga ([color=#55ff55]₱5,000[/color]), at matanggap ang sasahuring [color=#55ff55]₱7,000[/color] mula sa graveyard call center shift mamayang gabi.[/p]",
	"[p]Saktong ₱15,000 ang bubuuin. Walang labis, walang kulang.[/p]\n\n[p]Zero ang matitira para sa pamasahe, pagkain, o emergencies bukas.[/p]\n\n[p]Habang naglalakad sa kalsada, bawat billboard at bawat screen ng katabi sa jeep ay iisang bagay lang ang ibinabandera: [color=#d4af37][b]SugalHub[/b][/color] — mabilisang diskarte, instant pera.[/p]",
	"[p]Ang desisyon mo ngayong araw ang magdidikta kung makakapagtapos ka ng pag-aaral... o kung lalamunin ka ng siklo ng sugal at utang.[/p]\n\n[p][color=#ffd700][i]Maging alerto sa iyong mga desisyon at huwag hayaang mawala ang iyong kinabukasan.[/i][/color][/p]"
]

var current_page: int = 0

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_proceed_to_tutorial)
	_show_page(0)

func _show_page(index: int) -> void:
	current_page = index
	story_text.text = story_pages[current_page]
	story_text.visible_ratio = 0.0
	
	var tween = create_tween()
	tween.tween_property(story_text, "visible_ratio", 1.0, 1.2)
	
	if current_page == story_pages.size() - 1:
		next_button.text = "PROCEED TO TUTORIAL >"
	else:
		next_button.text = "CONTINUE >"

func _on_next_pressed() -> void:
	if story_text.visible_ratio < 1.0:
		story_text.visible_ratio = 1.0
		return
		
	if current_page < story_pages.size() - 1:
		_show_page(current_page + 1)
	else:
		_proceed_to_tutorial()

func _proceed_to_tutorial() -> void:
	SceneManager.load_scene("tutorial")
