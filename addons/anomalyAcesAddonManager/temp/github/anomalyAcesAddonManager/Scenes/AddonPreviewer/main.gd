@tool
extends Control

const ADDON_CARD_SCENE = preload("res://addons/anomalyAcesAddonManager/Scenes/AddonCard/addon_card.tscn")

@onready var grid_container = $VBoxContainer/ContentMargins/ScrollContainer/GridContainer
@onready var search_input = $VBoxContainer/Header/HBox/Controls/SearchInput
@onready var addon_count_label = $VBoxContainer/Header/HBox/Controls/AddonCountLabel
@onready var refresh_button = $VBoxContainer/Header/HBox/Controls/RefreshButton
@onready var ignore_button = $VBoxContainer/Header/HBox/Controls/IgnoreButton
@onready var updater_button = $VBoxContainer/Header/HBox/Controls/UpdaterButton
@onready var manager_deps_button = $VBoxContainer/Header/HBox/Controls/ManagerDepsButton
@onready var scroll_container = $VBoxContainer/ContentMargins/ScrollContainer

# Cache list of addon details: { name, version, author, description, demos, card_instance }
var addons_list: Array = []
var plugin_ref = null
var _last_detected_est_scale: float = 1.0

func initialize_view(p_ref, extra_data):
	plugin_ref = p_ref

func _ready():
	_last_detected_est_scale = AddonManagerUtil.get_estimated_scale()
	get_tree().root.size_changed.connect(_on_dpi_or_resolution_changed)
	
	var estimated_scale = _last_detected_est_scale
	var applied_scale = AddonManagerUtil.get_applied_scale()
	
	# Scale the header region by the estimated resolution scale factor
	AddonManagerUtil.apply_editor_scaling($VBoxContainer/Header, estimated_scale)
	
	# Scale the content margins by the applied custom scale factor
	AddonManagerUtil.apply_editor_scaling($VBoxContainer/ContentMargins, applied_scale)
	
	if Engine.is_editor_hint() and plugin_ref != null:
		# Add manual scaling control UI to header controls
		var controls = $VBoxContainer/Header/HBox/Controls
		AddonManagerUtil.add_scale_ui_to_header(controls, self)
		
	# Style styling setup or connect signals
	search_input.text_changed.connect(_on_search_changed)
	refresh_button.pressed.connect(scan_addons)
	ignore_button.pressed.connect(_on_ignore_button_pressed)
	updater_button.pressed.connect(_on_updater_button_pressed)
	manager_deps_button.pressed.connect(_on_manager_deps_pressed)
	
	scroll_container.resized.connect(_on_scroll_container_resized)
	_on_scroll_container_resized()
	
	_setup_button_icons(applied_scale)
	
	scan_addons()

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



func _on_scroll_container_resized():
	var scale = AddonManagerUtil.get_applied_scale()
	var card_min_width = 350.0 * scale
	var h_sep = 20.0 * scale
	var available_width = scroll_container.size.x
	
	# Account for vertical scrollbar
	available_width -= 20.0 * scale
	
	if available_width > 0:
		var cols = int((available_width + h_sep) / (card_min_width + h_sep))
		grid_container.columns = max(1, cols)

