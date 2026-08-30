@tool
class_name AcePluginMainView extends Control

# @onready var container: VBoxContainer = $VBoxContainer
@onready var loadingView: LoadingView = %LoadingView
@onready var addonTablePlugin: AceTablePlugin = %AddonTablePlugin
@onready var conflictTablePlugin: AceTablePlugin = %ConflictTablePlugin
@onready var tableTtile: Label = %TableTitle

##Signals
signal open_install_view(addons: Array, config_file: ConfigFile)
signal open_github_pat_view()

var rrm: GitHubManager

var _editor_interface: EditorInterface

var _addon_table: _AceTable
var _conflict_table: _AceTable

var _addons: Array[RemoteRepoObject] = []
var _selected_addons: Array[RemoteRepoObject] = []
var _conflicts: Array[RemoteRepoConflict] = []
var _selected_conflicts: Array[RemoteRepoConflict] = []
var _editor_scale: float = 1.0
var _table_scale: float = 1.0

func _ready() -> void:
	rrm = GitHubManager.new(self, _editor_interface)
	# _createTable()
	# for i in randi_range(1,3):
	# 	_add_addonInfo()
	rrm.addons_downloaded.connect(_on_addon_downloads_completed)
	rrm.conflicts_found.connect(_on_conflicts_found)
	rrm.addons_install_ready.connect(_on_addons_install_ready)
	rrm.addon_updates_processed.connect(_on_addon_updates_processed)

	if loadingView.animationPlayer.current_animation != "Loading":
		loadingView.playAnimation()
	
	if not Engine.is_editor_hint():
		getAddons()


	

func getAddons() -> void:
	_setLoadingViewSize()
	loadingView.visible = true
	tableTtile.visible = false
	addonTablePlugin.visible = false
	conflictTablePlugin.visible = false
	rrm.getAddonsFromRemoteRepo()



func installSelectedUpdates() -> void:
	# _setLoadingViewSize()
	# loadingView.visible = true
	# tableTtile.visible = false
	# addonTablePlugin.visible = false
	# conflictTablePlugin.visible = false
	# rrm.getAddonUpdatesFromRemoteRepo(_selected_addons, true)
	open_install_view.emit(_selected_addons, rrm.getConfigFile())

func selectAvailableUpdates() -> void:
	var updatable_addons = _addons.filter(func (addon: RemoteRepoObject): return addon.metadata.status == RemoteRepoConstants.STATUS.UPDATE_AVAILABLE)

	var tableData: Array[Dictionary] = _addon_table.get_rows()

	for data in tableData:
		if updatable_addons.find_custom(func (addon: RemoteRepoObject): return addon.repo == data["repo"]) != -1:
			data["selected"] = true

	AceTableManager.setTableData(_addon_table, tableData)
	# _on_addon_table_selection(tableData)

func updateAddons() -> void:
	_setLoadingViewSize()
	loadingView.visible = true
	tableTtile.visible = false
	addonTablePlugin.visible = false
	conflictTablePlugin.visible = false
	rrm.updateAddonsFromRemoteRepo()

##### Signal Callbacks #####
func _on_addon_downloads_completed(addons: Array[RemoteRepoObject], isUpdate: bool) -> void:
	if isUpdate:
		AceLog.printLog(["Add-on updates downloaded from Remote Repo will process with another signal", JSON.parse_string(AceSerialize.serialize_array(addons))], AceLog.LOG_LEVEL.DEBUG)
		return
	
	loadingView.visible = false
	AceLog.printLog(["All Addons Downloaded from Remote Repo", JSON.parse_string(AceSerialize.serialize_array(addons))], AceLog.LOG_LEVEL.INFO)
	tableTtile.text = "Add-ons"
	tableTtile.visible = true
	addonTablePlugin.visible = true
	conflictTablePlugin.visible = false
	
	if _addon_table != null:
		var tableData: Array[Dictionary] = _normalize_table_data(_createAddonTableData(addons))
		AceTableManager.setTableData(_addon_table, tableData)
	else:
		_createAddonTable(addons)
	
	_addons = addons

