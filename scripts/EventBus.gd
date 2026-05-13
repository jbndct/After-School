extends Node

# --- ECONOMY SIGNALS ---
signal money_updated(new_amount: int)

# --- UI & PLAYER STATE SIGNALS ---
signal phone_toggled(is_open: bool)
signal sugalhub_opened() # Will be used by Player.gd to lock movement
signal sugalhub_closed() # Will be used by Player.gd to unlock movement

# --- PROGRESSION & NARRATIVE SIGNALS ---
signal dialogue_finished(dialogue_id: String)
signal minigame_completed(minigame_id: String, success: bool, net_profit: int)
signal day_phase_changed(new_phase: String) # e.g., "morning", "afternoon", "night"
