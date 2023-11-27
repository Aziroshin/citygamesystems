extends VBoxContainer

### GlobalDefaults.
# Path to the directory with the scenes to pick.
const MAIN_SCENES_PATH = GlobalDefaults.MAIN_SCENES_PATH
const DEV_CONFIG_FILE_DEFAULT_PATH := GlobalDefaults.DEV_CONFIG_FILE_DEFAULT_PATH
const DEFAULT_SCENE_PATH: String = GlobalDefaults.DEFAULT_SCENE_PATH

#### Config model.
const SCENE_PICKER_CONFIG_SECTION := ScenePickerConfigModel.SCENE_PICKER_CONFIG_SECTION
const PICKED_SCENE_PATH_CONFIG_KEY := ScenePickerConfigModel.PICKED_SCENE_PATH_CONFIG_KEY

# This button will be instantiated for every scene in `MAIN_SCENES_PATH`.
const SetSceneButton: Resource = preload(
	"%smain_scenes_lib/set_scene_button.tscn" % MAIN_SCENES_PATH)
	
	
# TODO [bug]: ResourceLoader.exists returns true, even if the `resource_type`
#  is wrong. Because of that this function currently returns true even if the
#  type is wrong.
func resource_path_is_sane_with_warning(
	p_path: String,
	p_called_from_getter: bool, # If false, it's a setter.
	p_descriptive_term := "",
	p_resource_type: String = "",
) -> bool:
		var path_exists := ResourceLoader\
			.exists(p_path) == true
		var is_proper_type := ResourceLoader\
			.exists(p_path, p_resource_type) == true
		
		# Assertion for debugging the function.
		#assert(false, "path_exists: %s, is_proper_type: %s, type: %s, called_from_getter: %s, path: %s"\
		#	% [path_exists, is_proper_type, resource_type, str(called_from_getter), path])
		
		if p_called_from_getter:
			if not path_exists:
				push_warning("Default %s returned, " % p_descriptive_term
					+ "because stored scene path doesn't exist: '%s'." % p_path
				)
				return false
			if path_exists and not is_proper_type:
				push_warning("Default %s " % p_descriptive_term
					+ "returned, because stored %s exists " % p_descriptive_term
					+ "but isn't of type '%s': " % p_resource_type
					+ "'%s'." % p_path
				)
				return false
		else: # Called from setter.
			if not path_exists:
				push_warning("Storing non-existent %s " % p_descriptive_term
					+ ": '%s'." % p_path
				)
				return false
			if path_exists and not is_proper_type:
				push_warning("Storing % which isn't of the " % p_descriptive_term
					+ "specified type (%s): " % p_resource_type
					+ "'%s'." % p_path
				)
				return false
		
		return true
		
		
# The scene we want to attach picked scenes to.
@onready var root_scene: Node3D =\
	# Note: This default value is set with a `DevMenu` overlay parent node in
	# mind which has an exported property `root_scene_node_path`, which would be
	# set in whatever node setup that `DevMenu` is a part of. If this is used
	# outside of that setup, just put whatever value makes sense for your
	# situation.
	# Note: The `NodePath` referenced by `root_scene_node_path` is relative to
	# the `DevMenu` (The `DevMenu` is referenced as `..`, which we prepend
	# to the `root_scene_node_path` to get a full path to the root scene. If the
	# `DevMenu` was directly parented by the root scene node, the whole path
	# would look like this: `../..`).
	get_node(NodePath("../" + str($"..".root_scene_node_path)))

# The scene we've attached last to `root_scene`. Starts out with an instance
# of the scene at `DEFAULT_SCENE_PATH` and then gets initialized via a deferred
# call to the picked scene whose path is saved in the config, unless there's
# no picked scene path saved in the config, in which case it leaves the default
# scene in place until the clicking of a `SetSceneButton` sets a new scene.
@onready var current_scene: Node3D = load(DEFAULT_SCENE_PATH).instantiate()

# This is one section of a potentially larger config file where the scene picker
# puts its config stuff.
@onready var config := ConfigSection.new(DEV_CONFIG_FILE_DEFAULT_PATH,
	SCENE_PICKER_CONFIG_SECTION)

@onready var picked_scene_path: String:
	get:
		var stored_scene_path: String = config.get_value(
			PICKED_SCENE_PATH_CONFIG_KEY,
			DEFAULT_SCENE_PATH
		)
		
		if resource_path_is_sane_with_warning(
			stored_scene_path, true, "scene path", "PackedScene"
		):
			return stored_scene_path
		
		return DEFAULT_SCENE_PATH
	
	set(p_path):
		resource_path_is_sane_with_warning(
			p_path, false, "scene path", "PackedScene"
		)
		
		# If we'd store the default scene path in cases where the getter
		# returned the default because a non-existent path was found in storage,
		# we'd be overwriting that path, even though it could prove useful for
		# debugging.
		if not p_path == DEFAULT_SCENE_PATH:
			config.set_value(PICKED_SCENE_PATH_CONFIG_KEY, p_path)
		
# Edit this if you have scenes in your `MAIN_SCENES_PATH` you don't want to
# have buttons on the picker.
@onready var scene_blacklist: Array[String] = [
	# In case the "root" scene (the scene we're attached to) is in `MAIN_SCENES_PATH`.
	root_scene.scene_file_path,
	DEFAULT_SCENE_PATH
]


func _ready():
	var dir := DirAccess.open(MAIN_SCENES_PATH)
	
	call_deferred("set_scene_by_resource_path", picked_scene_path)
	
	dir.list_dir_begin()
	
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break
		
		var file_res_path = "%s%s" % [MAIN_SCENES_PATH, file_name]
		
		if file_name.get_extension() == "tscn" and not file_res_path in scene_blacklist:
			var new_button: HBoxContainer = SetSceneButton.instantiate()
			new_button.init(file_res_path, file_name.get_basename())
			new_button.scene_picked.connect(_on_set_scene_button_button_up)
			add_child(new_button)
	
	dir.list_dir_end()


func remove_and_delete_scene(p_scene: Node3D) -> void:
	root_scene.remove_child(p_scene)
	current_scene.queue_free()
	

func set_scene(p_scene: Node3D) -> void:
	remove_and_delete_scene(current_scene)
	root_scene.add_child(p_scene)
	current_scene = p_scene
	picked_scene_path = p_scene.scene_file_path
	

func set_scene_from_resource(p_scene: Resource) -> void:
	set_scene(p_scene.instantiate())


func set_scene_by_resource_path(p_path: String) -> void:
	set_scene_from_resource(load(p_path))


func set_scene_by_resource_name(p_res_name: String) -> void:
	set_scene_from_resource(load("%s%s.tscn" % [MAIN_SCENES_PATH, p_res_name]))


func _on_set_scene_button_button_up(p_scene_resource_path: String) -> void:
	set_scene_by_resource_path(p_scene_resource_path)
