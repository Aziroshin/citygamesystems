extends Node

var curve := Curve3D.new()
var point_out_finalized: Array[bool] = []
var point_finalized: Array[bool] = []
signal curve_changed(curve: Curve3D)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_p_delta: float) -> void:
	pass


func emit_curve_changed() -> void:
	curve_changed.emit(curve.duplicate())


func get_last_idx_or_zero() -> int:
	if curve.point_count == 0:
		return 0
	return curve.point_count - 1


func get_second_last_or_zero() -> int:
	if curve.point_count <= 1:
		return 0
	return curve.point_count - 2


func mouse_position_to_curve_point_local(
	p_mouse_position: Vector3,
	p_idx: int
) -> Vector3:
	var local_position := p_mouse_position - curve.get_point_position(p_idx)
	return local_position


func _add_default_point(p_position: Vector3) -> void:
	curve.add_point(p_position, Vector3(0.1, 0.1, 0.1), -Vector3(0.1, 0.1, 0.1))
	point_finalized.append(false)
	point_out_finalized.append(false)
	emit_curve_changed()


func _add_point(
	p_position: Vector3,
	in_position: Vector3,
	out_position: Vector3
) -> void:
	curve.add_point(p_position, in_position, out_position)
	point_finalized.append(false)
	point_out_finalized.append(false)


func _on_map_mouse_button(
	_p_camera: Camera3D,
	p_event: InputEventMouseButton,
	_p_click_position: Vector3,
	_p_click_normal: Vector3,
	_p_shape: int
) -> void:
	if p_event.button_index == MOUSE_BUTTON_LEFT and p_event.pressed:
		if curve.point_count == 1:
			point_finalized[0] = true
		elif point_out_finalized[get_second_last_or_zero()]:
			point_finalized[get_last_idx_or_zero()] = true
		else:
			point_out_finalized[get_second_last_or_zero()] = true


func _on_map_mouse_motion(
	_p_camera: Camera3D,
	_p_event: InputEventMouseMotion,
	p_position: Vector3,
	_p_normal: Vector3,
	_p_shape: int
) -> void:
	if curve.point_count == 0:
		_add_default_point(p_position)
	elif curve.point_count == 1 and point_finalized[0]:
		_add_point(p_position, Vector3(0.1, 0.1, 0.1), Vector3(0.1, 0.1, 0.1))
		Cavedig.needle($Map, Transform3D(Basis(), curve.get_point_position(0)),
			Vector3(0.3, 0.1, 0.8),  # Purple
			0.3, 0.1
		)
	else:
		if curve.point_count > 1 and not point_out_finalized[get_second_last_or_zero()]:
			curve.set_point_out(
				get_second_last_or_zero(),
				mouse_position_to_curve_point_local(p_position, get_second_last_or_zero())
			)
		
		if point_finalized[get_last_idx_or_zero()]:
			_add_point(p_position, Vector3(0.1, 0.1, 0.1), Vector3(0.1, 0.1, 0.1))
			Cavedig.needle($Map, Transform3D(Basis(), curve.get_point_position(get_last_idx_or_zero())),
				Vector3(0.3, 0.1, 0.8),  # Purple
				0.5, 0.1
			)
		if not curve.get_point_position(get_last_idx_or_zero()).is_equal_approx(p_position):
			curve.set_point_position(get_last_idx_or_zero(), p_position)
			emit_curve_changed()
		
