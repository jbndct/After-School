@tool
extends EditorScript
## Builds res://themes/game_theme.tres from the AfterSchool branding sheet.
## HOW TO RUN: open this file in the Script editor, then File > Run (Ctrl+Shift+X).
## Safe to re-run after changing colors or paths. It OVERWRITES the theme file,
## so close game_theme.tres in the Inspector first and don't hand-edit it.

# ---------- EDIT THESE PATHS ----------
const OUT_PATH := "res://themes/game_theme.tres"
const FONT_BODY := "res://assets/fonts/Stack_Sans_Headline/StackSansHeadline-VariableFont_wght.ttf"
const FONT_BOLD := "res://assets/fonts/Stack_Sans_Headline/StackSansHeadline-VariableFont_wght.ttf"
const FONT_TITLE := "res://assets/fonts/Palette_Mosaic/PaletteMosaic-Regular.ttf"
# Optional: dialogue bubble WITH tail, exported as PNG from your design ("" = skip)
const BUBBLE_TAIL_TEX := ""
# --------------------------------------

# Palette from the branding sheet
var ORANGE := Color("#F7640F")
var AMBER := Color("#FF9D00")
var TEAL := Color("#41B9A7")
var TEAL_DARK := Color("#35A090")
var WHITE := Color("#FFFFFF")
var BROWN := Color("#745C42")
var PEACH := Color("#FFEBD4")
var CREAM := Color("#FFFAF3")   # panel background, eyedrop your sheet to confirm
var TRACK := Color("#EEE9E3")   # slider track
var INK := Color("#2B2B2B")     # dark dialogue bubbles and key caps


