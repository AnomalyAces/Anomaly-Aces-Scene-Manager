@tool
class_name AceTransitions extends RefCounted

## Utility class for transition names, types, and transition configuration lookups.

# ==============================================================================
# CONSTANTS
# ==============================================================================

const START: String = "start"
const END: String = "end"
const TYPE: String = "type"

# Transition Names
const TRANSITION_FADE_BLACK: String = "fadeBlack"
const TRANSITION_CIRCLE_BLACK: String = "circleBlack"

# Transition Types
const TYPE_FADE: String = "Fade"
const TYPE_CIRCLE: String = "Circle"

static var fade_type: AceTransitionType = AceTransitionType.new("Fade", true, "Fade/ProgressBar")
static var circle_type: AceTransitionType = AceTransitionType.new("Circle", false, "")

static var DEFAULT_TRANSITIONS: Dictionary[String, AceTransitionConfig] = {
	TRANSITION_FADE_BLACK: AceTransitionConfig.new("fade_to_black", "fade_from_black", fade_type),
	TRANSITION_CIRCLE_BLACK: AceTransitionConfig.new("fade_to_black_circle", "fade_from_black_circle", circle_type)
}


# ==============================================================================
# PUBLIC STATIC METHODS
# ==============================================================================

static func is_valid_transition(transition: Variant) -> bool:
	if transition is AceTransitionConfig:
		return (transition as AceTransitionConfig).is_valid()
	elif typeof(transition) == TYPE_DICTIONARY:
		var d: Dictionary = transition as Dictionary
		return not d.is_empty() and d.get(START) != null and d.get(END) != null
	return false


static func get_transition(transition_name: String, settings: AceSettings = null) -> Variant:
	if transition_name.is_empty():
		return null
		
	if settings != null:
		var custom_transitions: Dictionary = settings.get_setting("available_transitions", {})
		if custom_transitions.has(transition_name):
			var custom_trans = custom_transitions[transition_name]
			if is_valid_transition(custom_trans):
				return custom_trans
				
	var default_trans = DEFAULT_TRANSITIONS.get(transition_name)
	if default_trans != null and is_valid_transition(default_trans):
		return default_trans
		
	return null


static func get_transition_config(transition_name: String, settings: AceSettings = null) -> AceTransitionConfig:
	var trans = get_transition(transition_name, settings)
	if trans is AceTransitionConfig:
		return trans as AceTransitionConfig
	elif typeof(trans) == TYPE_DICTIONARY:
		return AceTransitionConfig.from_dictionary(trans as Dictionary)
	return AceTransitionConfig.new()
