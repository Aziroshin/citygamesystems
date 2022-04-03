extends Spatial
class_name Visualizer

const VisualizationNoodleScene = preload("res://dev/visualization/VisualizationNoodle/VisualizationNoodle.tscn")
const VisualizationShader = preload("res://dev/visualization/VisualizationShader.tres")
var Self = load(filename)

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
	
func set_description(description: String) -> Visualizer:
	self.description = description
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
	
	knockoff.transform = self.transform
	
	return knockoff

class NoodleConnections extends Reference:
	var visualizer: Visualizer
	var connections: Dictionary = {}
	
	func _init(our_visualizer: Visualizer):
		self.visualizer = our_visualizer
	
	func add_connection(connection: NoodleConnection):
		self.connections[connection.other_visualizer] = connection
		
	func remove_connection(other_visualizer: Visualizer):
		self.connections.erase(other_visualizer)
		
	func get_connection(other_visualizer: Visualizer) -> NoodleConnection:
		return self.connections[other_visualizer]
		
	# Return schema: `{other_visualizer: NoodleConnection}`.
	func get_all_connections() -> Dictionary:
		return self.connections

class NoodleConnection extends Reference:
	var visualizer: Visualizer
	var other_visualizer: Visualizer
	var noodle: VisualizationNoodle
	var direction: int
	
	enum Direction {
		NONE
		FROM
		TO
	}

	const OppositeDirectionOf: Dictionary = {
		Direction.NONE: Direction.NONE,
		Direction.TO: Direction.FROM,
		Direction.FROM: Direction.TO
	}
	
	func _init(
		our_visualizer: Visualizer,
		connected_visualizer: Visualizer,
		connecting_noodle: VisualizationNoodle,
		noodle_direction: int
	):
		self.visualizer = our_visualizer
		self.other_visualizer = connected_visualizer
		self.noodle = connecting_noodle
		self.direction = noodle_direction
	
class MeshDelegate extends Reference:
	var visualizer: Visualizer
	var mesh_name: String
	var has_mesh := false
	var mesh: MeshInstance
	var _material: ShaderMaterial
	var _material_is_unique := false
	
	func _init(visualizer: Visualizer, mesh_name: String):
		self.visualizer = visualizer
		self.mesh_name = mesh_name
		if self.visualizer.has_node(self.mesh_name):
			self._set_mesh(visualizer.get_node(self.mesh_name))
	
	# Sets our mesh.
	# Even though this is a `_` method, this may still be called from
	# other places within the Visualizer lib.
	func _set_mesh(new_mesh: MeshInstance) -> MeshDelegate:
		self.mesh = new_mesh
		self.has_mesh = true
		self._set_material(VisualizationShader)
		return self
	
	func _set_material(material: ShaderMaterial) -> void:
		self._material = material
		if self.has_mesh:
			self.mesh.material_override = self._material
		else:
			# More sophisticated error handling would be a good idea.
			push_error("VisualizerError: Tried to set material when we don't even have a mesh.")
	
	func _make_material_unique() -> void:
		self._set_material(self._material.duplicate())
	
	# Copy on Write, but for our material. ;)
	func _get_material_for_mutation() -> ShaderMaterial:
		if not _material_is_unique:
			self._make_material_unique()
		return self._material
	
	# Sets the color of our mesh.
	# Returns our visualizer, as this is a top level builder pattern
	# method.
	func set_color(color: Vector3) -> Visualizer:
		if self.has_mesh:
			self._get_material_for_mutation().set_shader_param("color", color)
			return self.visualizer
		return self.visualizer
	
	# Returns `Vector3(0, 0, 0)` if there is no mesh.
	func get_color() -> Vector3:
		if self.has_mesh:
			return self._material.get_shader_param("color")
		return Vector3(0, 0, 0)
	
	func new_knockoff(new_visualizer) -> MeshDelegate:
		# Light convention: Not relying on `_` prefixed functions and vars here
		# is strongly advised, even when it comes at a cost.
		
		var knockoff := MeshDelegate.new(new_visualizer, self.mesh_name)
		
		# The color is already on it by virtue of the duplicated mesh, but
		# not using the `set_color` function would create a strange situation
		# where `make_material_unique` isn't set, so we'd have to do that
		# separately, which would be... sticky, to say the least.
		# It's probably best to stick to non-`_` functions
		# in order to create a proper replica. This is especially important
		# when considering that future changes not aware of the idiosyncrasies
		# of this here function might introduce feral bugs if we're not careful
		# here.
		knockoff.set_color(self.get_color())
		
		return knockoff

