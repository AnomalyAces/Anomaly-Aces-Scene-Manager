@tool
class_name DemoCustomLoadingScreen extends AceLoadingScene

## Demo implementation of a custom loading screen overriding the default loading screen.
## Demonstrates waiting for user key press after resource load completion before showing the new scene.

signal user_pressed_continue

var _selected_transition: AceTransitionConfig
var _waiting_for_input: bool = false


func _ready() -> void:
	super._ready()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not _waiting_for_input:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
		_waiting_for_input = false
		get_viewport().set_input_as_handled()
		user_pressed_continue.emit()


func play_transition(transition: AceTransitionConfig) -> void:
	_selected_transition = get_transition_config(transition)
	var active_node: Control = get_transition_node(_selected_transition)
	if active_node != null:
		active_node.visible = true

	var start_anim: String = _selected_transition.start if _selected_transition != null else ""
	if animation_player != null and not start_anim.is_empty() and animation_player.has_animation(start_anim):
		animation_player.play(start_anim)
		await animation_player.animation_finished

	loading_screen_ready.emit()


func finish_transition() -> void:
	_waiting_for_input = true
	_update_prompt_ui()

	# Wait for user key press / click before revealing the newly loaded scene
	await user_pressed_continue

	# Ignore mouse input during exit animation so clicks reach the new scene
	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_IGNORE)

	var end_anim: String = _selected_transition.end if _selected_transition != null else ""
	if animation_player != null and not end_anim.is_empty() and animation_player.has_animation(end_anim):
		animation_player.play(end_anim)
		await animation_player.animation_finished

	loading_screen_finished.emit()
	queue_free()


func _on_progress_changed(new_value: float) -> void:
	var active_bar: ProgressBar = _get_active_progress_bar()
	if active_bar != null:
		var pct: float = new_value * 100.0 if new_value <= 1.0 else new_value
		active_bar.value = pct


func _on_load_finished() -> void:
	var active_bar: ProgressBar = _get_active_progress_bar()
	if active_bar != null:
		active_bar.value = 100.0

	_update_prompt_ui()


func _get_active_progress_bar() -> ProgressBar:
	var pb_node: Control = get_progress_bar_node(_selected_transition)
	if pb_node is ProgressBar:
		return pb_node as ProgressBar
	var scene_bar: Node = find_child("ProgressBar", true, false)
	if scene_bar is ProgressBar:
		return scene_bar as ProgressBar
	return null


func _update_prompt_ui() -> void:
	var prompt: Label = get_node_or_null("Panel/PromptLabel") as Label
	if prompt != null:
		prompt.text = "Press Any Key to Continue..."
		prompt.visible = true
	else:
		var title: Label = get_node_or_null("Panel/TitleLabel") as Label
		if title != null:
			title.text = "=== LOADING COMPLETE ===\nPress Any Key to Continue..."


func _set_mouse_filter_recursive(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)
