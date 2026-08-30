@tool
class_name _AceTableTextLink extends Object

var link: String
var text: String
var color: Color = Color.WHITE

func _init(lnk: String, txt: String, clr: Color = Color.WHITE) -> void:
	self.link = lnk
	self.text = txt
	self.color = clr

static func from_dict(dict: Dictionary) -> _AceTableTextLink:
	return _AceTableTextLink.new(dict.link, dict.text, dict.color if dict.has("color") else Color.WHITE)
