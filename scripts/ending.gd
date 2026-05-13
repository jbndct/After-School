extends Node2D

# ─── UI NODES ───
# Hook these up to whatever Labels/RichTextLabels you have in ending.tscn
@onready var title_label = $EndingTitle 
@onready var description_label = $EndingDescription
@onready var menu_button = $MenuButton

func _ready() -> void:
	# Hide player/UI elements if they accidentally carried over
	EventBus.sugalhub_closed.emit()
	
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
		
	evaluate_run()

func evaluate_run() -> void:
	var ending_title = ""
	var ending_text = ""
	
	# ENDING D: POVERTY (Takes absolute priority if scholarship failed)
	if not RunState.scholarship_passed:
		ending_title = "ENDING D: Hindi Siya Kasali"
		ending_text = "Ador watches from outside the venue gate. He didn't make it. Not because he wasn't smart, not because he didn't work — but because the system gave him too little runway. The cost of survival was just too high."
		
	# ENDING A: GOOD ENDING (Passed, Worked, Clean)
	elif RunState.scholarship_passed and RunState.job_completed and not RunState.gambling_attempted:
		ending_title = "ENDING A: Sipag at Tiyaga"
		ending_text = "Ador walks across the stage. His mom is in the crowd, crying. He chose the hard road. He made it clean. The diploma is his, and he earned every single inch of it."
		
	# ENDING B & C: THE GAMBLING ENDINGS
	elif RunState.gambling_attempted:
		if RunState.gambling_net_result >= 0:
			# HOOKED ENDING (Net Positive)
			ending_title = "ENDING B: Nanalo, Pero..."
			ending_text = "Ador graduates. He has money. He looks successful. But under the table, SugalHub is open. He's betting again. The app didn't ruin him this time... but it will."
		else:
			# WRECKED ENDING (Net Negative)
			ending_title = "ENDING C: Kinuha Na Niya"
			ending_text = "Ador graduates, but barely. The gambling losses drained him. He had to beg and scramble to survive. He sees Mark in the crowd — Mark who started it all. The cost of temptation made visible."
			
	# FALLBACK (In case they skipped the job but passed the exam)
	else:
		ending_title = "ENDING D: Hindi Siya Kasali"
		ending_text = "Even with the scholarship, missing the night shift wage left Ador short. He watches the graduation from the outside."

	# Apply to UI
	if title_label: title_label.text = ending_title
	if description_label: description_label.text = ending_text

func _on_menu_pressed() -> void:
	# Ensure "menu" is added to your SceneManager.SCENES dictionary!
	SceneManager.load_scene("menu")
