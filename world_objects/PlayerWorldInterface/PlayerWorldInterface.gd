extends CharacterBody3D

###########################################################################
# Config
###########################################################################
# Action names for movement
const MOVE_LEFT_ACTION := "camera_left"
const MOVE_RIGHT_ACTION := "camera_right"
const MOVE_FORWARD_ACTION := "camera_forward"
const MOVE_BACKWARD_ACTION := "camera_backward"
const MOVE_UP_ACTION := "camera_up"
const MOVE_DOWN_ACTION := "camera_down"

@export var default_speed := 128.0
@export var overwrite_existing_actions := false
@export var double_tap_interval := 0.2
@export var initial_motion_mode: MotionMode = MOTION_MODE_FLOATING
###########################################################################

@onready var camera: Camera3D = $SpringArm/Camera

# If more than a key is needed, refactor the value to be an object instead.
const action_default_keys := {
	MOVE_LEFT_ACTION: KEY_A,
	MOVE_RIGHT_ACTION: KEY_D,
	MOVE_FORWARD_ACTION: KEY_W,
	MOVE_BACKWARD_ACTION: KEY_S,
	MOVE_UP_ACTION: KEY_SPACE,
	MOVE_DOWN_ACTION: KEY_SHIFT,
}

var delta_without_up_action := 0.0

func set_action_key(action: String, keycode: int):
	var key_event_for_action := InputEventKey.new()
	key_event_for_action.keycode = keycode
	InputMap.action_add_event(action, key_event_for_action)

func ensure_action_configured(action: String) -> void:
	if not InputMap.has_action(action):
		push_error("Action not found: %s." % action)
		InputMap.add_action(action)
	if overwrite_existing_actions:
		set_action_key(action, action_default_keys[action])
		
func ensure_actions_configured()-> void:
	for action in action_default_keys.keys():
		ensure_action_configured(action)
		
func force_from_forces(forces: Array[Vector3]) -> Vector3:
	assert(len(forces) > 0, "`forces` can't be empty.")
	
	if len(forces) == 1:
		return forces[0]
	
	var force: Vector3
	var i = 0
	while i < len(forces) - 1:
		print("i: %s, len: %s" % [i, len(forces)])
		force = forces[i] + forces[i + 1]
		i = i + 1
	return force
	
func _ready():
	ensure_actions_configured()
	motion_mode = initial_motion_mode

func _physics_process(delta: float) -> void:
	var forces: Array[Vector3]
	
	if Input.is_action_pressed(MOVE_LEFT_ACTION):
		forces.append(transform.basis.x)
	if Input.is_action_pressed(MOVE_RIGHT_ACTION):
		forces.append(-transform.basis.x)
	if Input.is_action_pressed(MOVE_FORWARD_ACTION):
		forces.append(transform.basis.z)
	if Input.is_action_pressed(MOVE_BACKWARD_ACTION):
		forces.append(-transform.basis.z)
		
	# Move upward when holding the up-action and start falling
	# when double-tapping the up-action. This will probably break
	# or at least get really awkward with non-button-ish controls.
	if Input.is_action_pressed(MOVE_UP_ACTION):
		if Input.is_action_just_pressed(MOVE_UP_ACTION):
			print(delta_without_up_action)
			if delta_without_up_action <= double_tap_interval:
				motion_mode = MOTION_MODE_GROUNDED
			else:
				motion_mode = MOTION_MODE_FLOATING
			delta_without_up_action = 0.0
		else:
			forces.append(transform.basis.y)
		
	if Input.is_action_pressed(MOVE_DOWN_ACTION):
		forces.append(-transform.basis.y)
	
	# If we're flying, add a gravity force.
	if not is_on_floor() and not motion_mode == MOTION_MODE_FLOATING:
		forces.append(Vector3(0, -1, 0))
	
	if len(forces) > 0:
		velocity = force_from_forces(forces).normalized() * default_speed * delta
		move_and_slide()
		
	# Wrapping up.
	delta_without_up_action = delta_without_up_action + delta

func _input(event: InputEvent) -> void:
	pass
	
# Notes (TODO [production-cleanup])
# camera.project_ray_origin(get_viewport().get_mouse_position())
