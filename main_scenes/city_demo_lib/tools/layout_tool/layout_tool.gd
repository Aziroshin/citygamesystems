extends CityToolLib.CurveLayoutTool

## "Imports": CityToolLib
const CurveCursor := CityToolLib.CurveCursor
const CurveLayoutToolState := CityToolLib.CurveLayoutToolState

## Used to get the actual corresponding map points to our curve points.
signal request_map_points(source_points: PackedVector3Array)

enum LayoutToolMapRayCasterRequestTypeId {
	CURVE,
}
@export var map_agent: ToolLibMapAgent
@export var life_cyclers: CityGameWorldObjectLifeCyclers
## Used for the colliders the tool uses to detect the boundary and corners of
## the area it's working with. Not related to the colliders of the layout
## objects themselves.
@export var collision_radius := 1.0
@onready var cursor := CurveCursor.new(get_state().curve)
@onready var last_mouse_position := Vector3()
var corner_colliders: Array[IndexedAreaToolCollider] = []
var boundary_colliders: Array[IndexedAreaToolCollider] = []


var ray := RayCast3D.new()
func _ready() -> void:
	map_agent.get_map_node().add_child(ray)


func activate() -> void:
	super()
	map_agent.mouse_button.connect(_on_map_mouse_button)
	map_agent.mouse_position_change.connect(_on_map_mouse_position_change)


func deactivate() -> void:
	super()
	map_agent.mouse_button.disconnect(_on_map_mouse_button)
	map_agent.mouse_position_change.disconnect(_on_map_mouse_position_change)


func add_node(
	p_position: Vector3,
	p_finalized: bool,
) -> int:
	cursor.current_idx = super(p_position, p_finalized)
	return cursor.current_idx


func add_node_with_collider(
		p_position: Vector3,
		p_finalized: bool,
	) -> int:
		var idx := add_node(p_position, p_finalized)
		
		var node_shape := SphereShape3D.new()
		node_shape.radius = collision_radius
		var node_collider := IndexedAreaToolCollider.new(
			self,
			node_shape,
			idx
		)
		map_agent.get_map_node().add_child(node_collider)
		node_collider.transform.origin = p_position
		node_collider.input_ray_pickable = false
		node_collider.add_to_group(CityGameGlobals.NodeGroups.CGS_CORNER_COLLIDERS, true)
		node_collider.add_to_group(CityGameGlobals.NodeGroups.CGS_TOOL_COLLIDERS, true)
		corner_colliders.append(node_collider)
		
		if idx >= 3:
			var position_a := get_state().curve.get_point_position(idx - 3)
			var position_b := get_state().curve.get_point_position(idx - 2)
			
			var edge_shape := CylinderShape3D.new()
			edge_shape.radius = collision_radius
			edge_shape.height = (position_a - position_b).length()
			var boundary_collider := IndexedAreaToolCollider.new(
				self,
				edge_shape,
				idx - 3
			)
			map_agent.get_map_node().add_child(boundary_collider)
			
			var z_at := (position_b - position_a).normalized()
			var x_at := Vector3.UP.cross(z_at).normalized()
			var y_at := z_at.cross(x_at).normalized()
			var basis_at := Basis(x_at, z_at, y_at)
			boundary_collider.transform = Transform3D(
				basis_at,
				position_a.lerp(position_b, 0.5)
			)
			
			boundary_collider.input_ray_pickable = false
			boundary_collider.add_to_group(CityGameGlobals.NodeGroups.CGS_BOUNDARY_COLLIDERS, true)
			boundary_collider.add_to_group(CityGameGlobals.NodeGroups.CGS_TOOL_COLLIDERS, true)
			boundary_colliders.append(boundary_collider)
		
		return idx


