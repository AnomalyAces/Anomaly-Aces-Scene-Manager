@tool
class_name AceTablePlugin extends Control 

var header_theme: Theme
var header_cell_theme: Theme
var row_theme: Theme
var row_cell_theme: Theme
var cell_separation: int

func _print(args):
	AceLog.printLog([args])

func _get_property_list():
	return [
		{
			"name": "Table Properties",
			"type": TYPE_NIL,
			"hint_string": "table_",
			"usage": PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name": "header_theme",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Theme"
		},
		{
			"name": "header_cell_theme",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Theme"
		},
		{
			"name": "row_theme",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Theme"
		},
		{
			"name": "row_cell_theme",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Theme"
		},
		{
			"name": "cell_separation",
			"type": TYPE_INT,
			"hint":  PROPERTY_HINT_NONE
		},
	]


func printConfig():
	var headerTheme: String = null if header_theme == null else header_theme.resource_path
	var headerCellTheme: String = null if header_cell_theme == null else header_cell_theme.resource_path
	var rowTheme: String = null if row_theme == null else row_theme.resource_path
	var rowCellTheme: String = null if row_cell_theme == null else row_cell_theme.resource_path
	var cellSeparation: int = cell_separation

	AceLog.printLog(["header theme: %s" % headerTheme])
	AceLog.printLog(["header cell theme: %s" % headerCellTheme])
	AceLog.printLog(["row theme: %s" % rowTheme])
	AceLog.printLog(["row cell theme: %s" % rowCellTheme])
	AceLog.printLog(["cell separation: %s" % cellSeparation])
