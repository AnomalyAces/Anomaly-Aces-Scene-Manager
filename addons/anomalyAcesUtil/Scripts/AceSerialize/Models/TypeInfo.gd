class_name TypedInfo extends Object
	
var is_built_in: bool
var array_script: Script #non-built in typed arrays
var dict_obj_script: Script #non-built in typed dictionaries
var built_in_type: int = -1
var children_processed: bool = false

func _to_string() -> String:
    return "TypedInfo[ is_built_in: %s, array_script: %s, dict_obj_script: %s, built_in_type: %s" % [
		is_built_in, 
		array_script.get_path() if array_script else null,
		dict_obj_script.get_path() if dict_obj_script else null,
		built_in_type
	] 
