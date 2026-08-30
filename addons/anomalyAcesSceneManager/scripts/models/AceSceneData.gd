@tool
class_name AceSceneData extends Resource

## Contains data to be transferred from one scene to another during transitions.

@export var data: Dictionary = {}


# ==============================================================================
# ENGINE / CONSTRUCTOR METHODS
# ==============================================================================

func _init(initial_data: Dictionary = {}) -> void:
	data = initial_data.duplicate()


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func set_value(key: String, value: Variant) -> void:
	data[key] = value


func get_value(key: String, default: Variant = null) -> Variant:
	return data.get(key, default)


func has_value(key: String) -> bool:
	return data.has(key)


func clear() -> void:
	data.clear()