func _on_conflicts_found(conflicting_addons: Array[RemoteRepoConflict]) -> void:
	loadingView.visible = false
	AceLog.printLog(["Conflicting addons found:", JSON.parse_string(AceSerialize.serialize_array(conflicting_addons))], AceLog.LOG_LEVEL.INFO)
	tableTtile.text = "Conflicts"
	tableTtile.visible = true
	addonTablePlugin.visible = false
	conflictTablePlugin.visible = true

	if _conflict_table != null:
		var tableData: Array[Dictionary] = _createConflictTableData(conflicting_addons)
		AceTableManager.setTableData(_conflict_table, tableData)
	else:
		_createConflictTable(conflicting_addons)
	
	_conflicts = conflicting_addons

func _on_addons_install_ready(addons: Array[RemoteRepoObject]) -> void:
	loadingView.visible = false
	AceLog.printLog(["Addons are ready for installation", JSON.parse_string(AceSerialize.serialize_array(addons))], AceLog.LOG_LEVEL.INFO)
	_merge_updated_addons(addons)
	tableTtile.visible = true
	addonTablePlugin.visible = true
	conflictTablePlugin.visible = false
	
	if _addon_table != null:
		var tableData: Array[Dictionary] = _normalize_table_data(_createAddonTableData(_addons))
		AceTableManager.setTableData(_addon_table, tableData)
	else:
		_createAddonTable(_addons)

func _on_addon_updates_processed(addons: Array[RemoteRepoObject]) -> void:
	loadingView.visible = false
	AceLog.printLog(["Add-on updates processed from Remote Repo", JSON.parse_string(AceSerialize.serialize_array(addons))], AceLog.LOG_LEVEL.INFO)
	_merge_updated_addons(addons)
	tableTtile.visible = true
	addonTablePlugin.visible = true
	conflictTablePlugin.visible = false

	if _addon_table != null:
		var tableData: Array[Dictionary] = _normalize_table_data(_createAddonTableData(_addons))
		AceTableManager.setTableData(_addon_table, tableData)
	else:
		_createAddonTable(_addons)
	
func _on_conflict_table_selection(_table_data: Array[Dictionary]) -> void:
	var _selected_table_data: Array[Dictionary] = _table_data.filter(func (dict: Dictionary): return dict["selected"])
	AceLog.printLog(["Conflict Table Selection: " ,_selected_table_data], AceLog.LOG_LEVEL.DEBUG)
	var deserializeRes: AceDeserializeResult = AceSerialize.deserialize(JSON.stringify(_selected_table_data), RemoteRepoConflict)
	if deserializeRes.error == OK:
		_selected_conflicts.assign(deserializeRes.data)

func _on_addon_table_selection(_table_data: Array[Dictionary]) -> void:
	var _selected_table_data: Array[Dictionary] = _table_data.filter(func (dict: Dictionary): return dict["selected"])
	AceLog.printLog(["Add-on Table Selection: ",_selected_table_data], AceLog.LOG_LEVEL.DEBUG)
	var addons_to_add: Array[RemoteRepoObject] = _addons.filter(func (addon: RemoteRepoObject): return AceArrayUtil.findFirst(_selected_table_data, func (dict: Dictionary): return dict["repo"] == addon.repo ) != null)
	_selected_addons.assign(addons_to_add)

func _on_reload_pressed() -> void:
	getAddons()


func _on_install_pressed() -> void:
	installSelectedUpdates()

func _on_select_pressed() -> void:
	selectAvailableUpdates()

func _on_github_pat_pressed() -> void:
	open_github_pat_view.emit()


#############################

func _setLoadingViewSize() -> void:
	# Set the loading view to be a square based on the smaller dimension of the current view size
	var view_size: Vector2 = size
	AceLog.printLog(["Current view size: %s" % view_size], AceLog.LOG_LEVEL.INFO)
	var max_dimension: float = max(view_size.x, view_size.y)
	# Make the custom minimum size x 1/4 of maximum dimension of the screen size and y 70% of the x dimension to account for typical loading animation aspect ratio
	var x_dim: float = max_dimension * .25
	var y_dim: float = x_dim * .7
	# Make the custom minimum size 1/4 of the screen size
	var loading_size: Vector2 = Vector2(x_dim, y_dim)
	AceLog.printLog(["Loading view size: %s" % loading_size], AceLog.LOG_LEVEL.INFO)
	
	loadingView.custom_minimum_size = loading_size

