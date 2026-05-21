# res://scripts/ending.gd
extends Control

@onready var story_container = $StoryContainer
@onready var title_label = $StoryContainer/TitleLabel
@onready var story_text = $StoryContainer/StoryText
@onready var credits_container = $CreditsContainer
@onready var credits_text = $CreditsContainer/CreditsText
@onready var skip_button = $SkipButton

enum State { TYPING, WAITING, CREDITS }
var current_state: State = State.TYPING

var text_length: int = 0
var type_timer: float = 0.0
var type_speed: float = 0.03 
var scroll_speed: float = 40.0 

func _ready() -> void:
	EventBus.sugalhub_closed.emit()
	
	story_container.show()
	credits_container.hide()
	
	skip_button.pressed.connect(_on_skip_pressed)
	skip_button.text = "Fast Forward"
	
	_evaluate_run()
	_setup_credits()

func _evaluate_run() -> void:
	var ending_title = ""
	var ending_body = ""
	
	if (not RunState.scholarship_passed or not RunState.job_completed) and not RunState.gambling_attempted:
		ending_title = "[center]ENDING D: Mahirap maging mahirap.[/center]"
		ending_body = "[center]Naka-kandado na ang gate. Wala ang pangalan ni Ador sa listahan — hindi dahil hindi siya nagsikap, kundi dahil ang sistema ay hindi dinisenyo para sa mga katulad niya. Ginawa niya ang lahat ng tamang bagay. Nag-aral. Nagtatrabaho. Hindi nagpadala. At hindi pa rin sapat. Tumalikod siya nang tahimik — walang luha, walang sigaw. Tanging yung uri ng pagod na hindi mapapawi ng tulog. Mayroon talagang mga taong ginagawa ang lahat ng tama, at naiiwanan pa rin. Ikaw — kung nasa katayuan mo si Ador, anong pagbabago sa labas niya ang sana ay nagawa mong baguhin?[/center]"
		
	elif RunState.scholarship_passed and RunState.job_completed and not RunState.gambling_attempted:
		ending_title = "[center]ENDING A: Matuwid na daan. [/center]"
		ending_body = "[center]Natapos na. Hindi may putok ng paputok o malakas na palakpakan. Tahimik lang. Pero hawak ni Ador ang katibayan ng lahat ng araw na tiniis niya. Ang 3,000, ang 5,000, ang 7,000, bawat piso na pinaghandaan, hindi pinaglaruan. Maraming beses na itinanong ng utak niya kung may mas madaling daan. Ngayon, alam na niya ang sagot. Hindi ang pagiging perpekto ang nagpapanalo sa kanya, kundi ang hindi sumuko nang hindi pa tapos ang laban. Saan ka pupunta mula dito? [/center]"
		
	elif RunState.gambling_attempted:
		if RunState.money >= 15000:
			ending_title = "[center]ENDING B: Paldo, Pero...[/center]"
			ending_body = "[center]Umaapaw ang palakpakan. Nabayaran ang tuition. Nakakain siya kinabukasan. Sa mata ng lahat, natapos niya ang laban. Pero sa mga susunod na araw, pagkatapos ng lahat, binuksan niya muli ang app. Hindi dahil kailangan niya ng pera. Dahil gusto niyang maulit ang pakiramdam. Isang laro pa lang. Pero ang 'isa pa' ay naging sampung beses. Sampung beses ay naging gabi. At ang gabi ay naging ugali na hindi niya napansin na lumagkit sa kanya. Nagtapos nga si Ador ng pag-aaral. Pero hindi siya ang Ador na nagsimula. At hindi niya alam kung kailan eksaktong nawala yung bersyon niya na may kontrol pa. Ikaw ang pumili para sa kanya noon. Alam mo bang ganito ang magiging katapusan ng isang 'oo'? Ano ang gagawin mo kung mabibigyan ka ng pagkakataong muli?[/center]"
		else:
			ending_title = "[center]ENDING C: Saan nga ba ako patungo? [/center]"
			ending_body = "[center]Natalo. Hindi lang ang pera — natalo rin ang bersyon ni Ador na naniniwala pa sa sarili niya. Dahil sa isang sandali ng inip at pag-asa sa maling bagay, nawasak ang pinaghandaan niyang buwan. Hindi siya masamang tao. Naliit lang siya sa tamang sandali, ng tamang ad, ng tamang pangako. Ngayon, nakatayo siya sa harap ng bukas na hindi niya inaasahan. Hindi malinaw kung saan patungo. Ikaw — kung ikaw ang pumili para sa kanya, anong nararamdaman mo ngayon?[/center]"

	title_label.text = ending_title
	story_text.text = ending_body
	text_length = story_text.get_parsed_text().length()
	story_text.visible_characters = 0

func _setup_credits() -> void:
	credits_text.text = """[center]

[b]AFTER SCHOOL[/b]
A CSMC221: Software Engineering 1 Final Project

[b]TEAM[/b]
John Benedict Baladia
Kirsten Gail Querubin
Arwen Fajardo

[b]ADVOCACY[/b]
Thousands of Filipino students work double shifts just to stay enrolled. 
Predatory gambling apps target the desperate and the young. 
Education is not a privilege. It is a right worth protecting.

[/center]"""

func _process(delta: float) -> void:
	match current_state:
		State.TYPING:
			type_timer += delta
			if type_timer >= type_speed:
				type_timer = 0.0
				story_text.visible_characters += 1
				
				if story_text.visible_characters >= text_length:
					_transition_to_waiting()
					
		State.CREDITS:
			credits_container.position.y -= scroll_speed * delta
			if credits_container.position.y < -credits_text.size.y - 100:
				SceneManager.load_scene("menu")

func _transition_to_waiting() -> void:
	story_text.visible_characters = text_length
	current_state = State.WAITING
	skip_button.text = "Continue"

func _on_skip_pressed() -> void:
	match current_state:
		State.TYPING:
			# Instantly finish text. _process will catch it on the next frame 
			# or we can force the transition here.
			_transition_to_waiting()
			
		State.WAITING:
			story_container.hide()
			credits_container.show()
			current_state = State.CREDITS
			skip_button.text = "Skip Credits"
			
		State.CREDITS:
			SceneManager.load_scene("menu")
