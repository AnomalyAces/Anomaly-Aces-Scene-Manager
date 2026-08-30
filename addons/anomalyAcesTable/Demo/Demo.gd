extends Control


var tablePlugin
# Called when the node enters the scene tree for the first time.
func _ready():
	tablePlugin = $AceTable
	
	var textRect = TextureRect.new()
	textRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	textRect.size_flags_horizontal = SIZE_EXPAND_FILL
	textRect.set_texture(load("res://icon.svg"))

	var fooColDef: AceTableColumnDef = AceTableColumnDef.new()
	fooColDef.columnId = "foo"
	fooColDef.columnName = "Foo"
	fooColDef.columnSort = true
	fooColDef.columnType = AceTableConstants.ColumnType.LABEL
	fooColDef.columnAlign = AceTableConstants.Align.CENTER

	var barColDef: AceTableColumnDef = AceTableColumnDef.new()
	barColDef.columnId = "bar"
	barColDef.columnName = "Bar"
	barColDef.columnSort = true
	barColDef.columnType = AceTableConstants.ColumnType.BUTTON
	barColDef.columnAlign = AceTableConstants.Align.CENTER
	barColDef.columnImage = "res://icon.svg"
	barColDef.columnImageSize = Vector2i(64,64)
	barColDef.columnCallable = button_pressed

	var foobarColDef: AceTableColumnDef = AceTableColumnDef.new()
	foobarColDef.columnId = "foobar"
	foobarColDef.columnName = "FooBar"
	foobarColDef.columnType = AceTableConstants.ColumnType.TEXTURE_RECT
	foobarColDef.columnAlign = AceTableConstants.Align.CENTER
	foobarColDef.columnNode = textRect

	var colDefs: Array[AceTableColumnDef] = [fooColDef, barColDef, foobarColDef]
	
	# var colDefs: Dictionary = {
	# 	"foo":{
	# 		"columnId": "foo",
	# 		"columnName": "Foo",
	# 		"columnSort": true,
	# 		"columnType": AceTableConstants.ColumnType.LABEL,
	# 		"columnAlign": AceTableConstants.Align.CENTER
	# 	},
	# 	"bar":{
	# 		"columnId": "bar",
	# 		"columnName": "Bar",
	# 		"columnSort": true,
	# 		"columnType": AceTableConstants.ColumnType.BUTTON,
	# 		"columnImage": "res://icon.svg",
	# 		"columnCallable": button_pressed.bind("Test"),
	# 		"columnAlign": AceTableConstants.Align.CENTER
			
	# 	},
	# 	"foobar":{
	# 		"columnId": "foobar",
	# 		"columnName": "FooBar",
	# 		"columnType": AceTableConstants.ColumnType.TEXTURE_RECT,
	# 		"columnAlign": AceTableConstants.Align.CENTER,
	# 		"columnNode": textRect
			
	# 	},
	# }
	
	var data: Array[Dictionary] = [
		{
			"foo":"12",
			"bar":"Press Me",
			"foobar": "res://icon.svg"
		},
		{
			"foo":"15",
			"bar":"Old Me",
			"foobar": "res://icon.svg"
		},
		{
			"foo":"10",
			"bar":"Press Me",
			"foobar": "res://icon.svg"
		},
		{
			"foo":"17",
			"bar":"New Me",
			"foobar": "res://icon.svg"
		}
	]

	AceTableManager.createTable(tablePlugin, colDefs, data)
	

func button_pressed(colDef: AceTableColumnDef, dt: Dictionary):
	AceLog.printLog(["data from Button: %s" % [dt]])
