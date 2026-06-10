# hex_grid.gd
# ---------------------------------------------------------------------------
# PURE LOGIC. No visuals, no nodes, no rendering. This file knows nothing about
# how a hex looks on screen — only the math of where hexes are and which one a
# point falls in. This is the "sim" half of the sim/presentation split your
# design doc calls for. Everything visual lives in /presentation and READS from
# code like this; it never writes back. Keeping this rule from rung 1 is what
# makes save/load and offline-accrual sane much later.
#
# Coordinate system: AXIAL (q, r). This is the single most important thing to
# get right in a hex game. There are several hex coordinate systems and mixing
# them is the classic bug. We commit to axial everywhere. Reference (bookmark
# this): https://www.redblobgames.com/grids/hexagons/
#
# Orientation: POINTY-TOP (a corner of the hex points straight up).
# ---------------------------------------------------------------------------

class_name HexGrid
extends RefCounted

# RefCounted = a lightweight object that is NOT part of the scene tree. It has
# no position on screen and is freed automatically when nothing references it.
# Perfect for pure logic.

var size: float          # center-to-corner distance, in pixels
var radius: int          # number of rings around the center hex

func _init(hex_size: float, grid_radius: int) -> void:
	size = hex_size
	radius = grid_radius


# --- Which hexes exist -----------------------------------------------------

# Returns every axial coordinate in a hexagon-shaped board of the given radius.
# A Vector2i is just an integer pair; here .x = q and .y = r.
func all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		# For a hexagonal board, r is clamped so the shape is a hexagon, not a
		# rhombus. This is the standard axial-range formula.
		var r_min := maxi(-radius, -q - radius)
		var r_max := mini(radius, -q + radius)
		for r in range(r_min, r_max + 1):
			cells.append(Vector2i(q, r))
	return cells


# --- Axial coord  ->  pixel position ---------------------------------------

# Given a hex's (q, r), where is its CENTER in world pixels?
# These are the pointy-top conversion constants from Red Blob Games.
func hex_to_pixel(hex: Vector2i) -> Vector2:
	var q := float(hex.x)
	var r := float(hex.y)
	var x := size * (sqrt(3.0) * q + sqrt(3.0) / 2.0 * r)
	var y := size * (3.0 / 2.0 * r)
	return Vector2(x, y)


# --- Pixel position  ->  axial coord ---------------------------------------

# Given a world-pixel point (e.g. the mouse), which hex is it inside?
# Two steps: convert to fractional axial coords, then round to the nearest
# real hex (rounding in hex space is not just round() — see hex_round).
func pixel_to_hex(point: Vector2) -> Vector2i:
	var q := (sqrt(3.0) / 3.0 * point.x - 1.0 / 3.0 * point.y) / size
	var r := (2.0 / 3.0 * point.y) / size
	return hex_round(q, r)


# Rounding a fractional hex coordinate to the nearest whole hex. You can't just
# round q and r independently — that lands in the wrong hex near borders. The
# trick is to convert to CUBE coords (q, r, s) where q + r + s = 0, round all
# three, then fix up whichever drifted most to restore that constraint.
func hex_round(qf: float, rf: float) -> Vector2i:
	var sf := -qf - rf                      # cube's third axis
	var q := roundi(qf)
	var r := roundi(rf)
	var s := roundi(sf)

	var q_diff := absf(q - qf)
	var r_diff := absf(r - rf)
	var s_diff := absf(s - sf)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	# (if s drifted most we just drop it; r and q already define the hex)

	return Vector2i(q, r)


# --- Corner geometry (used by the renderer to draw the shape) --------------

# The 6 corner points of a hex, relative to its center, as a PackedVector2Array
# ready to hand to draw_polygon / draw_polyline. Pointy-top means the first
# corner sits at 30 degrees, so a vertex points up.
func hex_corners() -> PackedVector2Array:
	var corners := PackedVector2Array()
	for i in range(6):
		var angle_deg := 60.0 * i - 30.0
		var angle_rad := deg_to_rad(angle_deg)
		corners.append(Vector2(size * cos(angle_rad), size * sin(angle_rad)))
	return corners