func _createConflictTable(conflics: Array[RemoteRepoConflict]) -> void:
	# 
	# columns: Addon, Conflict Addon, Conflict Type, Addon File, Conflict File
	#
	var selectColDef: AceTableColumnDef = AceTableColumnDef.new()
	selectColDef.columnId = "selected"
	selectColDef.columnName = ""
	selectColDef.columnType = AceTableConstants.ColumnType.SELECTION
	selectColDef.columnAlign = AceTableConstants.Align.CENTER
	selectColDef.columnImageSize = Vector2i(48 * _editor_scale, 48 * _editor_scale)
	selectColDef.columnHasSelectAll = true

	var addonColDef: AceTableColumnDef = AceTableColumnDef.new()
	addonColDef.columnId = "addon"
	addonColDef.columnName = "Add-on"
	addonColDef.columnType = AceTableConstants.ColumnType.LABEL
	addonColDef.columnSort = true
	addonColDef.columnAlign = AceTableConstants.Align.CENTER
	addonColDef.columnImageSize = Vector2i(48 * _editor_scale, 48 * _editor_scale)
	addonColDef.columnImage = "res://addons/anomalyAcesAddonManager/Icons/Package.svg"
	addonColDef.columnTextType = AceTableConstants.TextType.COMBO

	var conflictAddonColDef: AceTableColumnDef = AceTableColumnDef.new()
	conflictAddonColDef.columnId = "conflict_addon"
	conflictAddonColDef.columnName = "Conflict Add-on"
	conflictAddonColDef.columnType = AceTableConstants.ColumnType.LABEL
	conflictAddonColDef.columnSort = true
	conflictAddonColDef.columnAlign = AceTableConstants.Align.CENTER
	conflictAddonColDef.columnImageSize = Vector2i(48 * _editor_scale, 48 * _editor_scale)
	conflictAddonColDef.columnImage = "res://addons/anomalyAcesAddonManager/Icons/Package.svg"
	conflictAddonColDef.columnTextType = AceTableConstants.TextType.COMBO

	var conflictTypeColDef: AceTableColumnDef = AceTableColumnDef.new()
	conflictTypeColDef.columnId = "conflict_type"
	conflictTypeColDef.columnName = "Conflict Type"
	conflictTypeColDef.columnType = AceTableConstants.ColumnType.LABEL
	conflictTypeColDef.columnSort = true
	conflictTypeColDef.columnAlign = AceTableConstants.Align.CENTER
	conflictTypeColDef.columnTextType = AceTableConstants.TextType.TEXT

	var addonFileColDef: AceTableColumnDef = AceTableColumnDef.new()
	addonFileColDef.columnId = "addon_file"
	addonFileColDef.columnName = "Add-on File"
	addonFileColDef.columnType = AceTableConstants.ColumnType.LABEL
	addonFileColDef.columnSort = true
	addonFileColDef.columnAlign = AceTableConstants.Align.CENTER
	addonFileColDef.columnTextType = AceTableConstants.TextType.LINK
	addonFileColDef.columnCallable = _text_link_pressed

	var conflictFileColDef: AceTableColumnDef = AceTableColumnDef.new()
	conflictFileColDef.columnId = "conflicting_file"
	conflictFileColDef.columnName = "Conflict File"
	conflictFileColDef.columnType = AceTableConstants.ColumnType.LABEL
	conflictFileColDef.columnSort = true
	conflictFileColDef.columnAlign = AceTableConstants.Align.CENTER
	conflictFileColDef.columnTextType = AceTableConstants.TextType.LINK
	conflictFileColDef.columnCallable = _text_link_pressed

	var tableData: Array[Dictionary] = _createConflictTableData(conflics)
	var colDefs: Array[AceTableColumnDef] = [selectColDef, addonColDef, conflictAddonColDef, conflictTypeColDef, addonFileColDef, conflictFileColDef]

	AceLog.printLog(["Loading Conflict Table data via AceTableManager"])
	conflictTablePlugin.printConfig()
	AddonManagerUtil.scale_table_themes(conflictTablePlugin, _table_scale)
	_conflict_table = AceTableManager.createTable(conflictTablePlugin, colDefs, tableData)
	AddonManagerUtil.apply_editor_scaling(_conflict_table, _table_scale, false)
	_conflict_table.row_selected.connect(_on_conflict_table_selection)
	AceLog.printLog(["Done Loading Conflict Table data via AceTableManager"])

