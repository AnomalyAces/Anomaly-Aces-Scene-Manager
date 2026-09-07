@tool
class_name DemoDetailScreen extends Control

## Detail screen for the Ace Scene Manager demo project.
## Receives AceSceneData transferred from the previous scene and displays it.

@export var scene_data: Variant = null

var active_transition: String = "Fade"

@onready var data_label: Label = $VBoxContainer/DataLabel


func _ready() -> void:
	_update_display()


func set_scene_data(p_data: Variant) -> void:
	scene_data = p_data
	_update_display()


func _update_display() -> void:
	if data_label == null:
		return
	if scene_data is AceSceneData:
		var sd: AceSceneData = scene_data as AceSceneData
		active_transition = String(sd.get_value("transition", "Fade"))
		data_label.text = "Received Data:\n%s" % str(sd.data)
	elif scene_data != null:
		data_label.text = "Received Data: %s" % str(scene_data)
	else:
		data_label.text = "No scene data received."


func _on_back_button_pressed() -> void:
	AceSceneManager.load_scene("DemoMain", active_transition)
