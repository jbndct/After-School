@tool
class_name TriangleIcon
extends Control
## Draws a filled triangle. Used for the dialogue bubble tail (down) and the skip arrow (right).

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()

@export var points_down: bool = true:
	set(value):
		points_down = value
		queue_redraw()


func _draw() -> void:
	var s := size
	var pts: PackedVector2Array
	if points_down:
		pts = PackedVector2Array([Vector2(0, 0), Vector2(s.x, 0), Vector2(s.x * 0.5, s.y)])
	else:
		pts = PackedVector2Array([Vector2(0, 0), Vector2(s.x, s.y * 0.5), Vector2(0, s.y)])
	draw_colored_polygon(pts, color)
