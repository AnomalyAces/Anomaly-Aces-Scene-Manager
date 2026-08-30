@tool
extends PanelContainer

signal remove_requested

@onready var owner_field: LineEdit = $VBox/TopRow/OwnerField
@onready var repo_field: LineEdit = $VBox/TopRow/RepoField
@onready var subfolder_field: LineEdit = $VBox/SecondRow/SubfolderField
@onready var is_release_toggle: CheckButton = $VBox/ThirdRow/IsReleaseToggle
@onready var version_branch_label: Label = $VBox/ThirdRow/VersionBranchLabel
@onready var version_branch_field: LineEdit = $VBox/ThirdRow/VersionBranchField
@onready var remove_button: Button = $VBox/TopRow/RemoveButton
@onready var add_sub_dep_button: Button = $VBox/SubDepsSection/AddSubDepButton
@onready var sub_deps_container: VBoxContainer = $VBox/SubDepsSection/SubDepsContainer

const DEPENDENCY_ENTRY_SCENE = preload("res://addons/anomalyAcesAddonManager/Scenes/AddonDependencyEditor/DependencyEntry/dependency_entry.tscn")

func _ready() -> void:
	remove_button.pressed.connect(func(): remove_requested.emit())
	is_release_toggle.toggled.connect(_on_release_toggled)
	add_sub_dep_button.pressed.connect(_on_add_sub_dep)
	_on_release_toggled(is_release_toggle.button_pressed)

func _on_release_toggled(pressed: bool) -> void:
	version_branch_label.text = "Version:" if pressed else "Branch:"
	version_branch_field.placeholder_text = "e.g. 1.0.0" if pressed else "e.g. master"

func _on_add_sub_dep() -> void:
	var entry = DEPENDENCY_ENTRY_SCENE.instantiate()
	sub_deps_container.add_child(entry)
	entry.remove_requested.connect(func(): entry.queue_free())

func get_data() -> Dictionary:
	var deps: Array = []
	for child in sub_deps_container.get_children():
		if child.has_method("get_data"):
			deps.append(child.get_data())
	
	return {
		"owner": owner_field.text.strip_edges(),
		"repo": repo_field.text.strip_edges(),
		"isRelease": is_release_toggle.button_pressed,
		"version": version_branch_field.text.strip_edges() if is_release_toggle.button_pressed else "1.0",
		"branch": version_branch_field.text.strip_edges() if not is_release_toggle.button_pressed else "master",
		"subfolder": subfolder_field.text.strip_edges(),
		"dependencies": deps
	}

func set_data(data: Dictionary) -> void:
	owner_field.text = data.get("owner", "")
	repo_field.text = data.get("repo", "")
	var is_release: bool = data.get("isRelease", false)
	is_release_toggle.set_pressed_no_signal(is_release)
	_on_release_toggled(is_release)
	
	if is_release:
		version_branch_field.text = data.get("version", "")
	else:
		version_branch_field.text = data.get("branch", "")
	
	subfolder_field.text = data.get("subfolder", "")
	
	# Load nested dependencies
	for sub_dep in data.get("dependencies", []):
		var entry = DEPENDENCY_ENTRY_SCENE.instantiate()
		sub_deps_container.add_child(entry)
		entry.set_data(sub_dep)
		entry.remove_requested.connect(func(): entry.queue_free())
