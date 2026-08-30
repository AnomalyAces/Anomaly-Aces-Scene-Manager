@tool
class_name AceLogLevelInfo extends Object

var folder_arr: Array[String] = []
var file_arr: Array[String] = []

func _init(folders: Array[String] = [], files: Array[String] = []) -> void:
	folder_arr.append_array(folders)
	file_arr.append_array(files)

func _to_string() -> String:
	return "[folder_arr=%s, file_arr=%s]" % [folder_arr, file_arr]