func _createConflictTableData(conflics: Array[RemoteRepoConflict]) -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for conflict in conflics:
		var conflict_dict: Dictionary = {
			"selected": false,
			"addon": conflict.addon.repo,
			"conflict_addon": conflict.conflicting_addon.repo,
			"conflict_type": "Release Conflict" if conflict.releaseConflict else ("Version Conflict" if conflict.versionConflict else ("Branch Conflict" if conflict.branchConflict else "N/A")),
			# Is data for a text link. Needs to be an object with "text" and "link" keys
			"addon_file": rrm.createTextLinkObjectForFile(conflict.addon),
			# Is data for a text link. Needs to be an object with "text" and "link" keys
			"conflicting_file": rrm.createTextLinkObjectForFile(conflict.conflicting_addon)
		}
		data.append(conflict_dict)
		data.append_array(_createConflictTableData(conflict.dependencies))
	return data


func _createAddonTable(addons: Array[RemoteRepoObject]) -> void:
	# 
	# columns: selected, addon, version/branch, addon file, status, updates
	#
	var selectColDef: AceTableColumnDef = AceTableColumnDef.new()
	selectColDef.columnId = "selected"
	selectColDef.columnName = ""
	selectColDef.columnType = AceTableConstants.ColumnType.SELECTION
	selectColDef.columnAlign = AceTableConstants.Align.CENTER
	selectColDef.columnImageSize = Vector2i(48 * _table_scale, 48 * _table_scale)
	selectColDef.columnHasSelectAll = true

	var addonColDef: AceTableColumnDef = AceTableColumnDef.new()
	addonColDef.columnId = "repo"
	addonColDef.columnName = "Add-on"
	addonColDef.columnType = AceTableConstants.ColumnType.LABEL
	addonColDef.columnSort = true
	addonColDef.columnAlign = AceTableConstants.Align.CENTER
	addonColDef.columnImageSize = Vector2i(48 * _editor_scale, 48 * _editor_scale)
	addonColDef.columnImage = "res://addons/anomalyAcesAddonManager/Icons/Package.svg"
	addonColDef.columnTextType = AceTableConstants.TextType.COMBO

	var versionColDef: AceTableColumnDef = AceTableColumnDef.new()
	versionColDef.columnId = "version"
	versionColDef.columnName = "Version"
	versionColDef.columnType = AceTableConstants.ColumnType.LABEL
	versionColDef.columnSort = true
	versionColDef.columnAlign = AceTableConstants.Align.CENTER
	versionColDef.columnTextType = AceTableConstants.TextType.TEXT

	var addonFileColDef: AceTableColumnDef = AceTableColumnDef.new()
	addonFileColDef.columnId = "addon_file"
	addonFileColDef.columnName = "Add-on File"
	addonFileColDef.columnType = AceTableConstants.ColumnType.LABEL
	addonFileColDef.columnSort = true
	addonFileColDef.columnAlign = AceTableConstants.Align.CENTER
	addonFileColDef.columnTextType = AceTableConstants.TextType.LINK
	addonFileColDef.columnCallable = _text_link_pressed

	var statusColDef: AceTableColumnDef = AceTableColumnDef.new()
	statusColDef.columnId = "status"
	statusColDef.columnName = "Status"
	statusColDef.columnType = AceTableConstants.ColumnType.LABEL
	statusColDef.columnSort = true
	statusColDef.columnAlign = AceTableConstants.Align.CENTER
	statusColDef.columnTextType = AceTableConstants.TextType.LINK
	statusColDef.columnCallable = _handle_update

	var lastUpdateColDef: AceTableColumnDef = AceTableColumnDef.new()
	lastUpdateColDef.columnId = "latest_update"
	lastUpdateColDef.columnName = "Latest Update"
	lastUpdateColDef.columnType = AceTableConstants.ColumnType.LABEL
	lastUpdateColDef.columnSort = true
	lastUpdateColDef.columnAlign = AceTableConstants.Align.CENTER
	lastUpdateColDef.columnTextType = AceTableConstants.TextType.TEXT
	

	var tableData: Array[Dictionary] = _normalize_table_data(_createAddonTableData(addons))

	var colDefs: Array[AceTableColumnDef] = [selectColDef, addonColDef, versionColDef, addonFileColDef, lastUpdateColDef, statusColDef]

	AceLog.printLog(["Loading Add-on Table data via AceTableManager"])
	addonTablePlugin.printConfig()
	AddonManagerUtil.scale_table_themes(addonTablePlugin, _table_scale)
	_addon_table = AceTableManager.createTable(addonTablePlugin, colDefs, tableData)
	AddonManagerUtil.apply_editor_scaling(_addon_table, _table_scale, false)
	_addon_table.row_selected.connect(_on_addon_table_selection)
	AceLog.printLog(["Done Loading Add-on Table data via AceTableManager"])

