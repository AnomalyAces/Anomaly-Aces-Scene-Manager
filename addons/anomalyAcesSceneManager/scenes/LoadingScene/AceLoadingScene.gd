@tool
@abstract
class_name AceLoadingScene extends CanvasLayer

## Base abstract class for loading screen scenes in Ace Scene Manager.
## Extend this class to implement custom transition animations and progress indicators.

signal loading_screen_ready
signal loading_screen_finished

@export var animation_player: AnimationPlayer:
	set(val):
		animation_player = val
		update_configuration_warnings()

## Configurable dictionary mapping Transition Type names to AceTransitionType objects.
@export var transition_types: Dictionary[String, AceTransitionType] = {}:
	set(val):
		transition_types = val
		update_configuration_warnings()


# ==============================================================================
# ENGINE VIRTUAL METHODS
# ==============================================================================

func _ready() -> void:
	if Engine.is_editor_hint():
		if not child_entered_tree.is_connected(_on_editor_child_changed):
			child_entered_tree.connect(_on_editor_child_changed)
		if not child_exiting_tree.is_connected(_on_editor_child_changed):
			child_exiting_tree.connect(_on_editor_child_changed)
		_subscribe_transition_type_signals()


func _on_editor_child_changed(_node: Node = null) -> void:
	_subscribe_transition_type_signals()
	update_configuration_warnings()


func _subscribe_transition_type_signals() -> void:
	for key in transition_types:
		var type_node: AceTransitionType = transition_types[key]
		if type_node != null and type_node.has_signal("changed"):
			if not type_node.changed.is_connected(update_configuration_warnings):
				type_node.changed.connect(update_configuration_warnings)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if animation_player == null:
		warnings.append("AnimationPlayer is not assigned on this AceLoadingScene.")

	if transition_types.is_empty():
		warnings.append("The 'transition_types' dictionary is empty. At least one transition type (e.g. 'Fade', 'Circle') must be configured.")
	else:
		for key in transition_types:
			var type_info: AceTransitionType = transition_types[key]
			if type_info == null:
				warnings.append("The transition_types dictionary entry for key '%s' has an empty/null AceTransitionType value." % key)
			else:
				if type_info.get_root_path_string().is_empty():
					warnings.append("The transition_types entry '%s' has an empty/unassigned 'transition_root_node' (NodePath)." % key)
				if type_info.has_progress_bar and type_info.get_progress_path_string().is_empty():
					warnings.append("The transition_types entry '%s' has 'has_progress_bar' enabled, but 'progress_bar_node' (NodePath) is empty/unassigned." % key)
				if type_info.has_shader and type_info.shader == null:
					warnings.append("The transition_types entry '%s' has 'has_shader' enabled, but 'shader' (Shader) is null/unassigned." % key)

	return warnings


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

## Called by AceSceneManager to begin the transition-in animation.
## [param transition]: The transition configuration AceTransitionConfig object.
@abstract func play_transition(transition: AceTransitionConfig) -> void


## Called by AceSceneManager when resource load is complete to begin transition-out animation.
@abstract func finish_transition() -> void


