@tool
class_name DemoCustomLoadingScreen extends AceLoadingScene

## Demo implementation of a custom loading screen overriding the default loading screen.

var _selected_transition: AceTransitionConfig


func _ready() -> void:
	super._ready()


func play_transition(transition: AceTransitionConfig) -> void:
	_selected_transition = _get_transition_config(transition)
	var active_node: Control = get_transition_node(_selected_transition)
	if active_node != null:
		active_node.visible = true

	var start_anim: String = _selected_transition.start if _selected_transition != null else ""
	if animation_player != null and not start_anim.is_empty() and animation_player.has_animation(start_anim):
		animation_player.play(start_anim)
		await animation_player.animation_finished

	loading_screen_ready.emit()


func finish_transition() -> void:
	var end_anim: String = _selected_transition.end if _selected_transition != null else ""
	if animation_player != null and not end_anim.is_empty() and animation_player.has_animation(end_anim):
		animation_player.play(end_anim)
		await animation_player.animation_finished

	loading_screen_finished.emit()
	queue_free()


func _on_progress_changed(new_value: float) -> void:
	var pb_node: Control = get_progress_bar_node(_selected_transition)
	var active_bar: ProgressBar = pb_node as ProgressBar if pb_node is ProgressBar else null
	if active_bar != null:
		var pct: float = new_value * 100.0 if new_value <= 1.0 else new_value
		active_bar.value = pct


func _on_load_finished() -> void:
	pass
