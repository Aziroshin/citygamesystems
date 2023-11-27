@tool
extends Node3D
class_name VisualizationNoodle

var is_post_ready: bool = false
const DEFAULT_START = Vector3(0, 0, 1)
const DEFAULT_END = Vector3(0, 0, -1)
@onready var sleeve = $Sleeve
@onready var path = $Path

# Since we're also using builder methods for setting and getting start
# and end position, but, at the same time, want tool-compatible
# configurability and the ability to set default values, we're setgetting
# the builder methods for the start and end position here.s
@export var start: Vector3 = DEFAULT_START:
	get:
		return get_start()
	set(p_value):
		set_start(p_value)
@export var end: Vector3 = DEFAULT_END:
	get:
		return get_end()
	set(p_value):
		set_end(p_value)

func _ready():
	path.curve.clear_points()
	path.curve.add_point(DEFAULT_START)
	path.curve.add_point(DEFAULT_END)
	is_post_ready = true

func set_size(p_new_size: float) -> VisualizationNoodle:
	call_deferred("_deferred_set_size", p_new_size)
	return self
#	if is_post_ready:
#		call_deferred("_deferred_set_size", new_size)
#		return self
#
#	self.connect("ready", self, "set_size", [new_size])
#	return self

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

func _deferred_set_size(p_new_size: float):
	sleeve.transform.origin = sleeve.transform.origin * p_new_size
	var new_scale: Vector3 = Vector3(0.2, 0.2, 0.2)
	
#	var new_transform = Transform(
#		Basis(
#			sleeve.transform.basis.x,
#			sleeve.transform.basis.y,
#			sleeve.transform.basis.z
#		),
#		sleeve.transform.origin
#	)
	#new_transform.basis.scaled(new_scale)
	
	sleeve.transform.basis.scaled(new_scale)
#	sleeve.transform.basis.x /= new_scale
#	sleeve.transform.basis.y /= new_scale
#	sleeve.transform.basis.z /= new_scale

func _deferred_set_start(p_position: Vector3):
	if is_post_ready:
		path.curve.set_point_position(0, p_position)
		print("noodle start (orange): %s" % global_transform.origin)
		Cavedig.needle(
			self,
			Transform3D(self.transform.basis, path.curve.get_point_position(0)),
			Cavedig.Colors.ORANGE
		)

func _deferred_set_end(p_position: Vector3):	
	if is_post_ready:
		path.curve.set_point_position(get_end_idx(), p_position)
	print("noodle end (aqua): %s" % global_transform.origin)
	Cavedig.needle(
		self,
		Transform3D(self.transform.basis, path.curve.get_point_position(get_end_idx())),
		Cavedig.Colors.AQUA
	)

###
### Builder methods (return self)
###

func add_as_child_to(p_node: Node3D) -> VisualizationNoodle:
	p_node.call_deferred("add_child", self)
	
	# Since the noodles form a connection between two visualizers which aren't
	# necessarily hierarchically related, tying the noodle's transformation
	# to one of them would unnecessarily complicate things.
	self.set_as_top_level(true)
	
	return self

# Start point of the noodle.
func set_start(p_position: Vector3) -> VisualizationNoodle:
	call_deferred("_deferred_set_start", p_position)
	return self

# End point of the noodle.
func set_end(p_position: Vector3) -> VisualizationNoodle:
	call_deferred("_deferred_set_end", p_position)
	return self
