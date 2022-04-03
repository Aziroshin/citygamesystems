tool
extends Spatial
class_name VisualizationNoodle

var is_post_ready: bool = false
const DEFAULT_START = Vector3(0, 0, 1)
const DEFAULT_END = Vector3(0, 0, -1)
onready var sleeve = $Sleeve
onready var path = $Path

# Since we're also using builder methods for setting and getting start
# and end position, but, at the same time, want tool-compatible
# configurability and the ability to set default values, we're setgetting
# the builder methods for the start and end position here.s
export var start: Vector3 = DEFAULT_START setget set_start, get_start
export var end: Vector3 = DEFAULT_END setget set_end, get_end

func _ready():
	path.curve.clear_points()
	path.curve.add_point(DEFAULT_START)
	path.curve.add_point(DEFAULT_END)
	is_post_ready = true

func get_end_idx() -> int:
	return path.curve.get_point_count() - 1

func get_end() -> Vector3:
	if is_post_ready:
		return path.curve.get_point_position(get_end_idx())
	return DEFAULT_END

func get_start() -> Vector3:
	if is_post_ready:
		return path.curve.get_point_position(0)
	return DEFAULT_START

###
### Builder methods (return self)
###

func add_as_child_to(node: Node) -> VisualizationNoodle:
	node.call_deferred("add_child", self)
	
	# Since the noodles form a connection between two visualizers which aren't
	# necessarily hierarchically related, tying the noodle's transformation
	# to one of them would unnecessarily complicate things.
	self.set_as_toplevel(true)
	
	return self

# Start point of the noodle.
func set_start(position: Vector3) -> VisualizationNoodle:
	start = position
	if is_post_ready:
		path.curve.set_point_position(0, position)
		print("noodle start (orange): %s" % global_transform.origin)
		Cavedig.needle(self, path.curve.get_point_position(0), Cavedig.Colors.ORANGE)
	return self

# End point of the noodle.
func set_end(position: Vector3) -> VisualizationNoodle:
	end = position
	if is_post_ready:
		path.curve.set_point_position(get_end_idx(), position)
		print("noodle end (aqua): %s" % global_transform.origin)
		Cavedig.needle(self, path.curve.get_point_position(get_end_idx()), Cavedig.Colors.AQUA)
	return self
