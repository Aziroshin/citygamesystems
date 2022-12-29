extends CharacterBody3D

# Note: When copy-pasting this, don't forget to also get these files:
# For `NilableTransform3D`: `res://global_lib/nilable_types/nilable_transform3d.gd
# For `NilableInt`: `res://global_lib/nilable_types/nilable_int.gd`

# If you don't want these files but only the contents, you'll have to refactor
# them into class syntax (take everything except the first two lines, indent
# it all and write, for example, `class NilableInt:` (unindented) above it).

###########################################################################
# Config
###########################################################################
### Action names for movement.
const MOVE_LEFT_ACTION := "camera_left"
const MOVE_RIGHT_ACTION := "camera_right"
const MOVE_FORWARD_ACTION := "camera_forward"
const MOVE_BACKWARD_ACTION := "camera_backward"
const MOVE_UP_ACTION := "camera_up"
const MOVE_DOWN_ACTION := "camera_down"
const ROTATE_LEFT_ACTION := "camera_rotate_left"
const ROTATE_RIGHT_ACTION := "camera_rotate_right"
const PITCH_UP_ACTION := "camera_pitch_up"
const PITCH_DOWN_ACTION := "camera_pitch_down"

### Action names for editor-only functionality.
# This is a special action for quick in-editor testing, which should be
# distinct from normal "save and quit" type of actions in more complex
# applications, and is intended to be used by this camera, not other things.
const SAVE_AND_QUIT_EDITOR_ACTION := "dev_camera_save_and_quit"

### Exports
@export var default_speed := 128.0
@export var default_rotation_speed := 6.0
@export var default_pitch_speed := 2.0
@export var overwrite_existing_actions := false
@export var double_tap_interval := 0.2
@export var initial_motion_mode: MotionMode = MOTION_MODE_FLOATING
@export var config_file_path := ""
@export var config_section := ""
@export var enable_integration_warnings := true
@export var show_integration_errors := true

### Child nodes should get a handy variable here, which should then be used
### in the code instead of the path, to make node tree refactoring more
### straight forward.
@onready var camera: Camera3D = $SpringArm/Camera

### Default keys for actions.
### If more than a key is needed, refactor the value to be an object instead.
const action_default_keys := {
	MOVE_LEFT_ACTION: KEY_A,
	MOVE_RIGHT_ACTION: KEY_D,
	MOVE_FORWARD_ACTION: KEY_W,
	MOVE_BACKWARD_ACTION: KEY_S,
	MOVE_UP_ACTION: KEY_SPACE,
	MOVE_DOWN_ACTION: KEY_SHIFT,
	SAVE_AND_QUIT_EDITOR_ACTION: KEY_F4,
	ROTATE_LEFT_ACTION: KEY_Q,
	ROTATE_RIGHT_ACTION: KEY_E,
	PITCH_UP_ACTION: KEY_R,
	PITCH_DOWN_ACTION: KEY_F
}

### Config file anatomy.
const CONFIG_VALUE_NAME_TRANSFORM := "transform"
const CONFIG_VALUE_NAME_MOTION_MODE := "motion_mode"
###########################################################################


###########################################################################
# Non-config globals
###########################################################################
var delta_without_up_action := 0.0
###########################################################################


###########################################################################
# Misc
###########################################################################
# Get the resulting vector from adding up all vectors in the specified array.
func force_from_forces(forces: Array[Vector3]) -> Vector3:
	assert(len(forces) > 0, "`forces` can't be empty.")
	
	if len(forces) == 1:
		return forces[0]
	
	var force: Vector3
	var i = 0
	while i < len(forces) - 1:
		force = forces[i] + forces[i + 1]
		i = i + 1
	return force
###########################################################################


###########################################################################
# Actions
###########################################################################
# Set a key for an action.
# This alters `InputMap` at runtime and doesn't write to the project.
func set_action_key(action: String, keycode: int):
	var key_event_for_action := InputEventKey.new()
	key_event_for_action.keycode = keycode
	InputMap.action_add_event(action, key_event_for_action)
	
	
# Add (and overwrite if specified) an action as required to make sure it's
# reasonably set up as configured without having to set it up in the Input Map
# first.
# This alters `InputMap` at runtime and doesn't write to the project.
func ensure_action_configured(action: String, overwrite: bool = false) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		set_action_key(action, action_default_keys[action])
		if enable_integration_warnings:
			push_warning("Action not found: %s. Spoofing it with hotkey: %s."\
				% [action, InputMap.action_get_events(action)[0].as_text()])
	elif overwrite:
		set_action_key(action, action_default_keys[action])
		
		
