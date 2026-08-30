@tool
extends Control

@onready var back_button: Button = $VBoxContainer/Header/HBox/BackButton
@onready var path_label: Label = $VBoxContainer/Header/HBox/PathLabel
@onready var sub_viewport: SubViewport = $VBoxContainer/ViewportContainer/SubViewport

var plugin_ref = null
var editor_target_scene: String = ""

func initialize_view(p_ref, target_path: String):
	plugin_ref = p_ref
	editor_target_scene = target_path

func _ready() -> void:
	# Connect the back button pressed signal
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	
	if Engine.is_editor_hint() and plugin_ref != null:
		var scale = AddonManagerUtil.get_applied_scale()
		AddonManagerUtil.apply_editor_scaling(self, scale)
	
	# Determine target scene
	var target_scene = ""
	if Engine.is_editor_hint():
		target_scene = editor_target_scene
	else:
		target_scene = AddonPreviewerOverlay.target_demo_scene
		
	# Fallback check
	if target_scene == "":
		if FileAccess.file_exists("res://.preview_target.txt"):
			var file = FileAccess.open("res://.preview_target.txt", FileAccess.READ)
			if file:
				target_scene = file.get_as_text().strip_edges()
				file.close()
				DirAccess.remove_absolute("res://.preview_target.txt")
				
	if target_scene == "":
		push_error("No target demo scene specified. Returning to main menu.")
		_go_back()
		return
		
	path_label.text = "Previewing: " + target_scene
	
	# Load and instantiate the scene inside the SubViewport
	var scene_res = load(target_scene)
	if scene_res:
		var scene_instance = scene_res.instantiate()
		sub_viewport.add_child(scene_instance)
		
		# If the instance is a Control, ensure it fills the SubViewport if anchors are set
		if scene_instance is Control:
			scene_instance.anchors_preset = Control.PRESET_FULL_RECT
	else:
		push_error("Failed to load demo scene: " + target_scene)
		path_label.text = "Error: Failed to load " + target_scene
		path_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))

func _go_back() -> void:
	if Engine.is_editor_hint() and plugin_ref != null:
		plugin_ref.switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn")
	else:
		if AddonPreviewerOverlay.target_demo_scene == "":
			get_tree().quit()
		else:
			AddonPreviewerOverlay.target_demo_scene = ""
			get_tree().change_scene_to_file("res://addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn")

func _on_back_pressed() -> void:
	_go_back()


