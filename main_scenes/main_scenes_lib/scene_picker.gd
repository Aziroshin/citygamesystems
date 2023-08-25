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
	path: String,
	called_from_getter: bool, # If false, it's a setter.
	descriptive_term := "",
	resource_type: String = "",
) -> bool:
		var path_exists := ResourceLoader\
			.exists(path) == true
		var is_proper_type := ResourceLoader\
			.exists(path, resource_type) == true
		
		# Assertion for debugging the function.
		#assert(false, "path_exists: %s, is_proper_type: %s, type: %s, called_from_getter: %s, path: %s"\
		#	% [path_exists, is_proper_type, resource_type, str(called_from_getter), path])
		
		if called_from_getter:
			if not path_exists:
				push_warning("Default %s returned, " % descriptive_term
					+ "because stored scene path doesn't exist: '%s'." % path
				)
				return false
			if path_exists and not is_proper_type:
				push_warning("Default %s " % descriptive_term
					+ "returned, because stored %s exists " % descriptive_term
					+ "but isn't of type '%s': '%s'." % [resource_type, path]
				)
				return false
		else: # Called from setter.
			if not path_exists:
				push_warning("Storing non-existent %s " % descriptive_term
					+ ": '%s'." % path
				)
				return false
			if path_exists and not is_proper_type:
				push_warning("Storing % which isn't of the " % descriptive_term
					+ "specified type (%s): %s" % [resource_type, path]
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
	
	set(path):
		resource_path_is_sane_with_warning(
			path, false, "scene path", "PackedScene"
		)
		
		# If we'd store the default scene path in cases where the getter
		# returned the default because a non-existent path was found in storage,
		# we'd be overwriting that path, even though it could prove useful for
		# debugging.
		if not path == DEFAULT_SCENE_PATH:
			config.set_value(PICKED_SCENE_PATH_CONFIG_KEY, path)
		
		
# Edit this if you have scenes in your `MAIN_SCENES_PATH` you don't want to
# have buttons on the picker.
@onready var scene_blacklist: Array[String] = [
	# In case the "root" scene (the scene we're attached to) is in `MAIN_SCENES_PATH`.
	root_scene.scene_file_path,
	DEFAULT_SCENE_PATH
]


func _ready():
	var dir := DirAccess.open(MAIN_SCENES_PATH)
	var node: GridContainer = $".."
	
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


func remove_and_delete_scene(scene: Node3D) -> void:
	root_scene.remove_child(current_scene)
	current_scene.queue_free()
	

func set_scene(scene: Node3D) -> void:
	remove_and_delete_scene(current_scene)
	root_scene.add_child(scene)
	current_scene = scene
	picked_scene_path = scene.scene_file_path
	

func set_scene_from_resource(scene: Resource) -> void:
	set_scene(scene.instantiate())


func set_scene_by_resource_path(path: String) -> void:
	set_scene_from_resource(load(path))


func set_scene_by_resource_name(name: String) -> void:
	set_scene_from_resource(load("%s%s.tscn" % [MAIN_SCENES_PATH, name]))


func _on_set_scene_button_button_up(scene_resource_path: String) -> void:
	set_scene_by_resource_path(scene_resource_path)
