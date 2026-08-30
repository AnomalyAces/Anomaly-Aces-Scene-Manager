@tool
class_name _AceTableButtonCheckbox extends TextureButton

#Scenes and Resources
const _default_checkbox_checked: Resource = preload("res://addons/anomalyAcesTable/Icons/AceTableCheckboxChecked.svg")
const _default_checkbox_unchecked: Resource = preload("res://addons/anomalyAcesTable/Icons/AceTableCheckboxUnchecked.svg")

signal data_selected(colDef: AceTableColumnDef, data: Dictionary)
signal header_selected(is_toggled: bool)

var colDef: AceTableColumnDef
var data: Dictionary

var _prev_disabled: bool = false

func _ready() -> void:

	_apply_button_settings()



func _enter_tree() -> void:
	_prev_disabled = disabled
	set_process(true)

func _process(_delta: float) -> void:
	_update_disabled_state()

func _apply_button_settings():
	AceLog.printLog(["_AceTableButtonCheckbox: Applying button settings for ColDef [%s]" % [colDef]], AceLog.LOG_LEVEL.DEBUG)

	if colDef == null:
		return

	name = colDef.columnId
	size_flags_horizontal = SIZE_EXPAND_FILL
	custom_minimum_size = colDef.columnImageSize if colDef.columnImageSize else Vector2i(64,64)
	toggled.connect(_on_toggled)
	_update_textures()
	_set_normal_colors()


func _update_disabled_state():
	if disabled == _prev_disabled:
		return
	_prev_disabled = disabled
	if disabled:
		_set_disabled_colors()
	else:
		_set_normal_colors()


func _update_shader(color: Color):
	set_instance_shader_parameter("instance_color", color)

func _update_textures():
	texture_normal = colDef.columnCheckBox.unchecked if colDef.columnCheckBox else _default_checkbox_unchecked
	texture_pressed = colDef.columnCheckBox.checked if colDef.columnCheckBox else _default_checkbox_checked
	texture_hover = colDef.columnCheckBox.checked if colDef.columnCheckBox else _default_checkbox_checked
	texture_focused = colDef.columnCheckBox.checked if colDef.columnCheckBox else _default_checkbox_unchecked
	texture_disabled = colDef.columnCheckBox.unchecked if colDef.columnCheckBox else _default_checkbox_unchecked
func _set_normal_colors():

	if disabled:
		return

	_update_shader(get_theme_color("icon_normal_color", "Button"))

func _set_disabled_colors():
	_update_shader(get_theme_color("icon_disabled_color", "Button"))

func _set_active_colors():
	if disabled:
		return

	_update_shader(get_theme_color("icon_pressed_color", "Button"))


func _on_toggled(is_toggled: bool) -> void:
	if is_toggled:
		_set_active_colors()
	else:
		_set_normal_colors()
	

	data[colDef.columnId] = is_toggled
	if colDef.columnButtonType == AceTableConstants.ButtonType.HEADER:
		AceLog.printLog(["Header Selection Toggled From Table -  Value: %s" % [is_toggled]], AceLog.LOG_LEVEL.DEBUG)
		header_selected.emit(is_toggled)
	else:
		AceLog.printLog(["Data Selected From Table -  data: %s" % [data]], AceLog.LOG_LEVEL.DEBUG)
		data_selected.emit(colDef, data)


func _on_mouse_exited() -> void:
	if button_pressed:
		return
	_set_normal_colors()


func _on_mouse_entered() -> void:
	if button_pressed:
		return
	_set_active_colors()


func _on_focus_exited() -> void:
	if button_pressed:
		return
	_set_normal_colors()


func _on_focus_entered() -> void:
	if button_pressed:
		return
	_set_active_colors()


func _to_string() -> String:
	return "_AceTableButtonCheckbox - is_toggled: %s" % [button_pressed]