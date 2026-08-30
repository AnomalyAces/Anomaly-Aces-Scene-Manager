@tool
class_name _AceTableText extends HBoxContainer


var texture_rect: TextureRect
var label: RichTextLabel
var colDef: AceTableColumnDef
var data: Dictionary
var type: AceTableConstants.TextType = AceTableConstants.TextType.TEXT:
	set(t_type):
		type = t_type
		match type:
			AceTableConstants.TextType.ICON:
				label.visible = false
				texture_rect.visible = true
			AceTableConstants.TextType.TEXT:
				texture_rect.visible = false
				label.visible = true
			AceTableConstants.TextType.LINK:
				texture_rect.visible = false
				label.visible = true
			AceTableConstants.TextType.COMBO:
				texture_rect.visible = true
				label.visible = true
			AceTableConstants.TextType.HEADER:
				texture_rect.visible = false
				label.visible = true

var is_right_icon: bool = false:
	set(is_right):
		is_right_icon = is_right
		if texture_rect != null:
			if is_right_icon:
				move_child(texture_rect, 1)
			else:
				move_child(texture_rect, 0)


func _ready() -> void:
	texture_rect = $TextureRect
	label = $Label

	_apply_text_settings()


func _apply_text_settings():
	AceLog.printLog(["_AceTableText: Applying text settings for ColDef [%s]" % [colDef]], AceLog.LOG_LEVEL.DEBUG)

	if colDef == null:
		return
	
	name = colDef.columnId

	label.horizontal_alignment = int(colDef.columnAlign) as HorizontalAlignment

	size_flags_horizontal = SIZE_EXPAND_FILL
	type = colDef.columnTextType
	is_right_icon = colDef.columnImageAlign == AceTableConstants.ImageAlign.RIGHT

	if(type != AceTableConstants.TextType.HEADER && !colDef.columnImage.is_empty()):
		texture_rect.texture = load(colDef.columnImage)
		texture_rect.custom_minimum_size = colDef.columnImageSize if colDef.columnImageSize else Vector2i(64,64)

	if colDef.columnTextType == AceTableConstants.TextType.HEADER:
		label.text = colDef.columnName
	else:
		if colDef.columnTextType == AceTableConstants.TextType.LINK:
			if _is_valid_text_link_data(data):
				var link_data: _AceTableTextLink = _AceTableTextLink.from_dict(data[colDef.columnId])
				if link_data.link.is_empty():
					label.bbcode_text = "[color=%s]%s[/color]" % [link_data.color.to_html(), link_data.text]
				else:
					label.bbcode_text = "[url=%s][color=%s]%s[/color][/url]" % [link_data.link, link_data.color.to_html(), link_data.text]
			else:
				AceLog.printLog(["_AceTableText: Invalid text link data for column [%s]: %s. Should contain 'text' and 'link' keys. No link created." % [colDef.columnId, data[colDef.columnId]]], AceLog.LOG_LEVEL.ERROR)
				label.text = data[colDef.columnId]
		else:
			label.text = data[colDef.columnId]

	_set_normal_colors()

func _update_shader(textureRect: TextureRect, color: Color):
	if colDef.columnTextIconUpdateWithState:
		textureRect.set_instance_shader_parameter("instance_color", color)

func _set_normal_colors():

	label.add_theme_color_override("font_color", get_theme_color("font_color", "Button"))
	_update_shader(texture_rect,  get_theme_color("icon_normal_color", "Button"))

func _set_active_colors():
	label.add_theme_color_override("font_color", get_theme_color("font_pressed_color", "Button"))
	_update_shader(texture_rect,  get_theme_color("icon_pressed_color", "Button"))

func _on_mouse_exited() -> void:
	_set_normal_colors()


func _on_mouse_entered() -> void:
	_set_active_colors()


func _on_focus_exited() -> void:
	_set_normal_colors()


func _on_focus_entered() -> void:
	_set_active_colors()



func _on_label_meta_clicked(meta: String) -> void:
	if colDef.columnCallable != null:
		colDef.columnCallable.call(meta)


func _is_valid_text_link_data(dt: Dictionary) -> bool:
	if dt.has(colDef.columnId):
		var link_data = dt[colDef.columnId]
		if link_data is Dictionary:
			if link_data.has("text") && link_data.has("link"):
				return true
	return false
