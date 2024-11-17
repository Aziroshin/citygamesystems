## Provides mouse info in the 3D space.
##
## Addon dependencies:
##   - mouse_3d_ray
extends Node
class_name Mouse3D

@export var mouse_3d_ray: Mouse3DRay
signal mouse_motion(
	p_camera: Camera3D,
	p_event: InputEventMouseMotion,
	p_position: Vector3,
	p_normal: Vector3,
	p_shape: int
)
signal mouse_position_change(
	p_camera: Camera3D,
	p_event: InputEventMouseMotion,
	p_position: Vector3,
	p_normal: Vector3,
	p_shape: int
)
signal mouse_button(
	p_camera,
	p_event,
	p_mouse_position,
	p_normal,
	p_shape
)
## In cases where it's important to know whether we've gotten a mouse position
## already.
var knows_position := false
var last_mouse_position := Vector3()
var last_mouse_button_event := InputEventMouseButton.new()
var last_mouse_button_event_processed := false
var last_mouse_motion_event := InputEventMouseMotion.new()
var last_mouse_motion_event_processed := false


func _ready():
	mouse_3d_ray.ray_caster.updated.connect(_on_ray_caster_updated)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		last_mouse_motion_event = event
		last_mouse_motion_event_processed = false
	if event is InputEventMouseButton:
		last_mouse_button_event = event
		last_mouse_button_event_processed = false


func _on_ray_caster_updated():
	if mouse_3d_ray.collisions.exist():
		var first_collision = mouse_3d_ray.collisions.all[0]
		var mouse_position = first_collision[Mouse3DRay.Collisions.Keys.POSITION]
		var normal = first_collision[Mouse3DRay.Collisions.Keys.NORMAL]
		var shape = first_collision[Mouse3DRay.Collisions.Keys.SHAPE]
		
		if not last_mouse_motion_event_processed:
			mouse_motion.emit(
				mouse_3d_ray.camera,
				last_mouse_motion_event,
				mouse_position,
				normal,
				shape
			)
			last_mouse_motion_event_processed = true
			
			if not mouse_position == last_mouse_position:
				mouse_position_change.emit(
					mouse_3d_ray.camera,
					last_mouse_motion_event,
					mouse_position,
					normal,
					shape
				)
				last_mouse_position = mouse_position
		
		if not last_mouse_button_event_processed:
			if last_mouse_button_event.button_index > 0:
				mouse_button.emit(
					mouse_3d_ray.camera,
					last_mouse_button_event,
					mouse_position,
					normal,
					shape
				)
			last_mouse_button_event_processed = true
