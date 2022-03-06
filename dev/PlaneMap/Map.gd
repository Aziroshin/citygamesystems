extends StaticBody

var noise = preload("res://dev/PlaneMap/PlaneMapNoise.tres")
var material = preload("res://dev/PlaneMap/MapMaterial.tres")

func _ready():
	var st = SurfaceTool.new()
	var mdt = MeshDataTool.new()
	var size = Vector2(100, 100)
	var scale = 0.02
	
	st.set_material(material)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

#	st.add_uv(Vector2(0, 0))
#	st.add_vertex(Vector3(0, 0, 0))
#	st.add_uv(Vector2(1, 0))
#	st.add_vertex(Vector3(100, 0, 0))
#	st.add_uv(Vector2(1, 1))
#	st.add_vertex(Vector3(100, 100, 0))
#	st.add_uv(Vector2(0, 1))
#	st.add_vertex(Vector3(0, 100, 0))
	
	for x in size.x:
		for y in size.y:
			#var height = noise.get_noise_2d(x, y)
			var height = 1
			st.add_uv(Vector2(x * scale, y * scale))
			st.add_vertex(Vector3(x * scale, height, y * scale))
		
	
	var mesh = st.commit()

	#st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
#	mdt.create_from_surface(mesh, 0)
#	mdt.commit_to_surface(mesh)
	
	#var sphere = create_sphere()
	# Create mesh surface from mesh array.
	# mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh) # No blendshapes or compression used.
	
	# Still invisible...
	#var sphere_st = SurfaceTool.new()
#	sphere_st.create_from(mesh, 0)
#	sphere_st.index()
#	sphere_st.generate_normals(false)
	#mesh = sphere_st.commit()
	
	var mesh_instance: MeshInstance = MeshInstance.new()
	mesh_instance.set_mesh(mesh)
	add_child(mesh_instance)

func _input_event(camera, event, click_position, click_normal, shape):
	pass
