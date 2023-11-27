extends Node3D
class_name Visualizer

const VisualizationNoodleScene = preload("res://dev/visualization/VisualizationNoodle/VisualizationNoodle.tscn")
const VisualizationShader = preload("res://dev/visualization/VisualizationShader.tres")

# This used to be `load(filename)`. With godot 4.0, I'm not sure what to
# change this to at the moment. `load(scene_file_path)` might be wrong.
var Self = load(scene_file_path)

var primary: MeshDelegate
var secondary: MeshDelegate
var tertiary: MeshDelegate
var quaternary: MeshDelegate
var description: String
var connections: NoodleConnections
var _size: float = 1.0
	
func _init():
	connections = NoodleConnections.new(self)
	primary = MeshDelegate.new(self, "Primary")
	secondary =  MeshDelegate.new(self, "Secondary")
	tertiary = MeshDelegate.new(self, "Tertiary")
	quaternary = MeshDelegate.new(self, "Quaternary")
	
func set_description(p_description: String) -> Visualizer:
	description = p_description
	return self
	
func new_knockoff() -> Visualizer:
	var knockoff = Self.instance()
	
	# TODO: For some reason the script doesn't seem to exist at all on the
	# knockoff. This is simply a cheap workaround, but this is probably a sign
	# of a bigger issue (besides the adventurous architecture of the Visualizer,
	# of course. ^^").
	knockoff.set_script(load("res://dev/visualization/Visualizer.gd"))
	
	knockoff.primary = primary.new_knockoff(knockoff)
	knockoff.secondary = secondary.new_knockoff(knockoff)
	knockoff.tertiary = tertiary.new_knockoff(knockoff)
	knockoff.quaternary = quaternary.new_knockoff(knockoff)
	
	knockoff.transform = transform
	
	return knockoff

class NoodleConnections extends RefCounted:
	var visualizer: Visualizer
	var connections: Dictionary = {}
	
	func _init(p_our_visualizer: Visualizer):
		visualizer = p_our_visualizer
	
	func add_connection(p_connection: NoodleConnection):
		connections[p_connection.other_visualizer] = p_connection
		
	func remove_connection(p_other_visualizer: Visualizer):
		connections.erase(p_other_visualizer)
		
	func get_connection(p_other_visualizer: Visualizer) -> NoodleConnection:
		return connections[p_other_visualizer]
		
	# Return schema: `{other_visualizer: NoodleConnection}`.
	func get_all_connections() -> Dictionary:
		return connections

class NoodleConnection extends RefCounted:
	var visualizer: Visualizer
	var other_visualizer: Visualizer
	var noodle: VisualizationNoodle
	var direction: int
	
	enum Direction {
		NONE,
		FROM,
		TO,
	}

	const OppositeDirectionOf: Dictionary = {
		Direction.NONE: Direction.NONE,
		Direction.TO: Direction.FROM,
		Direction.FROM: Direction.TO
	}
	
	func _init(
		p_our_visualizer: Visualizer,
		p_connected_visualizer: Visualizer,
		p_connecting_noodle: VisualizationNoodle,
		p_noodle_direction: int
	):
		visualizer = p_our_visualizer
		other_visualizer = p_connected_visualizer
		noodle = p_connecting_noodle
		direction = p_noodle_direction
	
