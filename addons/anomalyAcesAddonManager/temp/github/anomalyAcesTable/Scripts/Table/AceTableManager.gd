@tool
class_name AceTableManager extends Node


static func createTable(plugin: AceTablePlugin, colDefs: Array[AceTableColumnDef], data: Array[Dictionary] = []) -> _AceTable:
	var table: _AceTable
	
	if plugin == null:
		AceLog.printLog(["AceTableManager not initialized, Please call AceTableManager.initialize()"], AceLog.LOG_LEVEL.ERROR)
		return null
	
	if plugin.get_children().size() > 0:
		var _child_tbl: _AceTable = plugin.find_child("AceTable")
		if _child_tbl != null:
			AceLog.printLog(["AceTableManager already has a table, returning existing table. To have multiple tables, add multiple AceTable nodes to the scene tree. To update an existing table, call AceTableManager 'setTableData'* methods"], AceLog.LOG_LEVEL.ERROR)
			table = _child_tbl
			return table
		else:
			AceLog.printLog(["AceTableManager has children but no table found, creating new table. To avoid this message, ensure the table node root is named 'AceTable'"], AceLog.LOG_LEVEL.ERROR)
			return null

	
	var tblConfig: _AceTableConfig = _AceTableConfig.new(colDefs)
	table = _AceTable.new()
	table.initializeTable(plugin, tblConfig)
	
	setTableData(table, data)
		
	return table
	
	
static func setTableData(table: _AceTable, data: Array[Dictionary]) -> void:
	if(data.size() > 0):
		table.set_data(data)

static func setTableDataFromObj(table: _AceTable, data: Array[Object]) -> void:
	var dict_data: Array[Dictionary] = JSON.parse_string(AceSerialize.serialize_array(data))
	setTableData(table, dict_data)
