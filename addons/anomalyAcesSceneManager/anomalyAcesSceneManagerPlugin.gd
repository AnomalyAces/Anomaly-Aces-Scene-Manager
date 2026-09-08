@tool
extends EditorPlugin

const AUTOLOAD_NAME: String = "AceSceneManager"
const AUTOLOAD_PATH: String = "res://addons/anomalyAcesSceneManager/scripts/AceSceneManager.gd"


const TOOL_MENU_TRANSITION_CONFIG: String = "Create Ace Transition Config..."
const TOOL_MENU_TRANSITION_TYPE: String = "Create Ace Transition Type..."

var _config_dialog: EditorFileDialog = null
var _type_dialog: EditorFileDialog = null


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _enter_tree() -> void:
	add_tool_menu_item(TOOL_MENU_TRANSITION_CONFIG, _on_create_transition_config)
	add_tool_menu_item(TOOL_MENU_TRANSITION_TYPE, _on_create_transition_type)


func _exit_tree() -> void:
	remove_tool_menu_item(TOOL_MENU_TRANSITION_CONFIG)
	remove_tool_menu_item(TOOL_MENU_TRANSITION_TYPE)
	if is_instance_valid(_config_dialog):
		_config_dialog.queue_free()
	if is_instance_valid(_type_dialog):
		_type_dialog.queue_free()


func _on_create_transition_config() -> void:
	if not is_instance_valid(_config_dialog):
		_config_dialog = EditorFileDialog.new()
		_config_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
		_config_dialog.add_filter("*.tres", "Ace Transition Config (*.tres)")
		_config_dialog.title = "Create New Ace Transition Config"
		_config_dialog.file_selected.connect(_on_transition_config_selected)
		get_editor_interface().get_base_control().add_child(_config_dialog)

	_config_dialog.current_file = "NewTransitionConfig.tres"
	if _config_dialog.has_method("popup_file_dialog"):
		_config_dialog.popup_file_dialog()
	else:
		_config_dialog.popup_centered_ratio(0.6)


func _on_transition_config_selected(path: String) -> void:
	var config := AceTransitionConfig.new()
	var err := ResourceSaver.save(config, path)
	if err == OK:
		get_editor_interface().get_resource_filesystem().rescan()
		get_editor_interface().edit_resource(config)
		AceLog.printLog(["Created new AceTransitionConfig at '%s'." % path], AceLog.LOG_LEVEL.INFO)
	else:
		AceLog.printLog(["Failed to save AceTransitionConfig at '%s' (Error: %s)" % [path, err]], AceLog.LOG_LEVEL.ERROR)


func _on_create_transition_type() -> void:
	if not is_instance_valid(_type_dialog):
		_type_dialog = EditorFileDialog.new()
		_type_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
		_type_dialog.add_filter("*.tres", "Ace Transition Type (*.tres)")
		_type_dialog.title = "Create New Ace Transition Type"
		_type_dialog.file_selected.connect(_on_transition_type_selected)
		get_editor_interface().get_base_control().add_child(_type_dialog)

	_type_dialog.current_file = "NewTransitionType.tres"
	if _type_dialog.has_method("popup_file_dialog"):
		_type_dialog.popup_file_dialog()
	else:
		_type_dialog.popup_centered_ratio(0.6)


func _on_transition_type_selected(path: String) -> void:
	var trans_type := AceTransitionType.new()
	var err := ResourceSaver.save(trans_type, path)
	if err == OK:
		get_editor_interface().get_resource_filesystem().rescan()
		get_editor_interface().edit_resource(trans_type)
		AceLog.printLog(["Created new AceTransitionType at '%s'." % path], AceLog.LOG_LEVEL.INFO)
	else:
		AceLog.printLog(["Failed to save AceTransitionType at '%s' (Error: %s)" % [path, err]], AceLog.LOG_LEVEL.ERROR)

