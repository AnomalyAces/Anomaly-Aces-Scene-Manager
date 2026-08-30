@tool
class_name AceScenes extends RefCounted

## Utility class for managing and querying registered scenes eligible for transition.


# ==============================================================================
# PUBLIC STATIC METHODS
# ==============================================================================

static func get_scene_registry(settings: AceSettings) -> Dictionary[String, String]:
	if settings == null:
		return {}
	var registry: Variant = settings.get_setting("scene_registry", {})
	if registry is Dictionary:
		return registry as Dictionary[String, String]
	return {}


static func resolve_scene_path(scene_key_or_path: String, settings: AceSettings) -> String:
	if scene_key_or_path.is_empty():
		return ""
		
	var registry: Dictionary[String, String] = get_scene_registry(settings)
	if registry.has(scene_key_or_path):
		return registry[scene_key_or_path]
		
	return scene_key_or_path


static func is_scene_eligible(scene_key_or_path: String, settings: AceSettings) -> bool:
	if scene_key_or_path.is_empty():
		return false
		
	var registry: Dictionary[String, String] = get_scene_registry(settings)
	if registry.is_empty():
		# If no registry configured, all scene paths are permitted
		return true
		
	var resolved_path: String = resolve_scene_path(scene_key_or_path, settings)
	return registry.has(scene_key_or_path) or registry.values().has(resolved_path)
