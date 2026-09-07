@tool
class_name AceTransitionType extends Resource

## Resource model representing configuration details for a specific transition type layout in a loading screen.

@export var transition_root_node: NodePath
@export var has_progress_bar: bool = false
@export var progress_bar_node: NodePath


# ==============================================================================
# CONSTRUCTOR
# ==============================================================================

func _init(p_root: NodePath = NodePath(""), p_has_progress: bool = false, p_progress_node: NodePath = NodePath("")) -> void:
	transition_root_node = p_root
	has_progress_bar = p_has_progress
	progress_bar_node = p_progress_node


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func get_root_path_string() -> String:
	return String(transition_root_node)


func get_progress_path_string() -> String:
	return String(progress_bar_node)
