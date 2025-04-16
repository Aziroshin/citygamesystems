## Draws the outline and (optionally) offset vectors of a `Curve2D` on itself.
extends Node2D
class_name Curve2DDebugVisualizer


const DEFAULT_EDGE_COLOR := Color(0.8, 0.4, 0.1)
const DEFAULT_LEFT_OFFSET_COLOR := Color(0.1, 0.4, 0.8)
const DEFAULT_RIGHT_OFFSET_COLOR := Color(0.4, 0.8, 0.1)
## Will redraw in the next `_draw` call if `true`.
## `_draw` will set this to `false`.
var redraw = false
## Will become `true` when `p_curve` is set. When set to `true`, will also set
## `redraw` to `true`.
## `_update_from_curve` will set this to `false`.
var curve_changed = false:
	set(p_value):
		curve_changed = p_value
		if p_value == true:
			redraw = true
#region Lines.
# Color is set here so individual lines can be given a different color.
enum LineField {
	POINT_1,
	POINT_2,
	COLOR
}
var edges: Array = []
var left_offsets: Array = []
var right_offsets: Array = []
#endregion
#region Line sets.
## Used to index the arrays in the `line_sets` array.
enum LineSetField {
	KIND,
	POINTS_AND_COLOR,
	THICKNESS,
	ANTIALIASED,
	SHOWN_OFFSET_INDEXES,
	COLOR
}
enum LineKind {
	EDGES,
	LEFT_OFFSETS,
	RIGHT_OFFSETS
}
## Line sets (indexed by the `LineKind` enum).
## Each entry is an array indexed by the `LineSetField` enum and contains the
## points and color to draw a line using `draw_line`.
var line_sets: Array = [
	[LineKind.EDGES, edges, 1.0, false, PackedInt64Array(),
	DEFAULT_EDGE_COLOR],
	[LineKind.LEFT_OFFSETS, left_offsets, 1.0, false, PackedInt64Array(),
	DEFAULT_LEFT_OFFSET_COLOR],
	[LineKind.RIGHT_OFFSETS, right_offsets, 1.0, false, PackedInt64Array(),
	DEFAULT_RIGHT_OFFSET_COLOR]
]
#endregion
@export var edge_color: Color:
	get:
		return line_sets[LineKind.EDGES][LineSetField.COLOR]
	set(p_value):
		#edge_color = p_value
		line_sets[LineKind.EDGES][LineSetField.COLOR] = p_value
@export var left_offset_color: Color:
	get:
		return line_sets[LineKind.LEFT_OFFSETS][LineSetField.COLOR]
	set(p_value):
		#left_offset_color = p_value
		line_sets[LineKind.LEFT_OFFSETS][LineSetField.COLOR] = p_value
@export var right_offset_color: Color:
	get:
		return line_sets[LineKind.RIGHT_OFFSETS][LineSetField.COLOR]
	set(p_value):
		#right_offset_color = p_value
		line_sets[LineKind.RIGHT_OFFSETS][LineSetField.COLOR] = p_value
@export var left_offset_length := 20.0
@export var right_offset_length := 20.0
@export var curve := Curve2D.new():
	get:
		return curve
	set(p_value):
		curve = p_value
		curve_changed = true
## If non-empty, will only show the left-offsets of indexes in this array.
@export var shown_left_offset_indexes := PackedInt64Array():
	get:
		return line_sets[LineKind.LEFT_OFFSETS][LineSetField.SHOWN_OFFSET_INDEXES]
	set(p_value):
		line_sets[LineKind.LEFT_OFFSETS][LineSetField.SHOWN_OFFSET_INDEXES] = p_value
## If non-empty, will only show the right-offsets of indexes in this array.
@export var shown_right_offset_indexes := PackedInt64Array():
	get:
		return line_sets[LineKind.RIGHT_OFFSETS][LineSetField.SHOWN_OFFSET_INDEXES]
	set(p_value):
		line_sets[LineKind.RIGHT_OFFSETS][LineSetField.SHOWN_OFFSET_INDEXES] = p_value
@export var show_offsets := true
## Shows all offsets, even when `shown_[left|right]_offset_indexes` aren't
## empty.
@export var show_all_offsets := false


func _ready() -> void:
	transform = transform.scaled(Vector2(2.0, 2.0))


# TODO: Visualize offset of first point.
func _update_from_curve() -> void:
	if curve_changed and curve.point_count > 1:
		var baked_points := curve.get_baked_points()
		var last_point := baked_points[0]
		
		var i_point := 1
		for point in baked_points.slice(1):
			edges.append([last_point, point, null])
			
			left_offsets.append([
				last_point,
				last_point\
					+ (point - last_point).rotated(-(PI * 0.5)).normalized()\
					* left_offset_length,
				null,
			])
			right_offsets.append([
				last_point,
				last_point\
					+ (point - last_point).rotated((PI * 0.5)).normalized()\
					* right_offset_length,
				null,
			])
			last_point = point
			i_point += 1
		curve_changed = false


func _draw() -> void:
	_update_from_curve()
	
	if not redraw:
		return

	for line_set in line_sets:
		var kind: LineKind = line_set[LineSetField.KIND]
		
		if not show_offsets\
		and (kind == LineKind.LEFT_OFFSETS or kind == LineKind.RIGHT_OFFSETS):
			continue
		
		var shown_offset_indexes: PackedInt64Array = line_set[LineSetField.SHOWN_OFFSET_INDEXES]
		var hide_non_shown_offsets := not show_all_offsets and not len(shown_offset_indexes) == 0
		var i_line := 0
		for line in line_set[LineSetField.POINTS_AND_COLOR]:
			if hide_non_shown_offsets:
				if not i_line in shown_offset_indexes:
					continue
			
			var line_offset_color_or_null = line[LineField.COLOR]
			var color: Color =\
				line_offset_color_or_null if not line_offset_color_or_null == null\
				else line_set[LineSetField.COLOR]
			draw_line(
				line[LineField.POINT_1],  # point 1
				line[LineField.POINT_2],  # point 2
				color,  # color
				line_set[LineSetField.THICKNESS],
				line_set[LineSetField.ANTIALIASED]
			)
			i_line += 1
	redraw = false


func _on_curve_changed(p_curve: Curve2D) -> void:
	curve = p_curve
