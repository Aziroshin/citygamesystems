extends Node3D

###########################################################################
# Config
###########################################################################
# Behaviour
@export var overwrite_existing_actions := false
# Action names for movement
const MOVE_LEFT_ACTION := "camera_left"
const MOVE_RIGHT_ACTION := "camera_right"
const MOVE_FORWARD_ACTION := "camera_up"
const MOVE_BACKWARD_ACTION := "camera_down"
###########################################################################

# If more than a key is needed, refactor the value to be an object instead.
const action_default_keys := {
	MOVE_LEFT_ACTION: KEY_A,
	MOVE_RIGHT_ACTION: KEY_D,
	MOVE_FORWARD_ACTION: KEY_W,
	MOVE_BACKWARD_ACTION: KEY_S
}

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

func _ready():
	ensure_actions_configured()

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed(MOVE_LEFT_ACTION):
		print("move left")
	if Input.is_action_pressed(MOVE_RIGHT_ACTION):
		print("move right")
	if Input.is_action_pressed(MOVE_FORWARD_ACTION):
		print("move forward")
	if Input.is_action_pressed(MOVE_BACKWARD_ACTION):
		print("move backward")

func _input(event: InputEvent) -> void:
	pass
