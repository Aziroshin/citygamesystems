extends ToolLibToolPositioner
class_name ToolLibToolMapPositioner

@export var map_agent: ToolLibMapAgent


func _ready():
	super()
	if not map_agent:
		push_error("%s added to scene tree without `map_agent`." % get_path())
		assert(map_agent)
