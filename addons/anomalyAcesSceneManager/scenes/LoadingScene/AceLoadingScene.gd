@tool
class_name AceLoadingScene extends CanvasLayer

## Base class for loading screen scenes in Ace Scene Manager.
## Extend this class to implement custom transition animations and progress indicators.

signal loading_screen_ready
signal loading_screen_finished

@export var animation_player: AnimationPlayer

## Configurable dictionary mapping Transition Type names to AceTransitionType objects or dictionaries.
@export var transition_types: Dictionary[String, AceTransitionType] = {}


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

## Called by AceSceneManager to begin the transition-in animation.
## [param transition]: The transition name (String) or transition configuration Dictionary.
func play_transition(transition: Variant) -> void:
	# Virtual method - override in derived loading scenes.
	loading_screen_ready.emit()


## Called by AceSceneManager when resource load is complete to begin transition-out animation.
func finish_transition() -> void:
	# Virtual method - override in derived loading scenes.
	loading_screen_finished.emit()
	queue_free()


## Helper method to retrieve AceTransitionType info for a given transition parameter.
func get_transition_type_info(transition: Variant) -> AceTransitionType:
	var config: AceTransitionConfig = _get_transition_config(transition)
	if config != null and config.type != null:
		return config.type

	# Fallback: check global settings if passed a string key
	if typeof(transition) == TYPE_STRING and AceSceneManager.settings != null:
		var type_name: String = transition as String
		var global_types: Dictionary = AceSceneManager.settings.get_setting("transition_types", {})
		if global_types.has(type_name):
			var raw_info: Variant = global_types[type_name]
			if raw_info is AceTransitionType:
				return raw_info as AceTransitionType
			elif typeof(raw_info) == TYPE_DICTIONARY:
				return AceTransitionType.from_dictionary(raw_info as Dictionary)

	return AceTransitionType.new()


## Helper method to resolve the root Control node for a given transition parameter.
func get_transition_node(transition: Variant) -> Control:
	var info: AceTransitionType = get_transition_type_info(transition)
	if info != null and not info.transition_root_node.is_empty():
		var node_path: NodePath = NodePath(info.transition_root_node)
		if has_node(node_path):
			return get_node_or_null(node_path) as Control

	# Fallback: Return first child Control node on this loading scene instance
	for child in get_children():
		if child is Control:
			return child as Control

	return null


## Helper method to resolve the progress bar node for a given transition parameter.
func get_progress_bar_node(transition: Variant) -> Control:
	var info: AceTransitionType = get_transition_type_info(transition)
	if info != null and info.has_progress_bar and not info.progress_bar_node.is_empty():
		var node_path: NodePath = NodePath(info.progress_bar_node)
		if has_node(node_path):
			return get_node_or_null(node_path) as Control

	# Fallback: Find any child ProgressBar in the active transition container or scene tree
	var active_container: Control = get_transition_node(transition)
	if active_container != null:
		var found_bar: Node = active_container.find_child("ProgressBar", true, false)
		if found_bar is Control:
			return found_bar as Control

	var scene_bar: Node = find_child("ProgressBar", true, false)
	if scene_bar is Control:
		return scene_bar as Control

	return null


# ==============================================================================
# PRIVATE / CALLBACK METHODS
# ==============================================================================

## Called by AceSceneManager when thread load progress updates.
## [param new_value]: Load progress from 0.0 to 1.0 (or 0 to 100).
func _on_progress_changed(new_value: float) -> void:
	# Virtual method - override in derived loading scenes.
	pass


## Helper method to resolve transition parameters into an AceTransitionConfig.
func _get_transition_config(transition: Variant) -> AceTransitionConfig:
	if transition is AceTransitionConfig:
		return transition as AceTransitionConfig
	elif typeof(transition) == TYPE_DICTIONARY:
		return AceTransitionConfig.from_dictionary(transition as Dictionary)
	elif typeof(transition) == TYPE_STRING and not (transition as String).is_empty():
		return AceTransitions.get_transition_config(transition as String)
	return AceTransitions.get_transition_config(AceTransitions.TRANSITION_FADE_BLACK)


## Helper method to resolve transition parameters into a Dictionary.
func _get_transition_dict(transition: Variant) -> Dictionary:
	return _get_transition_config(transition).to_dictionary()
