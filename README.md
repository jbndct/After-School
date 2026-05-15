# After-School 🎮

![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.x-blue?logo=godotengine&logoColor=white)

## 📖 Short Description

**After-School** is a 2D life-simulation role-playing game built in the Godot Engine. The game places players in the shoes of a student navigating life outside the classroom, requiring them to balance work, academics, and personal finances in a Philippine-inspired urban setting.

---

## 📑 Table of Contents

- [Gameplay Overview](#️-gameplay-overview)
- [Features](#-features)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Controls & Keybindings](#️-controls--keybindings)
- [Configuration](#️-configuration)
- [Export & Build Instructions](#-export--build-instructions)
- [Plugins & Addons](#-plugins--addons)
- [Contributing](#-contributing)
- [License](#-license)
- [Credits & Acknowledgements](#-credits--acknowledgements)
- [Contact & Links](#-contact--links)

---

## 🕹️ Gameplay Overview

The core gameplay loop revolves around resource and time management. Players explore various distinct environments — the street, their room, the school, the workplace, and a gambling hub — to complete objectives. Success requires managing digital finances via an in-game smartphone featuring EPera integration, and passing specific career or academic hurdles via distinct minigames.

The game adopts a critical lens on student life, presenting concrete challenges like scholarship interviews and the temptation of illicit gambling ("Sugal") rather than a purely idealized school experience.

---

## ✨ Features

- **Explorable Hubs**: Seamlessly transition between distinct locales including `school`, `street`, `room`, `workplace`, and `SugalHub`.
- **Dynamic Minigames**:
  - **Scholarship Exam**: A trivia/quiz minigame driven by an external JSON data file (`scholarship_questions.json`).
  - **Work Tasks**: Scenario-based interactions to earn income and progress the story.
- **Custom Dialogue System**: Powered by a global `DialogManager` and an event bus (`EventBus.gd`), enabling rich NPC interactions (e.g., School Guard, Registrar).
---

## 🚀 Getting Started

### Prerequisites

- **Godot Engine**: Version 4.x (Standard Edition)
- No .NET/C# runtime required — the project uses GDScript exclusively.

### Installation

1. Clone the repository:

```
git clone https://github.com/jbndct/after-school.git
```

2. Open **Godot Engine** and click **Import**.

3. Navigate to the cloned directory and select the `project.godot` file.

4. Click **Import & Edit** to load the project.

### Running the Project

- Press **F5** or click the **Play** button in the Godot editor to run the main scene.
- To test a specific scene (e.g., `MinigameWork.tscn`), open that scene and press **F6**.

---

## 📁 Project Structure

```
├── assets/                          # Art assets, sprites, and fonts
│   ├── sprites/                     # Characters, environments, and UI icons
│   │   └── Player/                  # Segmented player limbs and animation poses
│   └── ui/                          # Custom fonts and dialogue box textures
├── data/
│   └── scholarship_questions.json   # Data source for the scholarship minigame
├── scenes/                          # Godot scene files (.tscn)
│   ├── Levels/                      # room, school, street, workplace, SugalHub
│   ├── Minigames/                   # MinigameInterview, MinigameScholarship, MinigameWork
│   └── UI/                          # Player, Menu, SmartphoneUI, DialogueBox
├── scripts/                         # GDScript files (.gd)
│   ├── Core/                        # GameState.gd, RunState.gd, SceneManager.gd, EventBus.gd
│   └── Controllers/                 # menu.gd, player.gd, smartphoneUI.gd
├── singleton/
│   └── DialogManager.gd             # Global dialogue rendering and queuing
├── project.godot                    # Core Godot project configuration
└── icon.svg                         # Application icon
```

---

## ⌨️ Controls & Keybindings

| Action | Key / Input |
| :--- | :--- |
| Move Left / Right | `A` / `D` or `←` / `→` Arrow Keys |
| Jump | `Space` or `↑` Arrow Key |
| Interact | `E` or `Enter` |
| Open Smartphone | `Tab` or `M` |
| UI Navigate | Mouse Click / Arrow Keys |

---

## ⚙️ Configuration

Game state is managed by global singletons (`GameState.gd` and `RunState.gd`).

- To adjust starting money, initial dialogue flags, or player stats for testing, modify the initialization variables in `scripts/GameState.gd`.
- Dialogue trees and NPC interactions are handled through `DialogManager` in the `singleton/` folder.

---

## 📦 Export & Build Instructions

1. In the Godot Editor, go to **Project → Export...**
2. If `export_presets.cfg` is missing, click **Add...** and select your target platform (e.g., Windows Desktop, macOS, Linux/X11).
3. Ensure the **Godot Export Templates** are downloaded for your editor version via **Editor → Manage Export Templates**.
4. Click **Export Project**, choose a destination folder, and uncheck **Export With Debug** for release builds.

---

## 🧩 Plugins & Addons

The project uses standard Godot Engine nodes and features only. No third-party plugins from the Godot Asset Library were detected in an `addons/` directory.

---

## 🤝 Contributing

1. Fork the project
2. Create your feature branch: `git checkout -b feature/AmazingFeature`
3. Commit your changes: `git commit -m 'Add some AmazingFeature'`
4. Push to the branch: `git push origin feature/AmazingFeature`
5. Open a Pull Request

**Code Style Conventions:**
- Follow standard [GDScript style guidelines](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- Scene files (`.tscn`) should use `PascalCase`; script files (`.gd`) should use `snake_case`.

---

## 🏆 Credits & Acknowledgements

- **Development & Art**: Created by the After-School team (John Benedict P. Baladia, Kirsten Gail A. Querubin, Arwen Fajardo)
- **Typography**: [IosevkaCharon-Regular](https://github.com/be5invis/Iosevka) typeface
- **Engine**: Built with [Godot Engine](https://godotengine.org/)

