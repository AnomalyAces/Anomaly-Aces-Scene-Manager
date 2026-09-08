@tool
class_name AceTransitions extends RefCounted

## Utility class for transition names, types, and transition configuration lookups.

# ==============================================================================
# PUBLIC STATIC METHODS
# ==============================================================================

static func is_valid_transition(transition: AceTransitionConfig) -> bool:
	return transition != null and transition.is_valid()


static func get_transition(transition_name: String, settings: AceSettings = null) -> AceTransitionConfig:
	if transition_name.is_empty():
		return null
		
	# If transition_name is already a direct resource path or UID
	if transition_name.begins_with("res://") or transition_name.begins_with("uid://"):
		if ResourceLoader.exists(transition_name) or FileAccess.file_exists(transition_name):
			var direct_res: Resource = load(transition_name)
			if direct_res is AceTransitionConfig and is_valid_transition(direct_res):
				return direct_res

	var custom_transitions: Dictionary = settings.get_setting("available_transitions", {}) if settings != null else {}
	if settings != null and not custom_transitions.is_empty():
		# 1. Exact match
		var target_key: String = ""
		if custom_transitions.has(transition_name):
			target_key = transition_name
		else:
			# Case-insensitive or stripped fallback (e.g. "Default" vs "DefaultConfig")
			for k in custom_transitions:
				var k_str: String = String(k)
				if k_str.to_lower() == transition_name.to_lower() \
				or k_str.to_lower() == (transition_name + "config").to_lower() \
				or transition_name.to_lower() == (k_str + "config").to_lower():
					target_key = k_str
					break

		if not target_key.is_empty():
			var custom_val: Variant = custom_transitions[target_key]
			var custom_trans: AceTransitionConfig = null
			if custom_val is AceTransitionConfig:
				custom_trans = custom_val
			elif custom_val is String and not (custom_val as String).is_empty():
				var res: Resource = load(custom_val as String)
				if res is AceTransitionConfig:
					custom_trans = res
			elif custom_val is Dictionary:
				custom_trans = AceTransitionConfig.new(
					custom_val.get("start", ""),
					custom_val.get("end", ""),
					custom_val.get("loading_screen_path", "")
				)
			if is_valid_transition(custom_trans):
				return custom_trans

	if AceSceneManagerDemoSettings.demo_transitions.has(transition_name):
		return AceSceneManagerDemoSettings.demo_transitions[transition_name]

	AceLog.printLog(["Transition '%s' not found. available_transitions keys: %s, demo_transitions keys: %s" % [transition_name, custom_transitions.keys() if settings != null else [], AceSceneManagerDemoSettings.demo_transitions.keys()]], AceLog.LOG_LEVEL.WARN)
	return null


static func get_transition_config(transition_name: String, settings: AceSettings = null) -> AceTransitionConfig:
	var config: AceTransitionConfig = get_transition(transition_name, settings)
	if config != null:
		return config
	return AceTransitionConfig.new()


## Helper method to programmatically create and save a new AceTransitionConfig .tres resource file.
static func create_transition_config(path: String, start_anim: String = "", end_anim: String = "", loading_screen: String = "") -> AceTransitionConfig:
	var config := AceTransitionConfig.new(start_anim, end_anim, loading_screen)
	var dir: String = path.get_base_dir()
	if not dir.is_empty() and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var err: Error = ResourceSaver.save(config, path)
	if err == OK:
		AceLog.printLog(["Created transition config file at '%s'." % path], AceLog.LOG_LEVEL.INFO)
	else:
		AceLog.printLog(["Failed to save transition config at '%s' (Error: %s)" % [path, err]], AceLog.LOG_LEVEL.ERROR)
	return config