func _run() -> void:
	var t := Theme.new()
	var body := _font(FONT_BODY)
	var bold := _font(FONT_BOLD)
	var title := _font(FONT_TITLE)

	if body:
		t.default_font = body
	t.default_font_size = 22

	# ---------- Label ----------
	t.set_color("font_color", "Label", BROWN)

	# ---------- RichTextLabel (used for "Mission: Go outside.") ----------
	t.set_color("default_color", "RichTextLabel", BROWN)
	if body:
		t.set_font("normal_font", "RichTextLabel", body)
	if bold:
		t.set_font("bold_font", "RichTextLabel", bold)

	# ---------- Button ----------
	t.set_stylebox("normal", "Button", _box(PEACH, 12))
	t.set_stylebox("hover", "Button", _box(Color("#FFE0BF"), 12))
	t.set_stylebox("pressed", "Button", _box(Color("#FFD3A3"), 12))
	t.set_stylebox("disabled", "Button", _box(Color("#F5EDE3"), 12))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", BROWN)
	t.set_color("font_disabled_color", "Button", Color(BROWN, 0.5))
	t.set_font_size("font_size", "Button", 24)

	# ---------- HSlider (teal fill, round teal knob) ----------
	var thin := Vector4(0, 3, 0, 3)
	t.set_stylebox("slider", "HSlider", _box(TRACK, 4, 0, Color.TRANSPARENT, thin))
	t.set_stylebox("grabber_area", "HSlider", _box(TEAL, 4, 0, Color.TRANSPARENT, thin))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(TEAL_DARK, 4, 0, Color.TRANSPARENT, thin))
	t.set_icon("grabber", "HSlider", _circle(TEAL))
	t.set_icon("grabber_highlight", "HSlider", _circle(TEAL_DARK))
	t.set_icon("grabber_disabled", "HSlider", _circle(Color(TEAL, 0.4)))

	# ---------- Panels (cream, orange border, shadow) ----------
	var panel := _box(CREAM, 24, 4, ORANGE, Vector4(24, 24, 24, 24))
	panel.shadow_size = 12
	panel.shadow_color = Color(0, 0, 0, 0.25)
	panel.shadow_offset = Vector2(0, 4)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel.duplicate())
	t.set_stylebox("panel", "PopupPanel", panel.duplicate())

	# ---------- TitleLabel ("PAUSED") ----------
	t.set_type_variation("TitleLabel", "Label")
	if title:
		t.set_font("font", "TitleLabel", title)
	t.set_font_size("font_size", "TitleLabel", 48)
	t.set_color("font_color", "TitleLabel", ORANGE)

	# ---------- GearButton (round teal settings badge with white ring) ----------
	t.set_type_variation("GearButton", "Button")
	t.set_stylebox("normal", "GearButton", _box(TEAL, 64, 5, WHITE, Vector4(8, 8, 8, 8)))
	t.set_stylebox("hover", "GearButton", _box(TEAL_DARK, 64, 5, WHITE, Vector4(8, 8, 8, 8)))
	t.set_stylebox("pressed", "GearButton", _box(TEAL_DARK, 64, 5, WHITE, Vector4(8, 8, 8, 8)))
	t.set_stylebox("focus", "GearButton", StyleBoxEmpty.new())
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
		t.set_color(c, "GearButton", WHITE)

	# ---------- MissionPanel ("Mission: Go outside.") ----------
	_panel_variation(t, "MissionPanel", _box(Color("#FFF1DD"), 12, 4, TEAL, Vector4(22, 10, 22, 10)))

	# ---------- Dialogue bubbles (dark, white text) ----------
	_panel_variation(t, "DialogueBubble", _box(INK, 16, 0, Color.TRANSPARENT, Vector4(20, 14, 20, 14)))
	t.set_type_variation("BubbleLabel", "Label")
	t.set_color("font_color", "BubbleLabel", WHITE)
	t.set_type_variation("BubbleText", "RichTextLabel")
	t.set_color("default_color", "BubbleText", WHITE)

	if BUBBLE_TAIL_TEX != "" and ResourceLoader.exists(BUBBLE_TAIL_TEX):
		var sbt := StyleBoxTexture.new()
		sbt.texture = load(BUBBLE_TAIL_TEX)
		sbt.texture_margin_left = 24
		sbt.texture_margin_top = 24
		sbt.texture_margin_right = 24
		sbt.texture_margin_bottom = 44   # includes the tail, adjust to your PNG
		sbt.content_margin_left = 20
		sbt.content_margin_top = 14
		sbt.content_margin_right = 20
		sbt.content_margin_bottom = 30
		t.set_type_variation("DialogueBubbleTail", "PanelContainer")
		t.set_stylebox("panel", "DialogueBubbleTail", sbt)

	# ---------- Key prompts (WASD, Space, Skip) ----------
	_panel_variation(t, "KeyCap", _box(INK, 8, 2, WHITE, Vector4(12, 4, 12, 4)))
	_panel_variation(t, "KeyCapDim", _box(Color("#6E6E6E"), 8, 2, Color("#8C8C8C"), Vector4(12, 4, 12, 4)))
	_panel_variation(t, "SkipPill", _box(Color(0, 0, 0, 0.35), 12, 0, Color.TRANSPARENT, Vector4(8, 6, 16, 6)))
	_panel_variation(t, "IconChip", _box(INK, 10, 0, Color.TRANSPARENT, Vector4(8, 8, 8, 8)))
	t.set_type_variation("KeyLabel", "Label")
	t.set_color("font_color", "KeyLabel", WHITE)
	t.set_font_size("font_size", "KeyLabel", 20)
	if bold:
		t.set_font("font", "KeyLabel", bold)

	# ---------- Save ----------
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	var err := ResourceSaver.save(t, OUT_PATH)
	if err == OK:
		print("game_theme saved to ", OUT_PATH)
		EditorInterface.get_resource_filesystem().scan()
	else:
		push_error("Could not save theme. Error code: %d" % err)


# ---------- helpers ----------
func _font(path: String) -> Font:
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Font
	push_warning("Font not found, skipped: " + path)
	return null


# m = Vector4(left, top, right, bottom) content margins
func _box(bg: Color, radius: int = 12, border: int = 0, border_color: Color = Color.TRANSPARENT, m: Vector4 = Vector4(16, 14, 16, 14)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_color
	sb.content_margin_left = m.x
	sb.content_margin_top = m.y
	sb.content_margin_right = m.z
	sb.content_margin_bottom = m.w
	return sb


func _panel_variation(t: Theme, type_name: String, box: StyleBox) -> void:
	t.set_type_variation(type_name, "PanelContainer")
	t.set_stylebox("panel", type_name, box)


# Draws a smooth filled circle so you don't need a PNG for the slider knob
func _circle(color: Color, size: int = 28) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := (size - 1) / 2.0
	var radius := size / 2.0 - 1.0
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(Vector2(center, center))
			var a := clampf(radius - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(color, a))
	return ImageTexture.create_from_image(img)
