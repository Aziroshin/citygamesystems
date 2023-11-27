extends RefCounted
class_name CityGeoFuncs


static func create_kinked_roof_line(
	start: Vector3,
	end: Vector3,
	kinks: int,
	inset_ratio := 1.0,
	height_ratio := 1.0,
	_mid_stretch_ratio := 1.0 # TODO
) -> PackedVector3Array:
	var line := PackedVector3Array()
	assert(start.x == end.x)
	
	#var depth := end.z
	#var kink_depth := depth / (kinks + 1)
	#var height := end.y
	#var kink_height := height / (kinks + 1)
	
	var items := kinks + 2
	line.resize(items)
	
	for kink_idx in range(0, items):
		var angle: float = PI + ( (PI/2) - (PI/2) * ( float(kink_idx)/float(items) ) )
		line[kink_idx] = Vector3(
			0,
			sin(angle) * height_ratio,
			cos(angle) * inset_ratio
		) + Vector3(0, end.y, 0)
		
	line[0] = start
	line[items-1] = end
	return line


static func create_kinked_roof_line_local(
	start: Vector3,
	end: Vector3,
	kinks: int,
	inset_ratio := 1.0,
	height_ratio := 1.0,
	mid_stretch_ratio := 1.0 # TODO
) -> PackedVector3Array:
	return create_kinked_roof_line(
		Vector3(0, 0, 0),
		end - start,
		kinks,
		inset_ratio,
		height_ratio,
		mid_stretch_ratio
	)
	
	
static func shear_line(
	vertices: PackedVector3Array,
	shear_factor: float,
	axis_factors: Vector3
) -> PackedVector3Array:
	#var vertex_count := len(vertices)
	var sheared := PackedVector3Array()
	#sheared.resize(vertex_count)
	var start := vertices[0]
	var end := vertices[len(vertices)-1]
	var local_end := Vector3(
		end.x - start.x,
		end.y - start.y,
		end.z - start.z
	)
	
	for vertex in vertices:
		var ratio := 0.0
		if local_end.y != 0.0:
			ratio = vertex.y / local_end.y
		
		var displacement := Vector3(
			abs(ratio * shear_factor * axis_factors.x),
			abs(ratio * axis_factors.y),
			abs(ratio * shear_factor * axis_factors.z)
		)
		sheared.append(Vector3(
			vertex.x + displacement.x,
			vertex.y + displacement.y,
			vertex.z + displacement.z
		))
	return sheared
	
	
# If you type `surface_arrays` as `PackedVector3Array` but pass an
# `Array`, at first glance it works, as expected. However, the array is empty,
# its behaviour changed. That a type hint changes the internal workings of the
# object is quite surprising, but this might just be me approaching this from
# an "interface" perspective (like traits in Rust), misunderstanding Godot's
# type casting. In any case, the implicit nature of the type cast does leave the
# door open for quite some nasty bugs. Perhaps this is a bug in Godot?
static func get_array_mesh_node(surface_arrays: Array) -> MeshInstance3D:
	var array_mesh: ArrayMesh = ArrayMesh.new()
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	mesh_instance.mesh = array_mesh
	var material = load("res://dev/cavedig/cavedig_material.tres")
	mesh_instance.material_override = material
	return mesh_instance
	
	
static func get_multi_surface_array_mesh_node(
	surface_arrays_array: Array[Array],
	primitive := Mesh.PRIMITIVE_TRIANGLES
) -> MeshInstance3D:
	var array_mesh := ArrayMesh.new()
	var mesh_instance := MeshInstance3D.new()
	
	for surface_arrays in surface_arrays_array:
		array_mesh.add_surface_from_arrays(
			primitive,
			surface_arrays
		)
	mesh_instance.mesh = array_mesh
	
	return mesh_instance
	
	
static func get_array_mesh_node_from_vertices(
	array_vertex: PackedVector3Array
) -> MeshInstance3D:
	var surface_arrays := []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = array_vertex
	return get_array_mesh_node(surface_arrays)
	
	
static func get_grouped_surfaces_by_material_index(
	material_indices: PackedInt64Array,
	surface_arrays: Array,
	primitive_n := 3
) -> Array[Array]:
	var array_vertex: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_VERTEX]
	var array_tex_uv: PackedVector2Array = surface_arrays[ArrayMesh.ARRAY_TEX_UV]
	var array_normal: PackedVector3Array = surface_arrays[ArrayMesh.ARRAY_NORMAL]
	var grouped: Array[Array] = []
	
	### Initialize our array of surface arrays.
	var highest_material_index := 0
	for material_index in material_indices:
		highest_material_index = max(highest_material_index, material_index)
	grouped.resize(highest_material_index + 1)
	for i_material in range(highest_material_index + 1):
		var group_surface_arrays := []
		group_surface_arrays.resize(ArrayMesh.ARRAY_MAX)
		group_surface_arrays[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array()
		group_surface_arrays[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array()
		group_surface_arrays[ArrayMesh.ARRAY_NORMAL] = PackedVector3Array()
		grouped[i_material] = group_surface_arrays
	
	var i_face := 0
	for material_index in material_indices:
		var group_surface_arrays := grouped[material_index]
		var group_array_vertex: PackedVector3Array\
			= group_surface_arrays[ArrayMesh.ARRAY_VERTEX]
		var group_array_tex_uv: PackedVector2Array\
			= group_surface_arrays[ArrayMesh.ARRAY_TEX_UV]
		var group_array_normal: PackedVector3Array\
			= group_surface_arrays[ArrayMesh.ARRAY_NORMAL]
		
		group_array_vertex.append(array_vertex[primitive_n * i_face])
		group_array_vertex.append(array_vertex[primitive_n * i_face + 1])
		group_array_vertex.append(array_vertex[primitive_n * i_face + 2])
		
		group_array_tex_uv.append(array_tex_uv[primitive_n * i_face])
		group_array_tex_uv.append(array_tex_uv[primitive_n * i_face + 1])
		group_array_tex_uv.append(array_tex_uv[primitive_n * i_face + 2])
		
		group_array_normal.append(array_normal[primitive_n * i_face])
		group_array_normal.append(array_normal[primitive_n * i_face + 1])
		group_array_normal.append(array_normal[primitive_n * i_face + 2])
		
		group_surface_arrays[ArrayMesh.ARRAY_VERTEX] = group_array_vertex
		group_surface_arrays[ArrayMesh.ARRAY_TEX_UV] = group_array_tex_uv
		group_surface_arrays[ArrayMesh.ARRAY_NORMAL] = group_array_normal
		grouped[material_index] = group_surface_arrays
		
		i_face += 1
	
	return grouped
