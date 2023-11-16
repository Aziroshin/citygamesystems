@tool
extends StaticBody3D
class_name PlaneMap

var noise = preload("res://dev/PlaneMap/PlaneMapNoise.tres")
var material = preload("res://dev/PlaneMap/MapMaterial.tres")

@export var resolution := 10
@export var size := Vector2(10, 10)
@export var subdivision := Vector2(100, 100)

signal mouse_motion(
	camera: Camera3D,
	event: InputEventMouseMotion,
	click_position: Vector3,
	click_normal: Vector3,
	shape: int
)
signal mouse_button(
	camera: Camera3D,
	event: InputEventMouseButton,
	click_position: Vector3,
	click_normal: Vector3,
	shape: int
)

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
	array_mesh.clear_surfaces()
	mdt.commit_to_surface(array_mesh)
	
	st.create_from(array_mesh, 0)
	
	# For smoothing, this might be interesting:
	#   https://godotengine.org/qa/69339/regenerate-normals-after-meshdatatool-vertex-adjustments
	
	st.generate_normals()
	st.set_material(material)
	var mesh = st.commit()
	
	return mesh

func _ready():
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.set_mesh(create_mesh())
	
	# Making the map mouse-interactable.
	mesh_instance.create_trimesh_collision()
	var static_body: StaticBody3D = mesh_instance.get_node("_col")
	static_body.connect("input_event", _on_mouse_event)
	
	add_child(mesh_instance)
	
func _on_mouse_event(
	camera: Camera3D,
	event: InputEvent,
	mouse_position: Vector3,
	normal: Vector3,
	shape: int
):
	if event is InputEventMouseMotion:
		mouse_motion.emit(camera, event, mouse_position, normal, shape)
	if event is InputEventMouseButton:
		mouse_button.emit(camera, event, mouse_position, normal, shape)
	

