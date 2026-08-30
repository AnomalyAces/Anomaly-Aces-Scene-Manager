@tool
class_name AceTableColumnDef extends Node

const INVALID_TYPE: int = -1

class ColumnSortButton:
	var ascending: Resource
	var descending: Resource

	func _init(asc: String, desc: String) -> void:
		ascending = load(asc)
		descending = load(desc)

class ColumnCheckBox:
	var checked: Resource
	var unchecked: Resource

	func _init(chkd: String, unchkd: String) -> void:
		checked = load(chkd)
		unchecked = load(unchkd)

var _validationErrors: PackedStringArray = []

var columnName: String
var columnId: String
var columnType: AceTableConstants.ColumnType = AceTableConstants.ColumnType.NONE
var columnSort: bool = false
var columnSortButton: ColumnSortButton
var columnAlign: AceTableConstants.Align = AceTableConstants.Align.LEFT
var columnImage: String
var columnImageSize: Vector2i = Vector2i(32,32)
var columnImageAlign:AceTableConstants.ImageAlign = AceTableConstants.ImageAlign.LEFT
var columnCallable: Callable
var columnNode: Control
var columnButtonType: AceTableConstants.ButtonType = AceTableConstants.ButtonType.COMBO
var columnButtonIconUpdateWithState: bool = false
var columnTextType: AceTableConstants.TextType = AceTableConstants.TextType.TEXT
var columnTextIconUpdateWithState: bool = false
var columnCheckBox: ColumnCheckBox
var columnHasSelectAll: bool = false


#Check if the columDef is valid
func is_valid() -> bool:
	var warnings: PackedStringArray = []
	if(columnId.is_empty()):
		warnings.append("Column Id is empty")
	if(columnName.is_empty() && columnType != AceTableConstants.ColumnType.SELECTION):
		warnings.append("[%s]: Column Name is empty while Column Type is not 'AceTableConstants.ColumnType.SELECTION'" % columnId)
	if(columnType == AceTableConstants.ColumnType.NONE):
		warnings.append("Column Definition Input invalid")
	if(columnType == AceTableConstants.ColumnType.BUTTON && columnCallable.is_null()):
		warnings.append("[%s]: Column Type is Button but no Callable has been given" % columnId)
	if(columnType == AceTableConstants.ColumnType.LABEL && columnTextType == AceTableConstants.TextType.LINK && columnCallable.is_null()):
		warnings.append("[%s]: Column Type is Label, Text Type is Link but no Callable has been given" % columnId)
	if(columnNode):
		if(!_isValidNode()):
			warnings.append("[%s]: Column Node %s' does not match Column Type %s" % [columnId, columnNode.name, AceTableConstants.ColumnType.keys()[columnType]])
	
	_validationErrors = warnings
	return warnings.is_empty()

func print_errors():
	for error in _validationErrors:
		AceLog.printLog(["AceTableError - "+error], AceLog.LOG_LEVEL.ERROR)


func clone() -> AceTableColumnDef:
	var newColDef: AceTableColumnDef = AceTableColumnDef.new()
	newColDef.columnName = columnName
	newColDef.columnId = columnId
	newColDef.columnType = columnType
	newColDef.columnSort = columnSort
	newColDef.columnAlign = columnAlign
	newColDef.columnImage = columnImage
	newColDef.columnImageSize = columnImageSize
	newColDef.columnImageAlign = columnImageAlign
	newColDef.columnCallable = columnCallable
	newColDef.columnNode = columnNode
	newColDef.columnButtonType = columnButtonType
	newColDef.columnButtonIconUpdateWithState = columnButtonIconUpdateWithState
	newColDef.columnTextType = columnTextType
	newColDef.columnTextIconUpdateWithState = columnTextIconUpdateWithState
	newColDef.columnSortButton = columnSortButton
	newColDef.columnCheckBox = columnCheckBox
	return newColDef

func _isValidNode() -> bool:
	match columnType:
		AceTableConstants.ColumnType.LABEL:
			return columnNode is Label
		AceTableConstants.ColumnType.BUTTON:
			return columnNode is BaseButton
		AceTableConstants.ColumnType.TEXTURE_RECT:
			return columnNode is TextureRect
		AceTableConstants.ColumnType.SELECTION:
			return columnNode is CheckBox
		_:
			AceLog.printLog(["Column Node %s' does not match Column Type %s" % [columnNode.name, AceTableConstants.ColumnType.keys()[columnType]]], AceLog.LOG_LEVEL.ERROR)
			return false

func _to_string() -> String:
	var dict: Dictionary = {
		"columnName": columnName,
		"columnId": columnId,
		"columnType": AceTableConstants.ColumnType.keys()[columnType],
		"columnSort": columnSort,
		"columnAlign": AceTableConstants.Align.keys()[columnAlign],
		"columnImage": columnImage,
		"columnImageSize": columnImageSize,
		"columnImageAlign": AceTableConstants.ImageAlign.keys()[columnImageAlign],
		"columnCallable": str(columnCallable),
		"columnNode": str(columnNode),
		"columnButtonType": AceTableConstants.ButtonType.keys()[columnButtonType],
		"columnButtonIconUpdateWithState": columnButtonIconUpdateWithState,
		"columnTextType": AceTableConstants.TextType.keys()[columnTextType],
		"columnTextIconUpdateWithState": columnTextIconUpdateWithState,
		"columnSortButton": {
			"ascending": columnSortButton.ascending,
			"descending": columnSortButton.descending
		} if columnSortButton != null else null,
		"columnCheckBox": {
			"checked": columnCheckBox.checked,
			"unchecked": columnCheckBox.unchecked
		} if columnCheckBox != null else null
	}
	return JSON.stringify(dict)