@tool
class_name _AceTableSorter extends Node

var inner_column_name : String
var columnDef: AceTableColumnDef

func sort_row_by_column(table: _AceTable, colDef: AceTableColumnDef, column_name: String, sorting_type):
	
	### Init sorting and get data ###
	inner_column_name = column_name
	columnDef = colDef
	

	var rows_data: Array[Dictionary] = table.get_sorted_rows()
	
	
	#for row in rows_data:
		#rows_data.append(row)
	
	### Sort data ###
	match sorting_type:
		AceTableConstants.ColumnSort.SORT_ASCENDING:
			if columnDef.columnTextType == AceTableConstants.TextType.LINK:
				rows_data.sort_custom(_sort_ascending_link)
			else:
				rows_data.sort_custom(_sort_ascending)
		
		AceTableConstants.ColumnSort.SORT_DESCENDING:
			if columnDef.columnTextType == AceTableConstants.TextType.LINK:
				rows_data.sort_custom(_sort_descending_link)
			else:
				rows_data.sort_custom(_sort_descending)

		AceTableConstants.ColumnSort.NONE:
			#No sorting
			rows_data = table.get_rows()
			
	### Clear rows ###
	table._clear_rows()
	
	#Set the table data again
	table._set_sorted_data(rows_data)
	
		


func _sort_ascending(a, b):
	if a[inner_column_name] < b[inner_column_name]:
		return true
	
	return false


func _sort_descending(a, b):
	if a[inner_column_name] > b[inner_column_name]:
		return true
	
	return false

func _sort_ascending_link(a, b):
	var a_link_data = a[inner_column_name]
	var b_link_data = b[inner_column_name]
	if a_link_data is Dictionary && b_link_data is Dictionary:
		if a_link_data.has("text") && b_link_data.has("text"):
			if a_link_data["text"] < b_link_data["text"]:
				return true
	
	return false

func _sort_descending_link(a, b):
	var a_link_data = a[inner_column_name]
	var b_link_data = b[inner_column_name]	
	if a_link_data is Dictionary && b_link_data is Dictionary:
		if a_link_data.has("text") && b_link_data.has("text"):
			if a_link_data["text"] > b_link_data["text"]:
				return true
	
	return false

