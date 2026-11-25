@tool
extends EditorScript
## Builds DialogueBubble.tscn and MissionBanner.tscn so you don't have to place nodes by hand.
## HOW TO RUN: put this file anywhere in the project, open it, then File > Run (Ctrl+Shift+X).
## WARNING: re-running overwrites the two scenes (any hand edits to them are lost).

# ---------- EDIT THESE ----------
const SCRIPT_DIR := "res://scripts/ui/"   # where you saved the 4 helper scripts
const SCENE_DIR := "res://scenes/ui/"     # where the new scenes will be saved
# --------------------------------

var INK := Color("#2B2B2B")   # must match INK in build_game_theme.gd (bubble color)


func _run() -> void:
	for f in ["typewriter_label.gd", "triangle_icon.gd", "dialogue_bubble.gd", "mission_banner.gd"]:
		if not ResourceLoader.exists(SCRIPT_DIR + f):
			push_error("Missing script: " + SCRIPT_DIR + f + "  (fix SCRIPT_DIR or move the file)")
			return
	_build_bubble()
	_build_mission()
	EditorInterface.get_resource_filesystem().scan()
	print("Done. Scenes saved in ", SCENE_DIR)


func _build_bubble() -> void:
	var root := Control.new()
	root.name = "DialogueBubble"
	root.set_script(load(SCRIPT_DIR + "dialogue_bubble.gd"))
	_full_rect(root)

	var bubble := VBoxContainer.new()
	bubble.add_theme_constant_override("separation", 0)
	_add(root, bubble, "Bubble", root)

	var panel := PanelContainer.new()
	panel.theme_type_variation = &"DialogueBubble"
	_add(bubble, panel, "Panel", root)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_add(panel, row, "Row", root)

	var text := RichTextLabel.new()
	text.set_script(load(SCRIPT_DIR + "typewriter_label.gd"))
	text.theme_type_variation = &"BubbleText"
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.custom_minimum_size = Vector2(120, 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add(row, text, "Text", root, true)

	var col := VBoxContainer.new()
	_add(row, col, "SkipCol", root)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add(col, spacer, "Spacer", root)

	_add(col, _triangle(false, Color.WHITE, Vector2(10, 12)), "SkipIcon", root, true)

	var tail := _triangle(true, INK, Vector2(24, 12))
	tail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_add(bubble, tail, "Tail", root)

	_ignore_mouse(root)
	_save(root, SCENE_DIR + "DialogueBubble.tscn")


func _build_mission() -> void:
	var root := Control.new()
	root.name = "MissionBanner"
	root.set_script(load(SCRIPT_DIR + "mission_banner.gd"))
	_full_rect(root)

	var top := CenterContainer.new()
	top.anchor_right = 1.0
	top.offset_top = 32.0
	_add(root, top, "Top", root)

	var panel := PanelContainer.new()
	panel.theme_type_variation = &"MissionPanel"
	_add(top, panel, "Panel", root)

	var text := RichTextLabel.new()
	text.set_script(load(SCRIPT_DIR + "typewriter_label.gd"))
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_add(panel, text, "Text", root, true)

	_ignore_mouse(root)
	_save(root, SCENE_DIR + "MissionBanner.tscn")


# ---------- helpers ----------
func _add(parent: Node, child: Node, node_name: String, root: Node, unique: bool = false) -> void:
	child.name = node_name
	parent.add_child(child)
	child.owner = root
	if unique:
		child.unique_name_in_owner = true


func _triangle(down: bool, color: Color, min_size: Vector2) -> Control:
	var t := Control.new()
	t.set_script(load(SCRIPT_DIR + "triangle_icon.gd"))
	t.set("points_down", down)
	t.set("color", color)
	t.custom_minimum_size = min_size
	return t


func _full_rect(c: Control) -> void:
	c.anchor_left = 0.0
	c.anchor_top = 0.0
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


func _ignore_mouse(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)


func _save(root: Node, path: String) -> void:
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		err = ResourceSaver.save(ps, path)
	if err == OK:
		print("Saved ", path)
	else:
		push_error("Could not save %s (error %d)" % [path, err])
	root.free()
