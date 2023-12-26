@tool
extends StaticBody3D
class_name PlaneMap

const default_noise = preload("res://dev/PlaneMap/PlaneMapNoise.tres")
const default_material = preload("res://dev/PlaneMap/MapMaterial.tres")

@export var resolution := 10
@export var size := Vector2(10, 10)
@export var subdivision := Vector2(100, 100)
@export var alpha := 1.0
@export var noise := default_noise
@export var material := default_material

signal mouse_motion(
	p_camera: Camera3D,
	p_event: InputEventMouseMotion,
	p_click_position: Vector3,
	p_click_normal: Vector3,
	p_shape: int
)
signal mouse_button(
	p_camera: Camera3D,
	p_event: InputEventMouseButton,
	p_click_position: Vector3,
	p_click_normal: Vector3,
	p_shape: int
)


func _set_up_material() -> void:
	material.set_shader_parameter("alpha", alpha)


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
	_set_up_material()
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
	p_camera: Camera3D,
	p_event: InputEvent,
	p_mouse_position: Vector3,
	p_normal: Vector3,
	p_shape: int
):
	if p_event is InputEventMouseMotion:
		mouse_motion.emit(
			p_camera,
			p_event,
			p_mouse_position,
			p_normal,
			p_shape
		)
	if p_event is InputEventMouseButton:
		mouse_button.emit(
			p_camera,
			p_event,
			p_mouse_position,
			p_normal,
			p_shape
		)
	

