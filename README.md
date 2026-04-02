# After School

**After School** is a 2D narrative management game about financial anxiety, exhaustion, and the temptation of easy money. You play as a working student desperately trying to scrape together ₱15,000 for his college tuition before the deadline, all while balancing classes, a grueling night shift as a security guard, and the ever-present ping of a shady gambling app called SugalHub.

## 📖 Synopsis

The deadline is today. Your balance is ₱2,000. Your paycheck clears tonight for ₱6,500. You are drastically short. 

Navigate the player's exhausting routine across four distinct parts of the story. Attend classes to keep your scholarship, clock in for your night shift to secure your paycheck, and decide whether to stick it out the hard way or give in to the "easy money" promised by your friend Mark. Every choice leads to the registrar's office—will you have enough to stay enrolled?

## ✨ Key Features

* **Linear Narrative Flow:** A structured, 4-part story progression seamlessly managed by a global `GameState` singleton.
* **Dynamic Environments:** Hub-based street navigation where dialogue, objectives, and accessible doors change based on the time of day and current story step.
* **Contextual Dialogue System:** Interact with the world using a custom dialogue engine that updates based on the player's current progression index.
* **Consequence-Driven Mechanics:** Track finances, debt, and "SugalHub" usage. Giving into temptation permanently alters your playthrough path.
* **Integrated Minigames:** (In Development) Custom minigames for Scholarship Exams, Job Interviews, and Work Shifts seamlessly sandwiched between narrative beats.

## 🛠️ Tech Stack & Architecture

* **Engine:** Built in [Godot Engine](https://godotengine.org/) (GDScript).
* **State Management:** Uses an Autoload `GameState.gd` singleton to track player money, debt, relationships, and current narrative position (`current_part`, `current_step_index`).
* **Scene Swapping:** A modular array-based progression flow allows for dynamic transitions between the `Room`, `Street`, `School`, `Workplace`, and `Minigames` without hardcoding destinations into the levels themselves.

### Core File Structure
* `scripts/GameState.gd` - The brain of the game. Handles arrays, scene transitions, and global variables.
* `scenes/street.tscn` - The central hub. Parses the GameState to determine which doors are unlocked and what objective to display.
* `scenes/room.tscn`, `school.tscn`, `workplace.tscn` - Interior environments utilizing a unified `[E] to Interact` mechanic and event-driven dialogue triggers.

## 🚀 How to Run the Project

1. Clone the repository to your local machine.
2. Open the **Godot Engine** project manager.
3. Click **Import** and navigate to the `project.godot` file in the cloned folder.
4. Open the project.
5. Open `res://scenes/Menu.tscn` and click the **Play** button (F5) to start the game loop from the beginning.

---
*Created as a project for CSMC221: Software Engineering and its associated 2026 Software Festival.*
