extends RefCounted
class_name MeshDebugLib


class ADebugOverlay extends Node3D:
	const ROTATION_90_DEG = 2 * PI / 4
	var default_font_size := 8
	var _show_vertices := true
	var _show_normals := true
	
	static func create_single_color_material(color: Color) -> StandardMaterial3D:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		return material
	
	func set_default_font_size(new_default_font_size: int) -> ADebugOverlay:
		default_font_size = new_default_font_size
		return self
		
	func show_vertices(flag: bool) -> ADebugOverlay:
		self._show_vertices = flag
		return self
	
	func show_normals(flag: bool) -> ADebugOverlay:
		self._show_normals = flag
		return self
	
	func add_label(
		title: String,
		xyz: Vector3,
		label_specific_font_size := -1
	) -> ADebugOverlay:
		var label := Label3D.new()
		label.translate(xyz)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.text = "%s: %s" % [title, xyz]
		label.fixed_size = true
		if label_specific_font_size >= 0:
			label.font_size = label_specific_font_size
		else:
			label.font_size = default_font_size
		
		add_child(label)
		return self
		
	func add_normal_indicator(
		vert_xyz: Vector3,
		normal_xyz: Vector3
	) -> ADebugOverlay:
		var shaft_color := Color(0.2, 0.2, 1.0)  # Blue
		var nock_color := Color(1.0, 0.2, 0.2)  # Red
		var tip_color := Color(0.3, 0.9, 1.0)  # Lighter, cyan-ish blue
		var shaft_length := 0.1
		var shaft_radius := shaft_length / 100.0
		var nock_size := shaft_length / 10.0
		var tip_length := nock_size * 2.0
		var tip_radius := shaft_radius * 2.0
		var superior_length := shaft_length * 0.9
		var inferior_length := shaft_length - superior_length
		
		var indicator := Node3D.new()
		var shaft := CSGCylinder3D.new()
		var nock := CSGBox3D.new()
		var tip := CSGCylinder3D.new()
		indicator.add_child(shaft)
		indicator.add_child(nock)
		indicator.add_child(tip)
		
		# Shapes
		shaft.height = shaft_length
		shaft.radius = shaft_radius
		nock.size = Vector3(nock_size, nock_size, nock_size)
		tip.height = tip_length
		tip.radius = tip_radius
		
		# Materials
		shaft.material_override = create_single_color_material(shaft_color)
		nock.material_override = create_single_color_material(nock_color)
		tip.material_override = create_single_color_material(tip_color)
		
		# Positions
		shaft.rotate_x(self.ROTATION_90_DEG)
		tip.rotate_x(self.ROTATION_90_DEG)
		nock.rotate_x(self.ROTATION_90_DEG)
		shaft.translate(Vector3(0.0, (shaft_length / 2.0) - inferior_length, 0.0))
		nock.translate(Vector3(0.0, -(inferior_length + nock_size / 2.0), 0.0))
		tip.translate(Vector3(0.0, superior_length + tip_length / 2.0, 0.0))
		
		# Indicator position and normal-aligned rotation.
		indicator.translate(vert_xyz)
		var old_basis := indicator.transform.basis
		var basis_z := normal_xyz.normalized()
		var basis_x := old_basis.z.cross(basis_z).normalized()
		var basis_y := basis_z.cross(basis_x).normalized()
		indicator.transform.basis = Basis(
			basis_x,
			basis_y,
			basis_z,
		)
		
		add_child(indicator)
		return self
		
	func visualize_arrays(arrays: Array) -> ADebugOverlay:
		var has_normals := true if arrays[ArrayMesh.ARRAY_NORMAL] else false
		
		var idx := 0
		for vert_xyz in arrays[ArrayMesh.ARRAY_VERTEX]:
			if self._show_vertices:
				add_label("%s" % idx, vert_xyz)
			
			if self._show_normals and has_normals:
				var normal_xyz: Vector3 = arrays[ArrayMesh.ARRAY_NORMAL][idx]
				add_normal_indicator(vert_xyz, normal_xyz)
				
			idx += 1
		return self
		
	func visualize_array_vertex(
		array_vertex: PackedVector3Array
	) -> ADebugOverlay:
		var surface_arrays := []
		surface_arrays.resize(ArrayMesh.ARRAY_MAX)
		surface_arrays[ArrayMesh.ARRAY_VERTEX] = array_vertex
		visualize_arrays(surface_arrays)
		return self
