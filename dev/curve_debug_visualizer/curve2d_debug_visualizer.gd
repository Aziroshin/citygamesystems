## Draws the outline and (optionally) offset vectors of a `Curve2D` on itself.
extends Node2D
class_name Curve2dDebugVisualizer


signal finished_drawing
const DEFAULT_EDGE_COLOR := Color(0.8, 0.4, 0.1)
const DEFAULT_LEFT_OFFSET_COLOR := Color(0.1, 0.4, 0.8)
const DEFAULT_RIGHT_OFFSET_COLOR := Color(0.4, 0.8, 0.1)
const DEFAULT_FORWARD_COLOR := Color(0.8, 0.8, 0.4)
## Setting `curve` will set this to `true.`
## `_update_from_curve` will set this to `false`.
var curve_changed = false:
	set(p_value):
		curve_changed = p_value
		if p_value == true:
			self.queue_redraw()
		
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
var forwards: Array = []
#endregion
#region Line sets.
## Used to index the arrays in the `line_sets` array.
enum LineSetField {
	KIND,
	POINTS_AND_COLOR,
	THICKNESS,
	ANTIALIASED,
	MARKED_INDEXES,
	SHOW,
	COLOR
}
enum LineKind {
	EDGES,
	LEFT_OFFSETS,
	RIGHT_OFFSETS,
	FORWARDS
}
## Line sets (indexed by the `LineKind` enum).
## Each entry is an array indexed by the `LineSetField` enum and contains the
## points and color to draw a line using `draw_line`.
var line_sets: Array = [
	[LineKind.EDGES, edges, 2.0, false, PackedInt64Array(), true,
	DEFAULT_EDGE_COLOR],
	[LineKind.LEFT_OFFSETS, left_offsets, 1.0, false, PackedInt64Array(), true,
	DEFAULT_LEFT_OFFSET_COLOR],
	[LineKind.RIGHT_OFFSETS, right_offsets, 1.0, false, PackedInt64Array(), true,
	DEFAULT_RIGHT_OFFSET_COLOR],
	[LineKind.FORWARDS, forwards, 0.4, false, PackedInt64Array(), true,
	DEFAULT_FORWARD_COLOR]
]
#endregion
@export var edge_color: Color:
	get:
		return line_sets[LineKind.EDGES][LineSetField.COLOR]
	set(p_value):
		line_sets[LineKind.EDGES][LineSetField.COLOR] = p_value
@export var left_offset_color: Color:
	get:
		return line_sets[LineKind.LEFT_OFFSETS][LineSetField.COLOR]
	set(p_value):
		line_sets[LineKind.LEFT_OFFSETS][LineSetField.COLOR] = p_value
@export var right_offset_color: Color:
	get:
		return line_sets[LineKind.RIGHT_OFFSETS][LineSetField.COLOR]
	set(p_value):
		line_sets[LineKind.RIGHT_OFFSETS][LineSetField.COLOR] = p_value
@export var forward_color: Color:
	get:
		return line_sets[LineKind.FORWARDS][LineSetField.COLOR]
	set(p_value):
		line_sets[LineKind.FORWARDS][LineSetField.COLOR] = p_value
@export var left_offset_length := 20.0
@export var right_offset_length := 20.0
@export var forward_length := 20.0
@export var curve := Curve2D.new():
	get:
		return curve
	set(p_value):
		curve = p_value
		curve_changed = true
@export var marked_left_offset_indexes: PackedInt64Array:
	get:
		return line_sets[LineKind.LEFT_OFFSETS][LineSetField.MARKED_INDEXES]
	set(p_value):
		line_sets[LineKind.LEFT_OFFSETS][LineSetField.MARKED_INDEXES] = p_value
@export var marked_right_offset_indexes: PackedInt64Array:
	get:
		return line_sets[LineKind.RIGHT_OFFSETS][LineSetField.MARKED_INDEXES]
	set(p_value):
		line_sets[LineKind.RIGHT_OFFSETS][LineSetField.MARKED_INDEXES] = p_value
@export var marked_forward_indexes: PackedInt64Array:
	get:
		return line_sets[LineKind.FORWARDS][LineSetField.MARKED_INDEXES]
	set(p_value):
		line_sets[LineKind.FORWARDS][LineSetField.MARKED_INDEXES] = p_value
@export var show_left_offsets := true:
	get:
		return line_sets[LineKind.LEFT_OFFSETS][LineSetField.SHOW]
	set(p_value):
		line_sets[LineKind.LEFT_OFFSETS][LineSetField.SHOW] = p_value
@export var show_right_offsets := true:
	get:
		return line_sets[LineKind.RIGHT_OFFSETS][LineSetField.SHOW]
	set(p_value):
		line_sets[LineKind.RIGHT_OFFSETS][LineSetField.SHOW] = p_value
@export var show_forwards := true:
	get:
		return line_sets[LineKind.FORWARDS][LineSetField.SHOW]
	set(p_value):
		line_sets[LineKind.FORWARDS][LineSetField.SHOW] = p_value
@export var show_edges := true:
	get:
		return line_sets[LineKind.EDGES][LineSetField.SHOW]
	set(p_value):
		line_sets[LineKind.EDGES][LineSetField.SHOW] = p_value
