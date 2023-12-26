@tool
extends PlaneMap
class_name SphereMap

func create_mesh() -> Mesh:
	var st = SurfaceTool.new()
	var mdt = MeshDataTool.new()
	
	var sphere = SphereMesh.new()
	sphere.radius = 10.0
	sphere.height = 10.0
	sphere.radial_segments = 12
	sphere.rings = 12
	
	st.create_from(sphere, 0)
	var array_mesh = st.commit()
	mdt.create_from_surface(array_mesh, 0)
	#for i in mdt.get_vertex_count():
		#var vertex = mdt.get_vertex(i)
		#vertex.y = noise.get_noise_2d(vertex.x * resolution, vertex.z * resolution)
		#mdt.set_vertex(i, vertex)
	
	if array_mesh.get_surface_count() > 1:
		push_error("Map sphere array mesh unexpectedly has more than one surface.")
	array_mesh.clear_surfaces()
	mdt.commit_to_surface(array_mesh)
	
	st.create_from(array_mesh, 0)
	
	# For smoothing, this might be interesting:
	#   https://godotengine.org/qa/69339/regenerate-normals-after-meshdatatool-vertex-adjustments
	
	st.generate_normals()
	_set_up_material()
	st.set_material(material)
	var mesh = st.commit()
	
	return mesh