class MeshDelegate extends RefCounted:
	var visualizer: Visualizer
	var mesh_name: String
	var has_mesh := false
	var mesh: MeshInstance3D
	var _material: ShaderMaterial
	var _material_is_unique := false
	
	func _init(p_visualizer: Visualizer, p_mesh_name: String):
		visualizer = p_visualizer
		mesh_name = p_mesh_name
		if visualizer.has_node(mesh_name):
			_set_mesh(p_visualizer.get_node(mesh_name))
	
	# Sets our mesh.
	# Even though this is a `_` method, this may still be called from
	# other places within the Visualizer lib.
	func _set_mesh(p_new_mesh: MeshInstance3D) -> MeshDelegate:
		mesh = p_new_mesh
		has_mesh = true
		_set_material(VisualizationShader)
		return self
	
	func _set_material(p_material: ShaderMaterial) -> void:
		_material = p_material
		if has_mesh:
			mesh.material_override = _material
		else:
			# More sophisticated error handling would be a good idea.
			push_error("VisualizerError: Tried to set material when we don't even have a mesh.")
	
	func _make_material_unique() -> void:
		_set_material(_material.duplicate())
	
	# Copy on Write, but for our material. ;)
	func _get_material_for_mutation() -> ShaderMaterial:
		if not _material_is_unique:
			_make_material_unique()
		return _material
	
	# Sets the color of our mesh.
	# Returns our visualizer, as this is a top level builder pattern
	# method.
	func set_color(p_color: Vector3) -> Visualizer:
		if has_mesh:
			_get_material_for_mutation().set_shader_parameter("color", p_color)
			return visualizer
		return visualizer
	
	# Returns `Vector3(0, 0, 0)` if there is no mesh.
	func get_color() -> Vector3:
		if has_mesh:
			return _material.get_shader_param("color")
		return Vector3(0, 0, 0)
	
	func new_knockoff(p_new_visualizer) -> MeshDelegate:
		# Light convention: Not relying on `_` prefixed functions and vars here
		# is strongly advised, even when it comes at a cost.
		
		var knockoff := MeshDelegate.new(p_new_visualizer, mesh_name)
		
		# The color is already on it by virtue of the duplicated mesh, but
		# not using the `set_color` function would create a strange situation
		# where `make_material_unique` isn't set, so we'd have to do that
		# separately, which would be... sticky, to say the least.
		# It's probably best to stick to non-`_` functions
		# in order to create a proper replica. This is especially important
		# when considering that future changes not aware of the idiosyncrasies
		# of this here function might introduce feral bugs if we're not careful
		# here.
		knockoff.set_color(get_color())
		
		return knockoff

func add_as_child_to(p_parent: Node3D) -> Visualizer:
	p_parent.add_child(self)
	return self

func position_at(p_position: Vector3) -> Visualizer:
	
#	# Correct
#	print("previous global marker position: %s" % global_transform.origin)
#	var needle_parent = get_tree().root
#	Cavedig.needle(get_tree().root, global_transform.origin, Cavedig.Colors.GREEN, 0.1, 0.2).set_as_toplevel(true)
	
	global_transform.origin = p_position
	
#	var green_needle: CSGCylinder = Cavedig.needle(self, global_transform.origin, Vector3(0.2, 0.2, 0.2) + Cavedig.Colors.GREEN, 2, 0.05)
#	green_needle.set_as_toplevel(true)
#	#green_needle.global_transform.origin = self.global_transform.origin
#	print("marker global: %s" % green_needle.global_transform.origin)
#	print("marker local: %s" % green_needle.transform.origin)
#
#	# Correct
#	print("global marker position: %s" % global_transform.origin)
#	var global_marker_position: CSGCylinder = Cavedig.needle(needle_parent, global_transform.origin, Cavedig.Colors.BLUE, 0.2, 0.2)
#	global_marker_position.set_as_toplevel(true)
#	print("global marker position needle, local position: %s" % global_marker_position.transform.origin)
#
#	# Correct
#	print("local marker position: %s" % transform.origin)
#	Cavedig.needle(needle_parent, transform.origin, Vector3(0.2, 0.2, 0.2) + Cavedig.Colors.BLUE, 0.3, 0.05).set_as_toplevel(true)
#
#	# Correct
#	# Since this is a local position, the needle has to be relative to what
#	# the position it's marking is local to: `self`, the node the mesh belongs
#	# to.
#	print("local mesh position: %s" % self.primary.mesh.transform.origin)
#	Cavedig.needle(self, self.primary.mesh.transform.origin, Vector3(-0.2, -0.2, -0.2) + Cavedig.Colors.ORANGE, 6, 0.008).set_as_toplevel(true)
#
#	# Correct
#	print("global mesh position: %s" % self.primary.mesh.global_transform.origin)
#	Cavedig.needle(needle_parent, self.primary.mesh.global_transform.origin, Vector3(0.2, 0.2, 0.2) + Cavedig.Colors.AQUA, 5, 0.015).set_as_toplevel(true)
	
	return self