## Helper method to retrieve AceTransitionType info for a given transition parameter.
func get_transition_type_info(transition: AceTransitionConfig) -> AceTransitionType:
	var config: AceTransitionConfig = get_transition_config(transition)
	if config == null:
		return AceTransitionType.new()

	# 1. Match config against registered available transitions (project settings or demo settings)
	var search_name: String = ""
	if AceSceneManager.settings != null:
		var custom_trans: Dictionary = AceSceneManager.settings.get_setting("available_transitions", {})
		for k in custom_trans:
			var dict_cfg: AceTransitionConfig = AceTransitions.get_transition(String(k), AceSceneManager.settings)
			if dict_cfg == config or (dict_cfg != null and not dict_cfg.start.is_empty() and dict_cfg.start == config.start and dict_cfg.end == config.end):
				search_name = String(k)
				break

	if search_name.is_empty():
		for k in AceSceneManagerDemoSettings.demo_transitions:
			var demo_cfg: AceTransitionConfig = AceSceneManagerDemoSettings.demo_transitions[k]
			if demo_cfg == config or (demo_cfg != null and not demo_cfg.start.is_empty() and demo_cfg.start == config.start and demo_cfg.end == config.end):
				search_name = k
				break

	# 2. Fallback: Match by substring against transition_types keys (sorting by longest key first to prevent "Fade" matching inside "ShaderFade")
	if search_name.is_empty():
		var keys: Array = transition_types.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a).length() > String(b).length())
		for key in keys:
			var key_str: String = String(key)
			if not key_str.is_empty() and (key_str.to_lower() in config.start.to_lower() or key_str.to_lower() in config.end.to_lower()):
				search_name = key_str
				break

	# 3. Check loading scene's transition_types dictionary
	if not search_name.is_empty() and transition_types.has(search_name):
		var scene_type: AceTransitionType = transition_types[search_name]
		if scene_type != null:
			return scene_type

	# 4. Fallback to global settings
	if not search_name.is_empty() and AceSceneManager.settings != null:
		var global_types: Dictionary = AceSceneManager.settings.get_setting("transition_types", {})
		if global_types.has(search_name):
			var raw_val: Variant = global_types[search_name]
			if raw_val is AceTransitionType:
				return raw_val
			elif raw_val is String and not (raw_val as String).is_empty():
				var loaded_type: Resource = load(raw_val as String)
				if loaded_type is AceTransitionType:
					return loaded_type
		if AceSceneManagerDemoSettings.demo_transition_types.has(search_name):
			return AceSceneManagerDemoSettings.demo_transition_types[search_name]

	return AceTransitionType.new()


## Helper method to resolve transition parameters into an AceTransitionConfig.
func get_transition_config(transition: AceTransitionConfig = null) -> AceTransitionConfig:
	if transition != null:
		return transition
	return AceTransitions.get_transition_config("Fade", AceSceneManager.settings)


## Helper method to resolve the root Control node for a given transition parameter.
func get_transition_node(transition: AceTransitionConfig) -> Control:
	var info: AceTransitionType = get_transition_type_info(transition)
	if info != null:
		var root_path_str: String = info.get_root_path_string()
		if not root_path_str.is_empty() and has_node(NodePath(root_path_str)):
			return get_node_or_null(NodePath(root_path_str)) as Control

	# Fallback: Return first child Control node on this loading scene instance
	for child in get_children():
		if child is Control:
			return child as Control

	return null


## Helper method to resolve the progress bar node for a given transition parameter.
func get_progress_bar_node(transition: AceTransitionConfig) -> Control:
	var info: AceTransitionType = get_transition_type_info(transition)
	if info != null and info.has_progress_bar:
		var pb_path_str: String = info.get_progress_path_string()
		if not pb_path_str.is_empty() and has_node(NodePath(pb_path_str)):
			return get_node_or_null(NodePath(pb_path_str)) as Control

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


## Helper method to resolve the shader target node for a given transition parameter.
func get_shader_node(transition: AceTransitionConfig) -> CanvasItem:
	var info: AceTransitionType = get_transition_type_info(transition)
	if info != null:
		var sh_path_str: String = info.get_shader_path_string()
		if not sh_path_str.is_empty() and has_node(NodePath(sh_path_str)):
			return get_node_or_null(NodePath(sh_path_str)) as CanvasItem
	
	return get_transition_node(transition) as CanvasItem


## Helper method to setup and assign a ShaderMaterial with the transition shader onto the target node.
func setup_shader_material(transition: AceTransitionConfig) -> ShaderMaterial:
	var info: AceTransitionType = get_transition_type_info(transition)
	if info != null and info.has_shader and info.shader != null:
		var target: CanvasItem = get_shader_node(transition)
		if target != null:
			var mat: ShaderMaterial = target.material as ShaderMaterial
			if mat == null:
				mat = ShaderMaterial.new()
				target.material = mat
			mat.shader = info.shader
			return mat
	return null


# ==============================================================================
# PRIVATE / CALLBACK METHODS
# ==============================================================================

## Called by AceSceneManager when thread load progress updates.
## [param new_value]: Load progress from 0.0 to 1.0 (or 0 to 100).
@abstract func _on_progress_changed(new_value: float) -> void


## Called by AceSceneManager when resource load completes.
@abstract func _on_load_finished() -> void
