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
		
	if settings != null:
		var custom_transitions: Dictionary = settings.get_setting("available_transitions", {})
		if custom_transitions.has(transition_name):
			var custom_trans: AceTransitionConfig = custom_transitions[transition_name] as AceTransitionConfig
			if is_valid_transition(custom_trans):
				return custom_trans

	if AceSceneManagerDemoSettings.demo_transitions.has(transition_name):
		return AceSceneManagerDemoSettings.demo_transitions[transition_name]
		
	return null


static func get_transition_config(transition_name: String, settings: AceSettings = null) -> AceTransitionConfig:
	var config: AceTransitionConfig = get_transition(transition_name, settings)
	if config != null:
		return config
	return AceTransitionConfig.new()