func set_size(p_size: float) -> Visualizer:
	# TODO: Resize noodles.
#	var previous_scale = self.scale
	_size = p_size
	scale = Vector3(p_size, p_size, p_size)
#	for untyped_connection in self.connections.get_all_connections().values():
#		var connection: NoodleConnection = untyped_connection
#		connection.direction = NoodleConnection.Direction.FROM
#		connection.noodle.scale = connection.noodle.scale * (size)
	return self

#func resize(size_coefficient: float) -> Visualizer:
#	self.set_size(self.scale * size_coefficient)
#	return self

func align_along(p_vector: Vector3) -> Visualizer:
	# Solution inspired by r/Sprowl: https://www.reddit.com/r/godot/comments/f2fowu/aligning_node_to_surface_normal/
	global_transform.basis = Basis(
		p_vector.cross(global_transform.basis.z),
		p_vector,
		global_transform.basis.x.cross(p_vector)
	)
	return self

func noodle_to(p_other_visualizer: Visualizer) -> Visualizer:
	#Cavedig.needle(needle_parent, global_transform.origin, Cavedig.Colors.YELLOW, 0.1, 0.2).set_as_toplevel(true)
	print("source visualizer origin (yellow): %s" % global_transform.origin)
	noodle_up(p_other_visualizer, NoodleConnection.Direction.TO)
	return self

static func get_highest_spatial_in_hierarchy(p_spatial: Node3D) -> Node3D:
	var immediate_parent_spatial = p_spatial.get_parent_spatial()
	if immediate_parent_spatial:
		return Visualizer.get_highest_spatial_in_hierarchy(immediate_parent_spatial)
	return p_spatial
	
func get_highest_parent_spatial() -> NilableNode3D:
	var maybe_self = Visualizer.get_highest_spatial_in_hierarchy(self)
	if maybe_self.get_instance_id() == self.get_instance_id():
		return NilableNode3D.new()
	return NilableNode3D.new().set_value(maybe_self)
	
func noodle_up(p_other_visualizer: Visualizer, p_direction: int) -> Visualizer:
	var noodle: VisualizationNoodle = VisualizationNoodleScene.instantiate()\
		.add_as_child_to(get_tree().current_scene)\
		.set_size(self._size)\
		.set_start(global_transform.origin)
	connections.add_connection(NoodleConnection.new(
		self, 
		p_other_visualizer,
		noodle,
		p_direction
	))
	p_other_visualizer.get_noodled(
		self,
		noodle,
		NoodleConnection.OppositeDirectionOf[p_direction]
	)
	return self
	
func get_noodled(
	p_noodling_visualizer: Visualizer,
	p_noodle: VisualizationNoodle,
	p_direction
) -> Visualizer:
	p_noodle.set_end(global_transform.origin)
	connections.add_connection(NoodleConnection.new(
		self,
		p_noodling_visualizer,
		p_noodle,
		p_direction
	))
	Cavedig.needle(self, global_transform, Cavedig.Colors.SEA_GREEN, 0.05, 0.3)\
		.set_as_top_level(true)
	print("target visualizer origin (sea green): %s" % global_transform.origin)
	return self

# This can be called at the end of an `assert()` enclosed builder pattern
# call in order to disarm the assert in case it's used to make the visualizer
# only appear in debug builds.
func return_true() -> bool:
	return true
