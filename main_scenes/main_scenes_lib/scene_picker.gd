extends VBoxContainer

### Defaults.
# Path to the directory with the scenes to pick.
const MAIN_SCENES_PATH = Defaults.MAIN_SCENES_PATH
const DEV_CONFIG_FILE_DEFAULT_PATH := Defaults.DEV_CONFIG_FILE_DEFAULT_PATH
const DEFAULT_SCENE_PATH: String = Defaults.DEFAULT_SCENE_PATH

#### Config model.
const SCENE_PICKER_CONFIG_SECTION := ScenePickerConfigModel.SCENE_PICKER_CONFIG_SECTION
const PICKED_SCENE_PATH_CONFIG_KEY := ScenePickerConfigModel.PICKED_SCENE_PATH_CONFIG_KEY

# This button will be instantiated for every scene in `MAIN_SCENES_PATH`.
const SetSceneButton: Resource = preload(
	"%smain_scenes_lib/set_scene_button.tscn" % MAIN_SCENES_PATH)


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
		return config.get_value(
			PICKED_SCENE_PATH_CONFIG_KEY,
			"%sDefault.tscn" % MAIN_SCENES_PATH)
	set(value):
		config.set_value(PICKED_SCENE_PATH_CONFIG_KEY, value)

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
			print(file_res_path)
			print(str(scene_blacklist))
			var new_button := SetSceneButton.instantiate()
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
	print("[DEBUG] scene should be showing now.")


func set_scene_by_resource_name(name: String) -> void:
	set_scene_from_resource(load("%s%s.tscn" % [MAIN_SCENES_PATH, name]))


func _on_set_scene_button_button_up(scene_resource_path: String) -> void:
	set_scene_by_resource_path(scene_resource_path)
