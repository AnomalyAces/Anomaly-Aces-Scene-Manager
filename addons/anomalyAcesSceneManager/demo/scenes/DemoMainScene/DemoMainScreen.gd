@tool
class_name DemoMainScreen extends Control

## Main screen for the Ace Scene Manager demo project.
## Demonstrates scene transitions using registered scene keys, custom loading screens, and scene data transfer.

@onready var status_label: Label = $VBoxContainer/StatusLabel


func _ready() -> void:
	AceSceneManagerDemoSettings.setup_demo_settings()
	if status_label != null:
		status_label.text = "Status: Ready in Demo Main Screen"


func _on_fade_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Fade..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 100, "level": 3, "transition": "Fade"})
	AceSceneManager.load_scene("DemoDetail", "Fade", data)


func _on_circle_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Circle Wipe..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 250, "level": 5, "transition": "Circle"})
	AceSceneManager.load_scene("DemoDetail", "Circle", data)


func _on_custom_loading_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Custom Loading Screen..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerCustom", "mode": "BossFight", "transition": "CustomLoading"})
	AceSceneManager.load_scene("DemoDetail", "CustomLoading", data)


func _on_shader_fade_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Shader Fade..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 100, "level": 3, "transition": "ShaderFade"})
	AceSceneManager.load_scene("DemoDetail", "ShaderFade", data)