func _createAddonTableData(addons: Array[RemoteRepoObject]) -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for addon in addons:
		var addon_dict: Dictionary = {
			"selected": false,
			"repo": addon.repo,
			"version": addon.version if addon.isRelease else addon.branch,
			"status": rrm.createTextLinkObjectForUpdate(addon),
			# Is data for a text link. Needs to be an object with "text" and "link" keys
			"addon_file": rrm.createTextLinkObjectForFile(addon),
			"latest_update": addon.metadata.version_release_date.replace("T", " ") if addon.isRelease else addon.metadata.branch_last_commit_date.replace("T", " ")
		}
		data.append(addon_dict)
		data.append_array(_createAddonTableData(addon.dependencies))
	return data


func _normalize_table_data(table_data: Array[Dictionary]) -> Array[Dictionary]:
	# This function can be used to normalize or preprocess the data before feeding it to the table
	# For example, you could flatten nested data structures, format certain fields, etc.
	var normalized_data: Array[Dictionary] = []
	var normalized_dict: Dictionary = {}
	for dict in table_data:
		var dict_key = "|".join([dict["repo"], dict["version"]])
		if not normalized_dict.has(dict_key):
			normalized_dict[dict_key] = dict
	

	normalized_data.assign(normalized_dict.values())

	return normalized_data



func _button_pressed(colDef: AceTableColumnDef, dt: Dictionary):
	AceLog.printLog(["data from Button from column %s: %s" % [colDef.columnName,dt]], AceLog.LOG_LEVEL.INFO)

func _text_link_pressed(link: String) -> void:
	AceLog.printLog(["Text link pressed: %s" % link], AceLog.LOG_LEVEL.INFO)
	var abs_path: String = ProjectSettings.globalize_path(link)
	OS.shell_open(abs_path)

func _handle_update(link: String) -> void:
	AceLog.printLog(["Update link pressed: %s" % link], AceLog.LOG_LEVEL.INFO)

func _merge_updated_addons(addons: Array[RemoteRepoObject]) -> void:
	# This function can be used to merge the updated addons with the existing addons in the table
	# For example, you could update the status of existing addons, add new addons, remove deleted addons, etc.
	for updated_addon in addons:
		var existing_addon_index: int = _addons.find(updated_addon)
		if existing_addon_index != -1:
			# Update existing addon
			AceLog.printLog(["Existing addon to merge: %s" % _addons[existing_addon_index].repo], AceLog.LOG_LEVEL.DEBUG)
			_addons[existing_addon_index] = updated_addon
		else:
			# Add new addon
			AceLog.printLog(["New addon to merge: %s" % updated_addon.repo], AceLog.LOG_LEVEL.DEBUG)
			_addons.append(updated_addon)

func initialize_scaling(scale: float) -> void:
	_editor_scale = scale
	_table_scale = scale
	_apply_editor_scaling(self, scale)



func _apply_editor_scaling(node: Node, scale: float) -> void:
	AddonManagerUtil.apply_editor_scaling(node, scale, true)
