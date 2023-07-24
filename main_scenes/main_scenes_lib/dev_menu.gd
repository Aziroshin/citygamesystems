extends GridContainer

### GlobalDefaults.
const DEV_CONFIG_FILE_DEFAULT_PATH := GlobalDefaults.DEV_CONFIG_FILE_DEFAULT_PATH

### Config model.
const DEV_MENU_CONFIG_SECTION := DevMenuConfigModel.DEV_MENU_CONFIG_SECTION
const DEV_MENU_HIDDEN_CONFIG_KEY := DevMenuConfigModel.DEV_MENU_HIDDEN_CONFIG_KEY


# This is one section of a potentially larger config file where the DevMenu
# puts its config stuff.
@onready var config := ConfigSection.new(DEV_CONFIG_FILE_DEFAULT_PATH,
	DEV_MENU_CONFIG_SECTION)

@export var root_scene_node_path: NodePath
@export var toggle_action: StringName = ""


func set_to_shown():
	show()
	config.set_value(DEV_MENU_HIDDEN_CONFIG_KEY, false)
	
	
func set_to_hidden():
	hide()
	config.set_value(DEV_MENU_HIDDEN_CONFIG_KEY, true)


func _ready():
	if toggle_action == "":
		push_warning(
			"No DevMenu toggle action assigned. Showing DevMenu " +
			"regardless of config, just to be sure.")
		show()
		return
	
	if config.get_value(DEV_MENU_HIDDEN_CONFIG_KEY, false) == true:
		hide()
	else:
		show()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		if visible:
			set_to_hidden()
		else:
			set_to_shown()
