@tool
class_name _AceTableRow extends HBoxContainer

const _ace_table_button_scene = preload("res://addons/anomalyAcesTable/Scene/Button/_AceTableButton.tscn")
const _ace_table_checkbox_button_scene = preload("res://addons/anomalyAcesTable/Scene/Button/ButtonTypes/AceTableButtonCheckbox/_AceTableButtonCheckbox.tscn")
const _ace_table_text_scene: Resource = preload("res://addons/anomalyAcesTable/Scene/Text/_AceTableText.tscn")

signal pressed
signal row_selected(row_data: Dictionary)

var data: Dictionary




func initializeRow(plugin: AceTablePlugin, cfg: _AceTableConfig, rowScene: HBoxContainer, dt: Dictionary = {}):
	if(plugin == null || cfg == null):
		return
	
	data = dt
	rowScene.add_theme_constant_override("separation", plugin.cell_separation)
	
	for colDef in cfg.columnDefs:
		var cell: _AceTableCell = _AceTableCell.new()
		match colDef.columnType:
			AceTableConstants.ColumnType.LABEL:
				var label: _AceTableText = _getLabelFromConfig(colDef,data)
				rowScene.add_child(cell.compose_cell(plugin.row_cell_theme, label, colDef))
			AceTableConstants.ColumnType.BUTTON:
				var button: BaseButton = _getButtonFromConfig(colDef, data)
				rowScene.add_child(cell.compose_cell(plugin.row_cell_theme, button, colDef))
			AceTableConstants.ColumnType.TEXTURE_RECT:
				var image = _getTextureRectFromConfig(colDef, data)
				rowScene.add_child(cell.compose_cell(plugin.row_cell_theme, image, colDef))
			AceTableConstants.ColumnType.SELECTION:
				var checkBox = _getSelectionButtonFromConfig(colDef, data)
				checkBox.data_selected.connect(_on_row_selected)
				rowScene.add_child(cell.compose_cell(plugin.row_cell_theme, checkBox, colDef))
			_:
				AceLog.printLog(["Column Def %s column type %s is unknown" % [colDef, AceTableConstants.ColumnType.keys()[colDef.columnType]]], AceLog.LOG_LEVEL.ERROR)
	
func _table_update_selection(is_pressed: bool) -> void:
	var checkBox: _AceTableButtonCheckbox =  AceArrayUtil.findFirst( find_children("*", "_AceTableButtonCheckbox", true, false), func(c): return c is _AceTableButtonCheckbox)
	if checkBox != null:
		AceLog.printLog(["_AceTableRow: data %s" % [data]], AceLog.LOG_LEVEL.DEBUG)
		data["selected"] = is_pressed
		checkBox.set_pressed_no_signal(is_pressed)
		checkBox._set_active_colors() if is_pressed else checkBox._set_normal_colors()

func _getLabelFromConfig(colDef: AceTableColumnDef, dt: Dictionary) -> _AceTableText:
	var label: _AceTableText
	if(colDef.columnNode != null):
		label = colDef.columnNode.duplicate()
		label.name = colDef.columnId
		label.text = dt[colDef.columnId]
	else:
		label = _ace_table_text_scene.instantiate()
		label.colDef = colDef
		label.data = dt
	
	return label	

func _getButtonFromConfig(colDef: AceTableColumnDef, dt: Dictionary) -> BaseButton: 
	var button: _AceTableButton
	
	if(colDef.columnNode != null):
		button = colDef.columnNode.duplicate()
		button.name = colDef.columnId
		button.text = dt[colDef.columnId]
	else:
		button = _ace_table_button_scene.instantiate()
		button.colDef = colDef
		button.data = dt

	return button

func _getTextureRectFromConfig(colDef: AceTableColumnDef, dt: Dictionary) -> TextureRect:
	var textureRect: TextureRect
	if(colDef.columnNode != null):
		textureRect = colDef.columnNode.duplicate()
		textureRect.name = colDef.columnId
	else:
		textureRect = TextureRect.new()
		textureRect.name = colDef.columnId
		textureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textureRect.size_flags_horizontal = SIZE_EXPAND_FILL
		textureRect.custom_minimum_size = colDef.columnImageSize
		textureRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		textureRect.set_texture(load(dt[colDef.columnId]))
	return textureRect

func _getSelectionButtonFromConfig(colDef: AceTableColumnDef, dt: Dictionary) -> _AceTableButtonCheckbox:
	var checkBox: _AceTableButtonCheckbox
	
	if(colDef.columnNode != null):
		checkBox = colDef.columnNode.duplicate()
		checkBox.name = colDef.columnId
	else:
		checkBox = _ace_table_checkbox_button_scene.instantiate()
		checkBox.colDef = colDef
		checkBox.data = dt
	return checkBox


func _on_row_selected(colDef: AceTableColumnDef, data: Dictionary):
	AceLog.printLog(["_AceTableRow: Row selected with data [%s]. Emitting row_selected signal." % [data]], AceLog.LOG_LEVEL.DEBUG)
	row_selected.emit(data)


func _to_string() -> String:
	return "_AceTableRow - data: %s" % [data]
