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
		ending_body = "[center]Naka-kandado na ang gate. Wala ang pangalan ni Ador sa listahan ng mga ga-graduate. Kinapos siya. Ang 3,000 niya, pinagsama sa kakarampot na kinita, ay hindi umabot sa hinihinging 15,000. Hindi dahil tamad siya, kundi dahil kahit anong kayod niya, sadyang hindi sapat ang ibinibigay ng sistema. Tumalikod si Ador. Wala nang galit, tanging mabigat na pagod na lang. Isang tahimik na pagtanggap na mayroon talagang mga naiiwan sa dilim.[/center]"
		
	elif RunState.scholarship_passed and RunState.job_completed and not RunState.gambling_attempted:
		ending_title = "[center]ENDING A: Matuwid na daan. [/center]"
		ending_body = "[center]Nasisilaw si Ador sa ilaw ng entablado. Naalala niya kung paanong ang 3,000 niya, ang 5,000 sa scholarship, at ang 7,000 sa dalawang linggong shift ay saktong umabot sa 15,000. Kinailangan niyang tiisin ang gutom at labanan ang tukso ng mga influencers na nangangako ng mabilis na pera para sa 'breathing room'. Nakatawid siya nang malinis, hindi nagpadala sa peer pressure, at nilabanan ang boredom ng paulit-ulit na hirap. Hawak niya ang diploma. Siya ang nanalo.[/center]"
		
	elif RunState.gambling_attempted:
		if RunState.gambling_net_result >= 0:
			ending_title = "[center]ENDING B: Paldo, Pero...[/center]"
			ending_body = "[center]Umaapaw ang palakpakan. Mukha siyang success story. Nung gabing kailangan niya ng breathing room at nalamon siya ng boredom, nakinig siya sa paborito niyang vlogger at isinugal ang pera niya. Nanalo siya. Nabayaran ang 15,000 na tuition, at nakakain siya kinabukasan. Pero pagbalik niya sa upuan mula sa entablado, pasimpleng umiilaw ang screen ng phone niya sa ilalim ng toga. Bukas ang SugalHub. Hindi siya sinira ng app noon... pero alam niyang habambuhay na siyang nakakulong sa bitag ng pag-i-spin.[/center]"
		else:
			ending_title = "[center]ENDING C: Saan nga ba ako patungo? [/center]"
			ending_body = "[center]Naglakad si Ador sa entablado, pero parang tingga ang mga binti niya. Dahil sa inip, peer pressure, at paniniwala sa mga pekeng success stories ng mga influencers, isinugal niya ang perang nakalaan sana sa tuition. Natalo siya. Nasira ang saktong 15,000. Para makarating sa graduation, kinailangan niyang mangutang sa mga loan sharks. Pagtingin niya sa baba, nakita niya ang mga kaklase niyang nag-uudyok sa kanya noon. Hawak ni Ador ang diploma, pero ang tanging nasa isip niya ay kung paano niya babayaran ang libo-libong utang na sisira sa kinabukasan niya.[/center]"

	title_label.text = ending_title
	story_text.text = ending_body
	text_length = story_text.get_parsed_text().length()
	story_text.visible_characters = 0

func _setup_credits() -> void:
	credits_text.text = """[center]
[b]TEAM[/b]
Kirsten Gail Querubin
John Benedict Baladia
Arwen Fajardo

[b]ADVOCACY[/b]
Thousands of Filipino students work double shifts just to stay enrolled. 
Predatory gambling apps target the desperate and the young. 
Education is not a privilege — it is a right worth protecting.

#AlagangEskwela #LabanSaOnlineGambling
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
