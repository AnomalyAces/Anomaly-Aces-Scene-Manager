class_name AceDeserializeResult extends Object

var data: Variant
var error: Error

func _to_string() -> String:
    return "AceDeserializeResult[data:%s, error: %s]" % [str(data), str(error)]
