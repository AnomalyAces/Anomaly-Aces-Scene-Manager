@tool
class_name AceTransitionConfig extends Resource

## Resource model representing a transition animation configuration (start anim, end anim, and transition type layout).

@export var start: String = ""
@export var end: String = ""
@export var type: AceTransitionType


# ==============================================================================
# CONSTRUCTOR
# ==============================================================================

func _init(p_start: String = "", p_end: String = "", p_type: AceTransitionType = null) -> void:
	start = p_start
	end = p_end
	type = p_type


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func is_valid() -> bool:
	return not start.is_empty() and not end.is_empty()


func to_dictionary() -> Dictionary:
	return {
		AceTransitions.START: start,
		AceTransitions.END: end,
		AceTransitions.TYPE: type.to_dictionary() if type != null else {}
	}


static func from_dictionary(dict: Dictionary) -> AceTransitionConfig:
	if dict == null:
		return AceTransitionConfig.new()
	var s: String = String(dict.get(AceTransitions.START, ""))
	var e: String = String(dict.get(AceTransitions.END, ""))
	var raw_t: Variant = dict.get(AceTransitions.TYPE, null)
	var t: AceTransitionType = null
	if raw_t is AceTransitionType:
		t = raw_t as AceTransitionType
	elif typeof(raw_t) == TYPE_DICTIONARY:
		t = AceTransitionType.from_dictionary(raw_t as Dictionary)
	return AceTransitionConfig.new(s, e, t)