func add_as_child_to(parent: Node) -> Visualizer:
	parent.add_child(self)
	return self

func set_position(position: Vector3) -> Visualizer:
	
#	# Correct
#	print("previous global marker position: %s" % global_transform.origin)
#	var needle_parent = get_tree().root
#	Cavedig.needle(get_tree().root, global_transform.origin, Cavedig.Colors.GREEN, 0.1, 0.2).set_as_toplevel(true)
	
	self.global_transform.origin = position
	
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

func set_size(size: float) -> Visualizer:
	# TODO: Resize noodles.
#	var previous_scale = self.scale
	self._size = size
	self.scale = Vector3(size, size, size)
#	for untyped_connection in self.connections.get_all_connections().values():
#		var connection: NoodleConnection = untyped_connection
#		connection.direction = NoodleConnection.Direction.FROM
#		connection.noodle.scale = connection.noodle.scale * (size)
	return self

#func resize(size_coefficient: float) -> Visualizer:
#	self.set_size(self.scale * size_coefficient)
#	return self

func align_along(vector: Vector3) -> Visualizer:
	# Solution inspired by r/Sprowl: https://www.reddit.com/r/godot/comments/f2fowu/aligning_node_to_surface_normal/
	self.global_transform.basis = Basis(
		vector.cross(self.global_transform.basis.z),
		vector,
		self.global_transform.basis.x.cross(vector)
	)
	return self

func noodle_to(other_visualizer: Visualizer) -> Visualizer:
	#Cavedig.needle(needle_parent, global_transform.origin, Cavedig.Colors.YELLOW, 0.1, 0.2).set_as_toplevel(true)
	print("source visualizer origin (yellow): %s" % global_transform.origin)
	noodle_up(other_visualizer, NoodleConnection.Direction.TO)
	return self

static func get_highest_spatial_in_hierarchy(spatial: Spatial) -> Spatial:
	var immediate_parent_spatial = spatial.get_parent_spatial()
	if immediate_parent_spatial:
		return get_highest_spatial_in_hierarchy(immediate_parent_spatial)
	return spatial
	
func get_highest_parent_spatial() -> GdTypes.NilableSpatial:
	var maybe_self = get_highest_spatial_in_hierarchy(self)
	if maybe_self.get_instance_id() == self.get_instance_id():
		return GdTypes.NilableSpatial.new()
	return GdTypes.NilableSpatial.new().set_value(maybe_self)
	
func noodle_up(other_visualizer: Visualizer, direction: int) -> Visualizer:
	var noodle: VisualizationNoodle = VisualizationNoodleScene.instance()\
		.add_as_child_to(get_tree().current_scene)\
		.set_size(self._size)\
		.set_start(global_transform.origin)
	connections.add_connection(NoodleConnection.new(
		self, 
		other_visualizer,
		noodle,
		direction
	))
	other_visualizer.get_noodled(self, noodle, NoodleConnection.OppositeDirectionOf[direction])
	return self
	
func get_noodled(noodling_visualizer: Visualizer, noodle: VisualizationNoodle, direction) -> Visualizer:
	noodle.set_end(global_transform.origin)
	connections.add_connection(NoodleConnection.new(
		self,
		noodling_visualizer,
		noodle,
		direction
	))
	Cavedig.needle(self, global_transform.origin, Cavedig.Colors.SEA_GREEN, 0.05, 0.3).set_as_toplevel(true)
	print("target visualizer origin (sea green): %s" % global_transform.origin)
	return self

# This can be called at the end of an `assert()` enclosed builder pattern
# call in order to disarm the assert in case it's used to make the visualizer
# only appear in debug builds.
func return_true() -> bool:
	return true
