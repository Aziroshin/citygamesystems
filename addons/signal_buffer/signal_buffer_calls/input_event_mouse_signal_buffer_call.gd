extends SignalBufferCall
class_name InputEventMouseSignalBufferCall

signal _input_event_mouse(
	p_camera: Camera3D,
	p_event: InputEvent,
	p_mouse_position: Vector3,
	p_normal: Vector3,
	p_shape: int
)

var _camera: Camera3D
var _event: InputEvent
var _mouse_position: Vector3
var _normal: Vector3
var _shape: int


func _init(
	p_camera: Camera3D,
	p_event: InputEvent,
	p_mouse_position: Vector3,
	p_normal: Vector3,
	p_shape: int
) -> void:
	_camera = p_camera
	_event = p_event
	_mouse_position = p_mouse_position
	_normal = p_normal
	_shape = p_shape


func flush() -> void:
	_input_event_mouse.connect(signal_receiver_method, CONNECT_ONE_SHOT)
	_input_event_mouse.emit(
		_camera,
		_event,
		_mouse_position,
		_normal,
		_shape
	)
