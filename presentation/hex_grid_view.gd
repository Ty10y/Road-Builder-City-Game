# hex_grid_view.gd
# ---------------------------------------------------------------------------
# PRESENTATION. This is the visual half. It owns the screen — it draws the hex
# grid and reacts to the mouse — but it does NOT own any game truth. All the
# math it needs comes from HexGrid (the sim). If you ever catch this file
# making gameplay decisions instead of just *showing* them, that's the line
# blurring; pull the logic back into /sim.
#
# This script is attached to the root Node2D of main.tscn.
# ---------------------------------------------------------------------------

extends Node2D

const CONSTANTS_PATH := "res://data/constants.json"

var grid: HexGrid                         # the sim object (pure logic)
var cells: Array[Vector2i] = []           # every hex coord on the board
var hovered: Vector2i = Vector2i(999, 999)# which hex the mouse is over (999 = none)

# Colors, loaded from data/constants.json at startup.
var color_fill: Color
var color_outline: Color
var color_hover: Color

@onready var coord_label: Label = $HUD/CoordLabel


func _ready() -> void:
	var cfg := _load_constants()

	# Build the sim grid from data — never from numbers typed into this file.
	var hex_size: float = cfg["hex"]["size"]
	var grid_radius: int = cfg["hex"]["grid_radius"]
	grid = HexGrid.new(hex_size, grid_radius)
	cells = grid.all_cells()

	color_fill = _color_from(cfg["colors"]["tile_fill"])
	color_outline = _color_from(cfg["colors"]["tile_outline"])
	color_hover = _color_from(cfg["colors"]["tile_hover"])

	queue_redraw()


func _process(_delta: float) -> void:
	# get_global_mouse_position() already accounts for the Camera2D, so the
	# point is in the same world space HexGrid does its math in.
	var mouse := get_global_mouse_position()
	var under_mouse := grid.pixel_to_hex(mouse)

	# Only react when the hovered hex actually changes — avoids redrawing every
	# single frame for no reason.
	if under_mouse != hovered:
		hovered = under_mouse
		_update_label()
		queue_redraw()   # ask Godot to call _draw() again this frame


# _draw() is called by Godot whenever we queue_redraw(). All custom 2D drawing
# happens here. We loop every hex, offset the shape to that hex's center, and
# draw a filled polygon plus an outline.
func _draw() -> void:
	var corners := grid.hex_corners()

	for cell in cells:
		var center := grid.hex_to_pixel(cell)

		# Shift the 6 corner points from "around origin" to "around this hex".
		var pts := PackedVector2Array()
		for c in corners:
			pts.append(c + center)

		var is_hovered := (cell == hovered)
		var fill := color_hover if is_hovered else color_fill

		draw_colored_polygon(pts, fill)
		# Close the outline by repeating the first point at the end.
		var outline := pts
		outline.append(pts[0])
		draw_polyline(outline, color_outline, 2.0)


# --- helpers ---------------------------------------------------------------

func _update_label() -> void:
	var on_board := cells.has(hovered)
	if on_board:
		coord_label.text = "hex  q=%d  r=%d" % [hovered.x, hovered.y]
	else:
		coord_label.text = "hex  (off board)"


func _load_constants() -> Dictionary:
	var file := FileAccess.open(CONSTANTS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open %s" % CONSTANTS_PATH)
		return {}
	var text := file.get_as_text()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("constants.json did not parse to a Dictionary")
		return {}
	return data


# Turn a [r, g, b, a] array (0-1 floats) from JSON into a Godot Color.
func _color_from(arr: Array) -> Color:
	return Color(arr[0], arr[1], arr[2], arr[3])
