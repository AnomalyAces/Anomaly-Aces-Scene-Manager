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


func _on_horizontal_sweep_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Horizontal Sweep..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 100, "level": 3, "transition": "HorizontalSweep"})
	AceSceneManager.load_scene("DemoDetail", "HorizontalSweep", data)

func _on_vertical_sweep_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Vertical Sweep..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 100, "level": 3, "transition": "VerticalSweep"})
	AceSceneManager.load_scene("DemoDetail", "VerticalSweep", data)

func _on_diagonal_sweep_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Diagonal Sweep..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 100, "level": 3, "transition": "DiagonalSweep"})
	AceSceneManager.load_scene("DemoDetail", "DiagonalSweep", data)

func _on_tile_square_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Tile Square..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 100, "level": 3, "transition": "TileSquare"})
	AceSceneManager.load_scene("DemoDetail", "TileSquare", data)

func _on_tile_diamond_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Tile Diamond..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 100, "level": 3, "transition": "TileDiamond"})
	AceSceneManager.load_scene("DemoDetail", "TileDiamond", data)

func _on_tile_diamond_sweep_button_pressed() -> void:
	if status_label != null:
		status_label.text = "Status: Transitioning with Tile Diamond Sweep..."
	var data: AceSceneData = AceSceneData.new({"player": "PlayerOne", "score": 100, "level": 3, "transition": "TileDiamondSweep"})
	AceSceneManager.load_scene("DemoDetail", "TileDiamondSweep", data)