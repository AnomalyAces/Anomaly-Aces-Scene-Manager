@tool
extends Control

const ACE_PLUGIN_MANAGER_SCENE = "res://addons/anomalyAcesAddonManager/Scenes/AddonUpdater/AcePluginManager.tscn"

@onready var back_button = $VBoxContainer/Header/HBox/BackButton
@onready var refresh_button = $VBoxContainer/Header/HBox/Controls/RefreshButton
@onready var manager_container = $VBoxContainer/ManagerContainer

var plugin_ref = null
var plugin_manager = null
var _last_detected_est_scale: float = 1.0

func initialize_view(p_ref, _extra_data) -> void:
	plugin_ref = p_ref

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	
	_last_detected_est_scale = AddonManagerUtil.get_estimated_scale()
	get_tree().root.size_changed.connect(_on_dpi_or_resolution_changed)
	
	var estimated_scale = _last_detected_est_scale
	var applied_scale = AddonManagerUtil.get_applied_scale()
	
	# Load and scale the back button icon
	var back_tex = load("res://addons/anomalyAcesAddonManager/Icons/AceAddonBack.svg")
	if back_tex:
		var icon_size = int(round((16 + 12) * estimated_scale))
		back_button.icon = AddonManagerUtil.scale_svg_icon(back_tex, icon_size)
	
	# Scale the header region by the estimated resolution scale factor
	AddonManagerUtil.apply_editor_scaling($VBoxContainer/Header, estimated_scale)
	
	if Engine.is_editor_hint() and plugin_ref != null:
		# Add manual scaling control UI to header controls
		var controls = $VBoxContainer/Header/HBox/Controls
		AddonManagerUtil.add_scale_ui_to_header(controls, self)
		
		# Instantiate the migrated AcePluginManager at runtime directly
		var scene_res = load(ACE_PLUGIN_MANAGER_SCENE)
		if scene_res:
			plugin_manager = scene_res.instantiate()
			plugin_manager.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			plugin_manager.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			manager_container.add_child(plugin_manager)
			
			# Pass editor interface
			if plugin_manager.has_method("assignEditorInterface"):
				plugin_manager.assignEditorInterface(EditorInterface)
			
			# Trigger the initial addon load
			_on_refresh_pressed()

func _exit_tree() -> void:
	var root = get_tree().root if get_tree() else null
	if root and root.size_changed.is_connected(_on_dpi_or_resolution_changed):
		root.size_changed.disconnect(_on_dpi_or_resolution_changed)

func _on_dpi_or_resolution_changed() -> void:
	var new_est = AddonManagerUtil.get_estimated_scale()
	if new_est != _last_detected_est_scale:
		_last_detected_est_scale = new_est
		if plugin_ref and plugin_ref.has_method("reload_current_view"):
			plugin_ref.reload_current_view()



func _on_back_pressed() -> void:
	if plugin_ref:
		plugin_ref.switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn")

func _on_refresh_pressed() -> void:
	if plugin_manager and plugin_manager.has_method("getAddons"):
		plugin_manager.getAddons()
	elif plugin_manager and "main_view" in plugin_manager and plugin_manager.main_view != null:
		plugin_manager.main_view.getAddons()
