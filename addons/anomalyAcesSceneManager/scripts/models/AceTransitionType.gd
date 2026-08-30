@tool
class_name AceTransitionType extends Resource

## Model representing configuration details for a specific transition type layout in a loading screen.

@export var transition_root_node: String = ""
@export var has_progress_bar: bool = false
@export var progress_bar_node: String = ""


# ==============================================================================
# CONSTRUCTOR
# ==============================================================================

func _init(p_root: String = "", p_has_progress: bool = false, p_progress_node: String = "") -> void:
	transition_root_node = p_root
	has_progress_bar = p_has_progress
	progress_bar_node = p_progress_node


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func to_dictionary() -> Dictionary:
	return {
		"transition_root_node": transition_root_node,
		"has_progress_bar": has_progress_bar,
		"progress_bar_node": progress_bar_node
	}


static func from_dictionary(dict: Dictionary) -> AceTransitionType:
	if dict == null:
		return AceTransitionType.new()
	var root_path: String = String(dict.get("transition_root_node", ""))
	var has_pb: bool = dict.get("has_progress_bar", false)
	var pb_path: String = String(dict.get("progress_bar_node", ""))
	return AceTransitionType.new(root_path, has_pb, pb_path)
