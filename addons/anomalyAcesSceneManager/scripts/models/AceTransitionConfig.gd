@tool
class_name AceTransitionConfig extends Resource

## Resource model representing a transition animation configuration (start anim, end anim, and loading screen path).

@export var start: String = ""
@export var end: String = ""
@export_file("*.tscn") var loading_screen_path: String = ""


# ==============================================================================
# CONSTANTS
# ==============================================================================

const START: String = "start"
const END: String = "end"
const LOADING_SCREEN_PATH: String = "loading_screen_path"


# ==============================================================================
# CONSTRUCTOR
# ==============================================================================

func _init(p_start: String = "", p_end: String = "", p_loading_screen_path: String = "") -> void:
	start = p_start
	end = p_end
	loading_screen_path = p_loading_screen_path


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func is_valid() -> bool:
	return not start.is_empty() and not end.is_empty()