enum FilterMode {
	NONE,
	SHOW,
	HIDE
}
@export var marked_indexes_filter_mode := FilterMode.NONE
enum FilterOverrideDirection {
	BASE_OVERRIDES_LINE,
	LINE_OVERRIDES_BASE
}
@export var marked_indexes_filter_override_direction := FilterOverrideDirection.LINE_OVERRIDES_BASE
enum FilterOverrideMode  {
	ADDITIVE,
	SUBTRACTIVE
}
@export var marked_indexes_filter_override_Mode := FilterOverrideMode.ADDITIVE
@export var base_marked_indexes := PackedInt64Array()


func _ready() -> void:
	transform = transform.scaled(Vector2(2.0, 2.0))


func _update_lines_from_transforms(transform_1: Transform2D, transform_2: Transform2D) -> void:
	var point_1 := transform_1.origin
	var point_2 := transform_2.origin
	left_offsets.append([
		point_1,
		point_1 - transform_1.y * left_offset_length,
		null,
	])
	right_offsets.append([
		point_1,
		point_1 + transform_1.y * left_offset_length,
		null,
	])
	forwards.append([
		point_1,
		point_1\
			+ (point_2 - point_1).normalized()\
			* forward_length,
		null
	])


## Updates the data to be drawn based on `Curve2D.sample_baked_with_rotation`.
func _update_from_curve_by_sampling() -> void:
	if curve_changed and curve.point_count > 1:
		var baked_points := curve.get_baked_points()
		var last_point := baked_points[0]
		
		var i_point := 1
		for point in baked_points.slice(1):
			var last_point_transform := GeoFoo.get_baked_point_transform_2d(curve, i_point - 1)
			var point_transform := GeoFoo.get_baked_point_transform_2d(curve, i_point)
			edges.append([last_point, point, null])
			_update_lines_from_transforms(
				GeoFoo.get_baked_point_transform_2d(curve, i_point - 1),
				GeoFoo.get_baked_point_transform_2d(curve, i_point)
			)
			last_point = point
			i_point += 1
		
		var last_point_transform := GeoFoo.get_baked_point_transform_2d(
			curve,
			len(baked_points) - 1
		)
		var fake_point_beyond_last_point_transform := GeoFoo.get_baked_point_transform_2d(
			curve,
			len(baked_points) - 1
		)
		fake_point_beyond_last_point_transform.origin =\
			fake_point_beyond_last_point_transform.origin\
			+ fake_point_beyond_last_point_transform.x * 5.0
		_update_lines_from_transforms(
			last_point_transform,
			fake_point_beyond_last_point_transform
		)
			
		curve_changed = false


func _update_from_curve() -> void:
	_update_from_curve_by_sampling()


func _draw() -> void:
	_update_from_curve()

	for line_set in line_sets:
		var kind: LineKind = line_set[LineSetField.KIND]
		
		if not line_set[LineSetField.SHOW]:
			continue
		
		# The default is assumed to be `FilterOverrideDirection.LINE_OVERRIDES_BASE`:
		var overriding_marked_indexes: PackedInt64Array = line_set[LineSetField.MARKED_INDEXES]
		var overridable_marked_indexes: PackedInt64Array = base_marked_indexes
		if  marked_indexes_filter_override_direction == FilterOverrideDirection.BASE_OVERRIDES_LINE:
			overriding_marked_indexes = base_marked_indexes
			overridable_marked_indexes = line_set[LineSetField.MARKED_INDEXES]
			
		var i_line := -1  # To accommodate the early increment due to the early continues.
		for line in line_set[LineSetField.POINTS_AND_COLOR]:
			i_line += 1
			if not kind == LineKind.EDGES:
				if marked_indexes_filter_mode == FilterMode.SHOW:
					# For ease of understanding, the conditoinals below are
					# categorized in a comment each as being a `showlist` or a
					# `hidelist` in terms of what their *_marked_indexes array
					# means there.
					if marked_indexes_filter_override_Mode == FilterOverrideMode.ADDITIVE:
						# showlist
						if not i_line in overriding_marked_indexes\
						# showlist
						and not i_line in overridable_marked_indexes:
							continue
					elif marked_indexes_filter_override_Mode == FilterOverrideMode.SUBTRACTIVE:
						# hidelist
						if i_line in overriding_marked_indexes\
						# showlist
						or not i_line in overridable_marked_indexes:
							continue
				elif marked_indexes_filter_mode == FilterMode.HIDE:
					if marked_indexes_filter_override_Mode == FilterOverrideMode.ADDITIVE:
						# hidelist
						if i_line in overriding_marked_indexes\
						# hidelist
						or i_line in overridable_marked_indexes:
							continue
					elif marked_indexes_filter_override_Mode == FilterOverrideMode.SUBTRACTIVE:
						# showlist
						if not i_line in overriding_marked_indexes\
						# hidelist
						and i_line in overridable_marked_indexes:
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
	finished_drawing.emit()


func _on_curve_changed(p_curve: Curve2D) -> void:
	curve = p_curve
