@tool
class_name _AceTableConfig extends Node


#Array of Column Defs to define what Columns Names and Column id of the data entered
var columnDefs: Array[AceTableColumnDef] = []


func _init(colDefs: Array[AceTableColumnDef]):
	for colDef in colDefs:
		if colDef.is_valid():
			columnDefs.append(colDef)
		else:
			colDef.print_errors()

