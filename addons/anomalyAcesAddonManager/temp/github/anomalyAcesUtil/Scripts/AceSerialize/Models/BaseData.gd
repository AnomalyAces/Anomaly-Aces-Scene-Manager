class_name BaseData extends Node

func _get_properties() -> Array[String]:
	var properties: Array[String] 
	properties.assign( get_script().get_script_property_list().map(
		func(prop) -> String: return prop.name 
	))
	return properties
