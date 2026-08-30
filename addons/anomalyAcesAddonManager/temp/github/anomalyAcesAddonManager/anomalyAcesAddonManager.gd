@tool
extends EditorPlugin

var main_screen_wrapper: MarginContainer
var current_view: Control
var current_view_path: String = ""
var current_extra_data = null

func _enter_tree() -> void:
	# Enable all plugins in res://addons/
	AddonManagerUtil.enable_addons()

	#Intialize the AceLog settings
	AceLog.initialize_settings()

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
