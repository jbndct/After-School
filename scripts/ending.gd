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
	
	if not RunState.scholarship_passed or not RunState.job_completed:
		ending_title = "[center]ENDING D: Hindi Siya Kasali[/center]"
		ending_body = "[center]The venue gates are locked. From the outside, Ador listens to the muffled sound of applause and names being called. His name isn't one of them. He didn't fail because he lacked intelligence, or because he didn't work himself to the bone. He failed because the math of survival was rigged against him from the start. The night shifts, the exhaustion, the empty stomach—it wasn't enough to buy his way across that stage. As the final notes of the graduation march play, Ador turns away. There is no anger left, only a quiet, heavy exhaustion. A silent acknowledgement that in this system, some students fight just as hard as the rest, only to be left behind in the dark.[/center]"
		
	elif RunState.scholarship_passed and RunState.job_completed and not RunState.gambling_attempted:
		ending_title = "[center]ENDING A: Sipag at Tiyaga[/center]"
		ending_body = "[center]The lights on the stage are blinding. As Ador's name is called, the weight of the past few years suddenly hits him all at once. Every skipped meal, every grueling night shift at the call center, every time he walked past those flashing SugalHub posters and forced himself to look away. He scans the crowd and sees his mother, tears streaming down her face, clutching a worn-out handkerchief. He chose the hardest possible road. He made it out clean. As his fingers grasp the diploma, it feels impossibly heavy. It's not just a piece of paper; it's proof that he survived the meat grinder.[/center]"
		
	elif RunState.gambling_attempted:
		if RunState.gambling_net_result >= 0:
			ending_title = "[center]ENDING B: Nanalo, Pero...[/center]"
			ending_body = "[center]The applause washes over him, but Ador barely hears it. He holds his diploma in one hand, smiling for the cameras. He looks like a success story. A working student who beat the odds. But as he returns to his seat and the ceremony drags on, his hand slips into his pocket. Underneath the folding chair, out of sight from his proud mother, the screen illuminates his face. SugalHub is open. He places a bet. The app didn't ruin him today. It didn't stop him from graduating. But as the wheel spins on the screen, the truth sets in: he won the battle, but he has already lost the war. The trap has snapped shut.[/center]"
		else:
			ending_title = "[center]ENDING C: Kinuha Na Niya[/center]"
			ending_body = "[center]Ador walks across the stage, but his legs feel like lead. The applause sounds like static. He made it, but the victory is entirely hollow. To get here, he had to beg, borrow, and humiliate himself. The gambling losses had drained his tuition money, plunging him into a cycle of desperate loans and suffocating debt. As he looks out into the crowd, he doesn't see his family first. He sees Mark. Mark, who showed him the app. Mark, who promised an easy way out. The look they share says everything. Ador holds his diploma, but all he can think about is how much he owes, and how many years it will take to dig himself out of the grave he dug for himself.[/center]"

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
