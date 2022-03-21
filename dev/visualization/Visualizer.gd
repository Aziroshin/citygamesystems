extends Spatial
class_name Visualizer

const VisualizationShader = preload("res://dev/visualization/VisualizationShader.tres")
var Self = load(filename)

var primary: MeshDelegate
var secondary: MeshDelegate
var tertiary: MeshDelegate
var quaternary: MeshDelegate
var description: String
	
func _init():
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

func add_as_child(parent: Node) -> Visualizer:
	parent.add_child(self)
	return self

func set_position(position: Vector3) -> Visualizer:
	self.translate(position)
	return self

func set_size(size: float) -> Visualizer:
	self.scale = Vector3(size, size, size)
	return self

func resize(size_coefficient: float) -> Visualizer:
	self.scale *= size_coefficient
	return self

func align_along(vector: Vector3) -> Visualizer:
	# Solution inspired by r/Sprowl: https://www.reddit.com/r/godot/comments/f2fowu/aligning_node_to_surface_normal/
	self.global_transform.basis = Basis(
		vector.cross(self.global_transform.basis.z),
		vector,
		self.global_transform.basis.x.cross(vector)
	)
	return self

# This can be called at the end of an `assert()` enclosed builder pattern
# call in order to disarm the assert in case it's used to make the visualizer
# only appear in debug builds.
func return_true() -> bool:
	return true
