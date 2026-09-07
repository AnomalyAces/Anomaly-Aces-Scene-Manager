@tool
class_name AceScenes extends RefCounted

## Utility class for managing and querying registered scenes eligible for transition.


# ==============================================================================
# PUBLIC STATIC METHODS
# ==============================================================================

static func get_scene_registry(settings: AceSettings) -> Dictionary[String, String]:
	if settings != null:
		var registry: Variant = settings.get_setting("scene_registry", {})
		if registry is Dictionary and not (registry as Dictionary).is_empty():
			var res: Dictionary[String, String] = {}
			var dict: Dictionary = registry as Dictionary
			for k in dict:
				res[String(k)] = String(dict[k])
			return res

	if AceSceneManagerDemoSettings.demo_scene_registry.size() > 0:
		return AceSceneManagerDemoSettings.demo_scene_registry

	return {}


static func resolve_scene_path(scene_key_or_path: String, settings: AceSettings) -> String:
	if scene_key_or_path.is_empty():
		return ""
		
	var registry: Dictionary[String, String] = get_scene_registry(settings)
	if registry.has(scene_key_or_path):
		return registry[scene_key_or_path]

	if scene_key_or_path.begins_with("res://"):
		return scene_key_or_path

	if AceSceneManagerDemoSettings.demo_scene_registry.has(scene_key_or_path):
		return AceSceneManagerDemoSettings.demo_scene_registry[scene_key_or_path]

	return ""


static func is_scene_eligible(scene_key_or_path: String, settings: AceSettings) -> bool:
	if scene_key_or_path.is_empty():
		return false

	var resolved_path: String = resolve_scene_path(scene_key_or_path, settings)
	return not resolved_path.is_empty() and (ResourceLoader.exists(resolved_path) or FileAccess.file_exists(resolved_path))