func scan_addons():
	# Clear existing cards
	for child in grid_container.get_children():
		child.queue_free()
	addons_list.clear()
	
	var enabled_plugins = get_enabled_plugins()
	var ignored_folders = load_ignored_folders()
	
	var addons_path = "res://addons"
	if not DirAccess.dir_exists_absolute(addons_path):
		DirAccess.make_dir_absolute(addons_path)
	
	var dir = DirAccess.open(addons_path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with(".") and folder_name != "anomalyAcesAddonManager" and not folder_name in ignored_folders:
				var addon_dir_path = addons_path + "/" + folder_name
				var config_path = addon_dir_path + "/plugin.cfg"
				
				if FileAccess.file_exists(config_path):
					parse_addon(folder_name, config_path, addon_dir_path, enabled_plugins)
					
			folder_name = dir.get_next()
			
	# Update UI count
	addon_count_label.text = str(addons_list.size()) + " Addon(s) Detected"
	
	# Render cards
	render_addon_cards()

func parse_addon(folder_name: String, config_path: String, addon_dir_path: String, enabled_plugins: PackedStringArray):
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	var addon_name = folder_name
	var addon_version = "0.0.0"
	var addon_author = "Unknown"
	var addon_desc = ""
	
	if err == OK:
		addon_name = config.get_value("plugin", "name", folder_name)
		addon_version = config.get_value("plugin", "version", "0.0.0")
		addon_author = config.get_value("plugin", "author", "Unknown")
		addon_desc = config.get_value("plugin", "description", "")
		
	# Search recursively for demo scenes
	var demos = find_demo_scenes(addon_dir_path)
	
	var plugin_path = "res://addons/" + folder_name + "/plugin.cfg"
	var is_enabled = plugin_path in enabled_plugins
	
	addons_list.append({
		"folder": folder_name,
		"name": addon_name,
		"version": addon_version,
		"author": addon_author,
		"description": addon_desc,
		"demos": demos,
		"is_enabled": is_enabled,
		"plugin_path": plugin_path,
		"card": null
	})

func find_demo_scenes(path: String) -> Array:
	var list = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					list.append_array(find_demo_scenes(path + "/" + file_name))
			else:
				var lower_name = file_name.to_lower()
				if file_name.ends_with(".tscn") and (
					lower_name.contains("demo") or 
					lower_name.contains("example") or 
					lower_name.contains("test") or 
					lower_name.contains("preview")
				):
					list.append(path + "/" + file_name)
			file_name = dir.get_next()
	return list

func render_addon_cards():
	var scale = AddonManagerUtil.get_applied_scale()
	for item in addons_list:
		var card = ADDON_CARD_SCENE.instantiate()
		grid_container.add_child(card)
		card.set_addon_details(
			item["name"], 
			item["version"], 
			item["author"], 
			item["description"], 
			item["demos"],
			item["is_enabled"],
			item["plugin_path"],
			scale,
			item["folder"]
		)
		card.plugin_toggled.connect(_on_plugin_toggled)
		card.run_demo_requested.connect(_on_run_demo_requested)
		card.open_dependency_editor_requested.connect(_on_open_dependency_editor)
		item["card"] = card

func _on_run_demo_requested(demo_path: String):
	if Engine.is_editor_hint():
		var file = FileAccess.open("res://.preview_target.txt", FileAccess.WRITE)
		if file:
			file.store_string(demo_path)
			file.close()
		EditorInterface.play_custom_scene("res://addons/anomalyAcesAddonManager/Scenes/DemoPreviewer/demo_previewer.tscn")
	else:
		AddonPreviewerOverlay.target_demo_scene = demo_path
		get_tree().change_scene_to_file("res://addons/anomalyAcesAddonManager/Scenes/DemoPreviewer/demo_previewer.tscn")

func _on_updater_button_pressed():
	if plugin_ref:
		plugin_ref.switch_to_view("res://addons/anomalyAcesAddonManager/Scenes/AddonUpdater/addon_updater.tscn")

func _on_manager_deps_pressed():
	_on_open_dependency_editor("anomalyAcesAddonManager")

func _on_open_dependency_editor(folder_name: String):
	if plugin_ref:
		var addon_path = "res://addons/" + folder_name
		plugin_ref.switch_to_view(
			"res://addons/anomalyAcesAddonManager/Scenes/AddonDependencyEditor/addon_dependency_editor.tscn",
			{ "folder_name": folder_name, "addon_path": addon_path }
		)

func get_enabled_plugins() -> PackedStringArray:
	if Engine.is_editor_hint():
		var enabled_list = PackedStringArray()
		var addons_path = "res://addons"
		var dir = DirAccess.open(addons_path)
		if dir:
			dir.list_dir_begin()
			var folder_name = dir.get_next()
			while folder_name != "":
				if dir.current_is_dir() and not folder_name.begins_with("."):
					if EditorInterface.is_plugin_enabled(folder_name):
						enabled_list.append("res://addons/" + folder_name + "/plugin.cfg")
				folder_name = dir.get_next()
		return enabled_list
	else:
		if not FileAccess.file_exists("res://project.godot"):
			return PackedStringArray()
		var config = ConfigFile.new()
		var err = config.load("res://project.godot")
		if err == OK:
			return config.get_value("editor_plugins", "enabled", PackedStringArray())
		return PackedStringArray()

func _on_plugin_toggled(plugin_path: String, enabled: bool):
	var folder_name = plugin_path.get_slice("/", 3)
	
	if Engine.is_editor_hint():
		EditorInterface.set_plugin_enabled(folder_name, enabled)
		print("Toggled plugin via EditorInterface: ", folder_name, " -> ", enabled)
	else:
		var config = ConfigFile.new()
		var err = config.load("res://project.godot")
		if err == OK:
			var plugins = config.get_value("editor_plugins", "enabled", PackedStringArray())
			var plugin_list = Array(plugins)
			var has_plugin = plugin_path in plugin_list
			
			if enabled and not has_plugin:
				plugin_list.append(plugin_path)
			elif not enabled and has_plugin:
				plugin_list.erase(plugin_path)
				
			var new_plugins = PackedStringArray(plugin_list)
			config.set_value("editor_plugins", "enabled", new_plugins)
			config.save("res://project.godot")
			
			# Also update ProjectSettings memory so Godot runtime is aware and save settings
			ProjectSettings.set_setting("editor_plugins/enabled", new_plugins)
			ProjectSettings.save()

func _on_search_changed(new_text: String):
	var filter = new_text.strip_edges().to_lower()
	for item in addons_list:
		var card = item["card"]
		if card:
			if filter == "":
				card.visible = true
			else:
				var match_found = (
					item["name"].to_lower().contains(filter) or
					item["description"].to_lower().contains(filter) or
					item["author"].to_lower().contains(filter) or
					item["folder"].to_lower().contains(filter)
				)
				card.visible = match_found

func _setup_button_icons(scale: float) -> void:
	var icon_size = int(round((16 + 12) * scale))
	
	# 1. Rescan button icon
	var rescan_tex = load("res://addons/anomalyAcesAddonManager/Icons/Rescan.svg")
	if rescan_tex:
		refresh_button.icon = AddonManagerUtil.scale_svg_icon(rescan_tex, icon_size)
		
	# 2. Manager Dependencies button icon
	var deps_tex = load("res://addons/anomalyAcesAddonManager/Icons/ManagerDependencies.svg")
	if deps_tex:
		manager_deps_button.icon = AddonManagerUtil.scale_svg_icon(deps_tex, icon_size)
		if manager_deps_button.text.begins_with("⚙ "):
			manager_deps_button.text = manager_deps_button.text.substr(2)
		elif manager_deps_button.text.begins_with("⚙"):
			manager_deps_button.text = manager_deps_button.text.substr(1)

	# 3. Addon Updater button icon
	var updater_tex = load("res://addons/anomalyAcesAddonManager/Icons/AddonUpdater.svg")
	if updater_tex:
		updater_button.icon = AddonManagerUtil.scale_svg_icon(updater_tex, icon_size)
		if updater_button.text.ends_with("  →"):
			updater_button.text = updater_button.text.substr(0, updater_button.text.length() - 3)
		elif updater_button.text.ends_with(" →"):
			updater_button.text = updater_button.text.substr(0, updater_button.text.length() - 2)

	# 4. Ignore List button icon
	if Engine.is_editor_hint():
		var ignore_tex = EditorInterface.get_editor_theme().get_icon("VisibilityHidden", "EditorIcons")
		if ignore_tex:
			ignore_button.icon = AddonManagerUtil.scale_svg_icon(ignore_tex, icon_size)

func load_ignored_folders() -> Array[String]:
	var ignored: Array[String] = []
	var path = "res://addons/.addonignore"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			while not file.eof_reached():
				var line = file.get_line().strip_edges()
				if line != "" and not line.begins_with("#"):
					ignored.append(line)
			file.close()
	return ignored

func save_ignored_folders(ignored: Array[String]) -> void:
	var path = "res://addons/.addonignore"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_line("# Addon Previewer Ignore List")
		file.store_line("# Edit this file manually or via the UI to hide subfolders from the addon previewer")
		for folder in ignored:
			file.store_line(folder)
		file.close()

func _on_ignore_button_pressed() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Ignore List"
	
	# ScrollContainer for list
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	var label = Label.new()
	label.text = "Select folders to ignore (hide from Previewer):"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)
	
	var ignored_list = load_ignored_folders()
	var checkboxes = {}
	
	var dir = DirAccess.open("res://addons")
	if dir:
		dir.list_dir_begin()
		var name = dir.get_next()
		while name != "":
			if dir.current_is_dir() and not name.begins_with(".") and name != "anomalyAcesAddonManager":
				var checkbox = CheckBox.new()
				checkbox.text = name
				checkbox.button_pressed = name in ignored_list
				vbox.add_child(checkbox)
				checkboxes[name] = checkbox
			name = dir.get_next()
		dir.list_dir_end()
	
	var dialog_vbox = VBoxContainer.new()
	dialog_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_vbox.add_theme_constant_override("separation", 10)
	dialog_vbox.add_child(scroll)
	
	var delete_checkbox = CheckBox.new()
	delete_checkbox.text = "Also remove folder/symlink from addons folder"
	delete_checkbox.button_pressed = false
	dialog_vbox.add_child(delete_checkbox)
	
	var margins = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 16)
	margins.add_theme_constant_override("margin_top", 16)
	margins.add_theme_constant_override("margin_right", 16)
	margins.add_theme_constant_override("margin_bottom", 16)
	margins.add_child(dialog_vbox)
	dialog.add_child(margins)
	
	add_child(dialog)
	
	var scale = AddonManagerUtil.get_applied_scale()
	dialog.min_size = Vector2(400, 360) * scale
	scroll.custom_minimum_size = Vector2(360, 200) * scale
	
	# Connect confirm
	dialog.confirmed.connect(func():
		var new_ignored: Array[String] = []
		var to_delete: Array[String] = []
		for folder_name in checkboxes.keys():
			if checkboxes[folder_name].button_pressed:
				new_ignored.append(folder_name)
				if delete_checkbox.button_pressed and DirAccess.dir_exists_absolute("res://addons/" + folder_name):
					to_delete.append(folder_name)
		
		if to_delete.size() > 0:
			var confirm_del = ConfirmationDialog.new()
			confirm_del.title = "Warning: Permanent Deletion"
			
			var warn_label = Label.new()
			warn_label.text = "Are you sure you want to permanently remove the folder/symlink for the following addon(s) from res://addons/? This action cannot be undone:\n\n" + ", ".join(to_delete)
			warn_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			
			var warn_margins = MarginContainer.new()
			warn_margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			warn_margins.add_theme_constant_override("margin_left", 16)
			warn_margins.add_theme_constant_override("margin_top", 16)
			warn_margins.add_theme_constant_override("margin_right", 16)
			warn_margins.add_theme_constant_override("margin_bottom", 16)
			warn_margins.add_child(warn_label)
			confirm_del.add_child(warn_margins)
			
			add_child(confirm_del)
			confirm_del.min_size = Vector2(450, 200) * scale
			
			confirm_del.confirmed.connect(func():
				for folder_name in to_delete:
					_remove_addon_folder(folder_name)
				save_ignored_folders(new_ignored)
				scan_addons()
				confirm_del.queue_free()
			)
			confirm_del.canceled.connect(func():
				confirm_del.queue_free()
			)
			confirm_del.popup_centered()
		else:
			save_ignored_folders(new_ignored)
			scan_addons()
			
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	dialog.popup_centered()

func _remove_addon_folder(folder_name: String) -> void:
	var path = "res://addons/" + folder_name
	var global_path = ProjectSettings.globalize_path(path).replace("/", "\\")
	
	AceLog.printLog(["Removing addon folder/symlink: ", global_path], AceLog.LOG_LEVEL.INFO)
	
	var output = []
	# On Windows, rmdir /s /q removes directory symlinks/junctions safely without deleting contents of target folder.
	var exit_code = OS.execute("cmd.exe", ["/c", "rmdir", "/s", "/q", global_path], output)
	if exit_code == 0:
		AceLog.printLog(["Successfully removed folder/symlink: ", folder_name], AceLog.LOG_LEVEL.INFO)
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().scan()
	else:
		AceLog.printLog(["Failed to remove folder/symlink: ", folder_name, " Exit code: ", exit_code, " Output: ", output], AceLog.LOG_LEVEL.ERROR)
