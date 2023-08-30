extends RefCounted
class_name CityGeoFuncs


static func create_kinked_roof_line(
	start: Vector3,
	end: Vector3,
	kinks: int,
	inset_ratio := 1.0,
	height_ratio := 1.0,
	mid_stretch_ratio := 1.0 # TODO
) -> PackedVector3Array:
	var line := PackedVector3Array()
	assert(start.x == end.x)
	var x := start.x
	
	var depth := end.z
	var kink_depth := depth / (kinks + 1)
	var height := end.y
	var kink_height := height / (kinks + 1)
	
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
