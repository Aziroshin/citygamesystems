tool
extends StaticBody

var noise = preload("res://dev/PlaneMap/PlaneMapNoise.tres")
var material = preload("res://dev/PlaneMap/MapMaterial.tres")

export var resolution = 10
export var size = Vector2(10, 10)
export var subdivision = Vector2(100, 100)

# With some helpful input from Digital KI's post:
#   https://digitalki.net/2018/04/25/alter-a-plane-mesh-programmatically-with-godot-3-0-2/
# If you ever find this: There's definitely a use for this. All it needs is some noise. ;):
func create_mesh() -> Mesh:
	var st = SurfaceTool.new()
	var mdt = MeshDataTool.new()
	
	var plane = PlaneMesh.new()
	plane.subdivide_width = subdivision.x
	plane.subdivide_depth = subdivision.y
	plane.size = size
	
	st.create_from(plane, 0)
	var array_mesh = st.commit()
	mdt.create_from_surface(array_mesh, 0)
	for i in mdt.get_vertex_count():
		var vertex = mdt.get_vertex(i)
		vertex.y = noise.get_noise_2d(vertex.x * resolution, vertex.z * resolution)
		mdt.set_vertex(i, vertex)
	
	if array_mesh.get_surface_count() > 1:
		push_error("Map plane array mesh unexpectedly has more than one surface.")
	array_mesh.surface_remove(0)
	mdt.commit_to_surface(array_mesh)
	
	st.create_from(array_mesh, 0)
	
	# For smoothing, this might be interesting:
	#   https://godotengine.org/qa/69339/regenerate-normals-after-meshdatatool-vertex-adjustments
	
	st.generate_normals()
	st.set_material(material)
	var mesh = st.commit()
	
	return mesh

func _ready():
	var mesh_instance := MeshInstance.new()
	mesh_instance.set_mesh(create_mesh())
	
	# Making the map mouse-interactable.
	mesh_instance.create_trimesh_collision()
	var static_body: StaticBody = mesh_instance.get_node("_col")
	static_body.connect("input_event", self, "_on_mouse_event")
	
	add_child(mesh_instance)
	
	assert(Visualization.OctagonMarker.instance()\
		.add_as_child_to(self)\
		.set_position(Vector3(2, 1, -2))\
		.set_size(0.5)\
		.primary.set_color(Vector3(0.2, 0.1, 0.6))\
		.secondary.set_color(Vector3(0.2, 0.1, 0.3))\
		.noodle_to(
			Visualization.OctagonMarker.instance()\
			.add_as_child_to(self)\
			.set_position(Vector3(3.5, 1, -2.5))\
			.set_size(0.5)\
			.primary.set_color(Vector3(0.6, 0.1, 0.4))\
			.secondary.set_color(Vector3(0.6, 0.1, 0.2))\
		)
	)
	
func _on_mouse_event(camera, event, click_position, click_normal, shape):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			assert(Visualization.OctagonMarker.instance()\
				.add_as_child_to(self)\
				.set_position(click_position)\
				.align_along(click_normal)\
				.set_size(0.2)\
				.primary.set_color(Vector3(0.2, 0.7, 0.2))\
				.secondary.set_color(Vector3(0.4, 1, 0.4))
			)