# Add (and overwrite if specified) actions as required to provide reasonable
# controls as configured without having to set them up in the Input Map first.
# This alters `InputMap` at runtime and doesn't write to the project.
func ensure_actions_configured(overwrite: bool = false) -> void:
	for action in action_default_keys.keys():
		ensure_action_configured(action, overwrite)
###########################################################################


###########################################################################
# Config
###########################################################################
# Checks whether we have everything to access the config.
func check_config_access() -> bool:
	if config_file_path == "" or config_section == "":
		if show_integration_errors:
			push_error("No config file path and/or section configured for %s" % name)
		return false
	return true
	
	
# Saves config value and returns true or fails and returns false.
func save_config_value(section: String, key: String, value) -> bool:
	if check_config_access():
		var config := ConfigFile.new()
		config.load(config_file_path)
		config.set_value(section, key, value)
		config.save(config_file_path)
		return true
	return false
	
	
# Loads config and returns config value, or `null` if it fails.
func load_config_value(section: String, key: String) -> Variant:
	var config := ConfigFile.new()
	config.load(config_file_path)
	return config.get_value(config_section, key)
	
	
func save_transform() -> bool:
	return save_config_value(config_section, CONFIG_VALUE_NAME_TRANSFORM, transform)
	
	
func load_transform() -> NilableTransform3D:
	var value = load_config_value(config_section, CONFIG_VALUE_NAME_TRANSFORM)
	if value is Transform3D:
		return NilableTransform3D.new().set_value(value)
	else:
		return NilableTransform3D.new()
		
		
func save_motion_mode() -> bool:
	return save_config_value(config_section, CONFIG_VALUE_NAME_MOTION_MODE, motion_mode)
		
		
func load_motion_mode() -> NilableInt:
	var value = load_config_value(config_section, CONFIG_VALUE_NAME_MOTION_MODE)
	if typeof(value) == TYPE_INT:
		return NilableInt.new().set_value(value)
	return NilableInt.new()
###########################################################################


###########################################################################
# The Stuff
###########################################################################
func _ready():
	# Load transform
	var transform_data_from_config := load_transform()
	if not transform_data_from_config.is_nil:
		transform = transform_data_from_config.value
		
	# Load motion mode
	var motion_mode_data_from_config := load_motion_mode()
	if not motion_mode_data_from_config.is_nil:
		motion_mode = motion_mode_data_from_config.value
	else:
		motion_mode = initial_motion_mode
	
	ensure_actions_configured(overwrite_existing_actions)
	
	
func _physics_process(delta: float) -> void:
	var forces: Array[Vector3]
	
	#######################################################################
	# Input
	#######################################################################
	if Input.is_action_just_pressed(SAVE_AND_QUIT_EDITOR_ACTION):
		if OS.has_feature("editor"):
			save_transform()
			save_motion_mode()
			if not Engine.is_editor_hint():
				get_tree().quit()
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
		
	if Input.is_action_pressed(ROTATE_LEFT_ACTION):
		transform = transform.rotated(
			Vector3(0, 1, 0),
			default_rotation_speed * delta
		)
		
	if Input.is_action_pressed(ROTATE_RIGHT_ACTION):
		transform = transform.rotated(
			Vector3(0, 1, 0),
			default_rotation_speed * delta * -1
		)
		
	if Input.is_action_pressed(PITCH_UP_ACTION):
		camera.transform = camera.transform.rotated_local(
			Vector3(1, 0, 0),
			default_pitch_speed * delta
		)
		
	if Input.is_action_pressed(PITCH_DOWN_ACTION):
		camera.transform = camera.transform.rotated_local(
			Vector3(1, 0, 0),
			default_pitch_speed * delta * -1
		)
		
	#######################################################################
	
	# If we're flying without being in floating mode, add a gravity force.
	if not is_on_floor() and not motion_mode == MOTION_MODE_FLOATING:
		forces.append(Vector3(0, -1, 0))
	
	# Combine all forces and move.
	if len(forces) > 0:
		velocity = force_from_forces(forces).normalized() * default_speed * delta
		move_and_slide()
		
	delta_without_up_action = delta_without_up_action + delta
	
	
func _input(event: InputEvent) -> void:
	pass
###########################################################################
