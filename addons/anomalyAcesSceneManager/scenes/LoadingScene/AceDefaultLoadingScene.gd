@tool
class_name AceDefaultLoadingScene extends AceLoadingScene

## Default loading screen implementation for Ace Scene Manager.
## Provides fade and circle wipe transitions with animated progress bar updates.

var _selected_transition: Dictionary


# ==============================================================================
# ENGINE VIRTUAL METHODS
# ==============================================================================

func _ready() -> void:
	if transition_types.is_empty():
		transition_types = {
			"Fade": AceTransitionType.new("Fade", true, "Fade/ProgressBar"),
			"Circle": AceTransitionType.new("Circle", false, "")
		}


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func play_transition(transition: Variant) -> void:
	_selected_transition = _get_transition_dict(transition)
	_setup_transition_node()

	var start_anim: String = _selected_transition.get(AceTransitions.START, "")
	if animation_player != null and not start_anim.is_empty() and animation_player.has_animation(start_anim):
		animation_player.play(start_anim)
		await animation_player.animation_finished
	
	loading_screen_ready.emit()


func finish_transition() -> void:
	var end_anim: String = _selected_transition.get(AceTransitions.END, "")
	if animation_player != null and not end_anim.is_empty() and animation_player.has_animation(end_anim):
		animation_player.play(end_anim)
		await animation_player.animation_finished
		
	loading_screen_finished.emit()
	queue_free()


# ==============================================================================
# PRIVATE / CALLBACK METHODS
# ==============================================================================

func _get_active_transition_node() -> Control:
	return get_transition_node(_selected_transition)


func _setup_transition_node() -> void:
	var active_node: Control = _get_active_transition_node()
	if active_node != null:
		active_node.visible = true


func _on_progress_changed(new_value: float) -> void:
	var pb_node: Control = get_progress_bar_node(_selected_transition)
	var active_bar: ProgressBar = pb_node as ProgressBar if pb_node is ProgressBar else null

	if active_bar != null:
		var pct: float = new_value * 100.0 if new_value <= 1.0 else new_value
		active_bar.value = pct
		active_bar.visible = (pct > 10.0)
