@tool
class_name AceSettingConfig extends Object

var name: String
var type: Variant.Type
var hint: PropertyHint
var hint_string: String
var value: Variant

func _init(nme, typ, default_value = null, hnt = PropertyHint.PROPERTY_HINT_NONE, hnt_str = "" ) -> void:
	name = nme
	type = typ
	hint = hnt
	hint_string = hnt_str
	value = default_value

func _to_string() -> String:
	return "[name=%s, type=%s, hint=%s, hint_string=%s, value=%s ]" % [name, type, hint, hint_string, value]