@tool
extends EditorPlugin

var main_screen_wrapper: MarginContainer
var current_view: Control
var current_view_path: String = ""
var current_extra_data = null

func _enter_tree() -> void:
	# Check for missing dependencies first
	var missing_deps = []
	if not ResourceLoader.exists("res://addons/anomalyAcesLog/scripts/AceLog.gd"):
		missing_deps.append("anomalyAcesLog")
	if not ResourceLoader.exists("res://addons/anomalyAcesUtil/Scripts/AceFileUtil/AceFileUtil.gd"):
		missing_deps.append("anomalyAcesUtil")
	if not ResourceLoader.exists("res://addons/anomalyAcesTable/Scripts/Table/AceTableManager.gd"):
		missing_deps.append("anomalyAcesTable")

	if missing_deps.size() > 0:
		var err_msg = "Ace Addon Manager: Missing required companion plugins: %s. " % [missing_deps]
		err_msg += "Please run the bootstrap script (manage_addons bootstrap) before enabling the plugin."
		printerr(err_msg)
		push_error(err_msg)
		if Engine.is_editor_hint():
			EditorInterface.call_deferred("set_plugin_enabled", "anomalyAcesAddonManager", false)
		return

	# Enable all plugins in res://addons/ if the utility class is available
	var util_path = "res://addons/anomalyAcesAddonManager/Scripts/AddonManagerUtil/AddonManagerUtil.gd"
	if ResourceLoader.exists(util_path):
		var util = load(util_path)
		if util:
			util.enable_addons()

	# Initialize the AceLog settings if the dependency is present
	var ace_log_path = "res://addons/anomalyAcesLog/scripts/AceLog.gd"
	if ResourceLoader.exists(ace_log_path):
		var ace_log = load(ace_log_path)
		if ace_log:
			ace_log.initialize_settings()

	#Initialize the main screen wrapper
	main_screen_wrapper = MarginContainer.new()
	main_screen_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_screen_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Add the wrapper to the editor's main viewport
	EditorInterface.get_editor_main_screen().add_child(main_screen_wrapper)
	
	# Load the initial dashboard view (Addon Previewer)
	switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonPreviewer/main.tscn")
	
	_make_visible(false)

func _exit_tree() -> void:
	if main_screen_wrapper:
		main_screen_wrapper.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if main_screen_wrapper:
		main_screen_wrapper.visible = visible

func _get_plugin_name() -> String:
	return "Ace Addon Manager"

func _get_plugin_icon() -> Texture2D:
	var base_tex = preload("res://addons/anomalyAcesAddonManager/AceAddonManager.svg")
	if base_tex:
		var img = base_tex.get_image()
		if img:
			var scale = 1.0
			if Engine.is_editor_hint():
				scale = EditorInterface.get_editor_scale()
			var target_size = int(round(16 * scale))
			img.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
			return ImageTexture.create_from_image(img)
	return base_tex

func switch_to_view(scene_path: String, extra_data = null) -> void:
	current_view_path = scene_path
	current_extra_data = extra_data
	
	# Clear current view
	if current_view:
		main_screen_wrapper.remove_child(current_view)
		current_view.queue_free()
		current_view = null
		
	var scene_res = load(scene_path)
	if scene_res:
		current_view = scene_res.instantiate()
		current_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		current_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Set up custom parameters before ready
		if current_view.has_method("initialize_view"):
			current_view.initialize_view(self, extra_data)
			
		main_screen_wrapper.add_child(current_view)

func reload_current_view() -> void:
	if current_view_path != "":
		switch_to_view(current_view_path, current_extra_data)