func _on_map_mouse_button(
	_p_camera: Camera3D,
	p_event: InputEventMouseButton,
	p_mouse_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	var tool_position := map_agent.get_position(p_mouse_position)
	
	if tool_position == cursor.previous_position_ro:
		return
		
	if get_node_count() >= 3:
		var second_previous_position := get_state().curve.get_point_position(cursor.current_idx-2)
		var previous_to_second_previous := second_previous_position - cursor.previous_position_ro
		var previous_to_current :=  cursor.current_position_ro - cursor.previous_position_ro
		if previous_to_second_previous.normalized().dot(previous_to_current.normalized()) > 0.9:
			# TODO: Give proper (visual) feedback.
			print("[Layout Tool]: Angle too narrow.")
			return
		
	# TODO: This will need to be properly tied into actions, but also in
	# a way modular enough that it won't be a pain to integrate the tool into
	# other codebases.
	if p_event.button_index == MOUSE_BUTTON_LEFT and p_event.pressed:
		if get_node_count() == 0:
			add_node_with_collider(
				tool_position,
				UNFINALIZED
			)
		if get_node_count() >= 2:
			add_node_with_collider(
				tool_position,
				UNFINALIZED
			)
		
		Cavedig.needle(
			map_agent.get_map_node(),
			Transform3D(Basis(), get_state().curve.get_point_position(cursor.current_idx))
		)
		
		if get_node_count() >= 3\
		and map_agent.get_position(p_mouse_position) == get_state().curve.get_point_position(0):
			_on_request_build_layout()


func get_boundary_clipped_position(p_reference_position: Vector3) -> Vector3:
	var position := p_reference_position
	ray.transform.origin = cursor.previous_position_ro
	ray.target_position =  p_reference_position - cursor.previous_position_ro
	ray.collide_with_areas = true
	ray.force_update_transform()
	ray.force_raycast_update()
	
	# Reference, with suggestion from SIsilicon, including potential caveats
	# in the comments:
	# https://forum.godotengine.org/t/possible-to-detect-multiple-collisions-with-raycast2d/27326
	var colliding_objects: Array = []
	while ray.is_colliding():
		var collider := ray.get_collider()
		if [
		CityGameGlobals.NodeGroups.CGS_CORNER_COLLIDERS,
		CityGameGlobals.NodeGroups.CGS_TOOL_COLLIDERS
		].all(func(group): return collider.is_in_group(group))\
		or [
		CityGameGlobals.NodeGroups.CGS_BOUNDARY_COLLIDERS,
		CityGameGlobals.NodeGroups.CGS_TOOL_COLLIDERS
		].all(func(group): return collider.is_in_group(group)):
			position = ray.get_collision_point()
			break
		ray.add_exception(collider)
		colliding_objects.append(collider)
		ray.force_raycast_update()
	for colliding_object in colliding_objects:
		ray.remove_exception(colliding_object)
	return position


func _on_map_mouse_position_change(
	_p_camera: Camera3D,
	_p_event: InputEvent,
	p_mouse_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	var tool_position := map_agent.get_position(p_mouse_position)
	
	if get_node_count() == 1 and not p_mouse_position == cursor.current_position_ro:
		cursor.current_idx = add_node(p_mouse_position, FINALIZED)
	if get_node_count() >= 2:
		
		if tool_position == cursor.previous_position_ro:
			return
		
		var first_node_position := get_state().curve.get_point_position(0)
		if not tool_position == first_node_position:
			tool_position = get_boundary_clipped_position(p_mouse_position)
			
		set_node_position(cursor.current_idx, tool_position, UNFINALIZED)
		
		var current_node_in_point := cursor.previous_position_ro - cursor.current_position_ro
		var current_node_out_point := cursor.current_position_ro- cursor.previous_position_ro
		var previous_node_out_point := cursor.current_position_ro - cursor.previous_position_ro
		
		set_node_handle_in_point(
			cursor.current_idx,
			current_node_in_point,
			UNFINALIZED
		)
		set_node_handle_out_point(
			cursor.current_idx,
			current_node_out_point,
			UNFINALIZED
		)
		set_node_handle_out_point(
			cursor.previous_idx_ro,
			previous_node_out_point,
			UNFINALIZED
		)


# For quick & dirty debugging.
func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_C:
			# Perhaps using signals to communicate that a new layout has been
			# made, or a layout got edited might be an alternative to consider?
			# It would decouple the tool a little bit more, but also add
			# indirection in turn.
			_create_and_spawn_corner_only_layout_object()
			# TODO [bug]: This is also disabling the street tool when it's
			# active. However, the layout tool shouldn't be able to do that
			# when its its deactivation routine is triggered.
			deactivate()


func _create_and_spawn_corner_only_layout_object() -> LayoutWorldObject:
	var corner_points := PackedVector3Array()
	for i_point in get_state().curve.point_count:
		corner_points.append(get_state().curve.get_point_position(i_point))
	
	#TODO: Snap the centroid to the map on the y-axis.
	var centroid := GeoFoo.get_centroid(corner_points)
	GeoFoo.translate(corner_points, -centroid)
	var layout_object := life_cyclers.layout.create_from_corner_points(corner_points)
	
	map_agent.get_map_node().add_child(layout_object)
	layout_object.transform.origin = centroid
	return layout_object


func _on_request_build_layout() -> void:
	_do_and_finish()


#==========================================================================
# BEGIN: Reset functions
# They get called when the tool is getting reset to a blank
# state.
# The existence of these things here is a prototyping fragment, as
# ideally, they would be a part of the tool state.
#==========================================================================

func _reset_helper_nodes() -> void:
	for node3d_array in [
		corner_colliders,
		boundary_colliders
	]:
		for untyped_node3d in node3d_array:
			# For the lack of nested collection types in GDScript.
			var node: Node3D = untyped_node3d
			map_agent.get_map_node().remove_child(node)
			node.queue_free()
	corner_colliders = []
	boundary_colliders = []


## Initializes a blank state.
## Not the same as the `reset` signal on the state.
func _reset_state() -> void:
	set_state(CurveLayoutToolState.new())
	emit_curve_changed()


func _reset() -> void:
	_reset_helper_nodes()
	_reset_state()
	cursor = CurveCursor.new(get_state().curve)
	last_mouse_position = Vector3()
	corner_colliders = []
	boundary_colliders = []

# END: Reset functions
#==========================================================================

func _finish() -> void:
	deactivate()


func _do_and_finish() -> void:
	_create_and_spawn_corner_only_layout_object()
	_reset()
	_finish()



