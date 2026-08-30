@tool
class_name AcePluginManager extends Control

@onready var main_view: AcePluginMainView = $Main
@onready var install_addons: AcePluginInstallAddonsView = $InstallAddons
@onready var github_pat: AcePluginGithubPATView = $GithubPat


func _ready() -> void:
	if main_view != null:
		main_view.open_install_view.connect(_on_open_install_addons)
		main_view.open_github_pat_view.connect(_on_open_github_pat)

	if install_addons != null:
		install_addons.back_to_main_view.connect(_on_close_install_addons)
		install_addons.install_completed.connect(_on_install_completed)
	
	if github_pat != null:
		github_pat.back_to_main_view.connect(_on_close_github_pat)

func assignEditorInterface(editorInterface: EditorInterface) -> void:
	# Scale updater subviews dynamically using the user's custom scale setting
	var scale = AddonManagerUtil.get_applied_scale()
	
	var mv = main_view if main_view != null else get_node_or_null("Main")
	if mv != null:
		mv._editor_interface = editorInterface
		mv.initialize_scaling(scale)

	var ia = install_addons if install_addons != null else get_node_or_null("InstallAddons")
	if ia != null:
		ia._editor_interface = editorInterface
		ia.initialize_scaling(scale)

	var gp = github_pat if github_pat != null else get_node_or_null("GithubPat")
	if gp != null:
		gp._editor_interface = editorInterface
		gp.initialize_scaling(scale)


func _on_open_install_addons(addons: Array[RemoteRepoObject], config_file: ConfigFile) -> void:
	AceLog.printLog(["Opening Install Addons View with addons:", addons])
	install_addons.initalizeInstallView(addons, config_file)
	main_view.hide()
	install_addons.show()

func _on_close_install_addons() -> void:
	install_addons.hide()
	main_view.show()

func _on_install_completed(addons: Array, config_file: ConfigFile) -> void:
	AceLog.printLog(["Addons Installed:", addons])
	install_addons.hide()
	main_view.show()
	main_view.updateAddons()

func _on_open_github_pat() -> void:
	github_pat.initialize()
	main_view.hide()
	github_pat.show()

func _on_close_github_pat() -> void:
	main_view.show()
	github_pat.hide()
