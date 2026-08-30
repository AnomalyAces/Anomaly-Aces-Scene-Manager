@tool
class_name _AceTableButton extends Button



var container: HBoxContainer
var texture_rect: TextureRect
var label: Label
var colDef: AceTableColumnDef
var data: Dictionary
var type: AceTableConstants.ButtonType = AceTableConstants.ButtonType.COMBO:
	set(b_type):
		type = b_type
		match type:
			AceTableConstants.ButtonType.ICON:
				label.visible = false
				texture_rect.visible = true
			AceTableConstants.ButtonType.TEXT:
				texture_rect.visible = false
				label.visible = true
			AceTableConstants.ButtonType.CHECKBOX:
				texture_rect.visible = true
				label.visible = false
			AceTableConstants.ButtonType.COMBO:
				texture_rect.visible = true
				label.visible = true
			AceTableConstants.ButtonType.HEADER:
				texture_rect.visible = false
				label.visible = true

var is_right_icon: bool = false:
	set(is_right):
		is_right_icon = is_right
		if texture_rect != null:
			if is_right_icon:
				container.move_child(texture_rect, 1)
			else:
				container.move_child(texture_rect, 0)


func _ready() -> void:
	container = $MarginContainer/ButtonContainer
	texture_rect = $MarginContainer/ButtonContainer/TextureRect
	label = $MarginContainer/ButtonContainer/Label

	_apply_button_settings()


var _prev_disabled: bool = false

func _enter_tree() -> void:
	_prev_disabled = disabled
	set_process(true)

func _process(_delta: float) -> void:
	_update_disabled_state()


func _apply_button_settings():

	AceLog.printLog(["_AceTableButton: Applying button settings for ColDef [%s]" % [colDef]], AceLog.LOG_LEVEL.DEBUG)

	if colDef == null:
		return

	name = colDef.columnId

	label.horizontal_alignment = int(colDef.columnAlign) as HorizontalAlignment

	size_flags_horizontal = SIZE_EXPAND_FILL
	type = colDef.columnButtonType
	is_right_icon = colDef.columnImageAlign == AceTableConstants.ImageAlign.RIGHT

	if(type != AceTableConstants.ButtonType.HEADER && !colDef.columnImage.is_empty()):
		texture_rect.texture = load(colDef.columnImage)
		texture_rect.custom_minimum_size = colDef.columnImageSize if colDef.columnImageSize else Vector2i(64,64)
	
	if colDef.columnButtonType == AceTableConstants.ButtonType.HEADER:
		label.text = colDef.columnName
		is_right_icon = true
	else:
		label.text = data[colDef.columnId]
		is_right_icon = colDef.columnImageAlign == AceTableConstants.ImageAlign.RIGHT
		if !pressed.is_connected(_on_pressed):
			pressed.connect(_on_pressed)
	
	_set_normal_colors()
	

func _update_disabled_state():
	if disabled == _prev_disabled:
		return
	_prev_disabled = disabled
	if disabled:
		_set_disabled_colors()
	else:
		_set_normal_colors()

func _update_shader(textureRect: TextureRect, color: Color):
	if colDef.columnButtonIconUpdateWithState:
		textureRect.set_instance_shader_parameter("instance_color", color)

func _set_normal_colors():

	if disabled:
		return

	label.add_theme_color_override("font_color", get_theme_color("font_color", "Button"))
	_update_shader(texture_rect,  get_theme_color("icon_normal_color", "Button"))

func _set_disabled_colors():
	label.add_theme_color_override("font_color", get_theme_color("font_disabled_color", "Button"))
	_update_shader(texture_rect,  get_theme_color("icon_disabled_color", "Button"))
func _set_active_colors():
	if disabled:
		return

	label.add_theme_color_override("font_color", get_theme_color("font_pressed_color", "Button"))
	_update_shader(texture_rect,  get_theme_color("icon_pressed_color", "Button"))


func _on_button_up() -> void:
	_set_normal_colors()


func _on_pressed() -> void:
	_set_active_colors()
	
	if !colDef.columnCallable.is_null():
		colDef.columnCallable.call(colDef, data)
	else:
		AceLog.printLog(["AceTableWarning - Column [%s]: button was pressed but its Callable is null. Check column definition and errors in logs" % [colDef.columnId]], AceLog.LOG_LEVEL.WARN)


func _on_mouse_exited() -> void:
	_set_normal_colors()


func _on_mouse_entered() -> void:
	_set_active_colors()


func _on_focus_exited() -> void:
	_set_normal_colors()


func _on_focus_entered() -> void:
	_set_active_colors()
