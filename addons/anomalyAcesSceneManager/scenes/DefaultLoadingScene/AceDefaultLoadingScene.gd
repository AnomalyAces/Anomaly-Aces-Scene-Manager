@tool
class_name AceDefaultLoadingScene extends AceLoadingScene

## Default loading screen implementation for Ace Scene Manager.
## Provides fade and circle wipe transitions with animated progress bar updates.

var _selected_transition: AceTransitionConfig


# ==============================================================================
# ENGINE VIRTUAL METHODS
# ==============================================================================

func _ready() -> void:
	super._ready()


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func play_transition(transition: AceTransitionConfig) -> void:
	_selected_transition = _get_transition_config(transition)
	_setup_transition_node()

	var start_anim: String = _selected_transition.start if _selected_transition != null else ""
	AceLog.printLog(["[TRANSITION DIAGNOSTIC] play_transition: anim='%s', has_anim=%s, anim_player=%s" % [start_anim, (animation_player.has_animation(start_anim) if animation_player != null else false), animation_player]], AceLog.LOG_LEVEL.INFO)

	if animation_player != null and not start_anim.is_empty() and animation_player.has_animation(start_anim):
		animation_player.play(start_anim)
		await animation_player.animation_finished
	
	loading_screen_ready.emit()


func finish_transition() -> void:
	for child in get_children():
		if child is Control:
			var c_ctrl: Control = child as Control
			c_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for c in c_ctrl.get_children():
				if c is Control:
					(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	var end_anim: String = _selected_transition.end if _selected_transition != null else ""
	AceLog.printLog(["[TRANSITION DIAGNOSTIC] finish_transition: anim='%s', has_anim=%s, anim_player=%s" % [end_anim, (animation_player.has_animation(end_anim) if animation_player != null else false), animation_player]], AceLog.LOG_LEVEL.INFO)

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
	for child in get_children():
		if child is Control:
			(child as Control).visible = (child == active_node)

	setup_shader_material(_selected_transition)



func _on_progress_changed(new_value: float) -> void:
	var pb_node: Control = get_progress_bar_node(_selected_transition)
	var active_bar: ProgressBar = pb_node as ProgressBar if pb_node is ProgressBar else null

	if active_bar != null:
		var pct: float = new_value * 100.0 if new_value <= 1.0 else new_value
		active_bar.value = pct
		active_bar.visible = (pct > 10.0)


func _on_load_finished() -> void:
	var pb_node: Control = get_progress_bar_node(_selected_transition)
	var active_bar: ProgressBar = pb_node as ProgressBar if pb_node is ProgressBar else null
	if active_bar != null:
		active_bar.value = 100.0
