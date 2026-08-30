@tool
extends Node

## Main Autoload Manager for scene loading, transitions, and scene data transfer.

# ==============================================================================
# SIGNALS
# ==============================================================================

signal progress_changed(progress: float)
signal load_finished
signal transition_started(transition_name: String)
signal transition_completed


# ==============================================================================
# CONSTANTS & SETTINGS
# ==============================================================================

## Settings Root
const SETTINGS_ROOT: String = "aceSceneManager"

## Setting Keys
const SCENE_REGISTRY: String = "scene_registry"
const AVAILABLE_TRANSITIONS: String = "available_transitions"
const TRANSITION_TYPES: String = "transition_types"
const DEFAULT_LOADING_SCREEN: String = "default_loading_screen"
const USE_SUB_THREADS: String = "use_sub_threads"

static var empty_registry: Dictionary[String, String] = {}
static var empty_transitions: Dictionary[String, AceTransitionConfig] = {}
static var default_transition_types: Dictionary[String, AceTransitionType] = {
	"Fade": AceTransitionType.new("Fade", true, "Fade/ProgressBar"),
	"Circle": AceTransitionType.new("Circle", false, "")
}


static var SETTINGS_CONFIGURATION: Dictionary[String, AceSettingConfig] = {
	SCENE_REGISTRY: AceSettingConfig.new(
		SCENE_REGISTRY,
		TYPE_DICTIONARY,
		empty_registry,
		PROPERTY_HINT_TYPE_STRING,
		"%s/%s:;%s/%s:%s" % [TYPE_STRING, PROPERTY_HINT_NONE, TYPE_STRING, PROPERTY_HINT_FILE, "*.tscn"]
	),
	AVAILABLE_TRANSITIONS: AceSettingConfig.new(
		AVAILABLE_TRANSITIONS,
		TYPE_DICTIONARY,
		empty_transitions,
		PROPERTY_HINT_TYPE_STRING,
		"%s/%s:;%s/%s:%s" % [TYPE_STRING, PROPERTY_HINT_NONE, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "AceTransitionConfig"]
	),
	TRANSITION_TYPES: AceSettingConfig.new(
		TRANSITION_TYPES,
		TYPE_DICTIONARY,
		default_transition_types,
		PROPERTY_HINT_TYPE_STRING,
		"%s/%s:;%s/%s:%s" % [TYPE_STRING, PROPERTY_HINT_NONE, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "AceTransitionType"]
	),

	DEFAULT_LOADING_SCREEN: AceSettingConfig.new(
		DEFAULT_LOADING_SCREEN,
		TYPE_STRING,
		"res://addons/anomalyAcesSceneManager/scenes/LoadingScene/AceDefaultLoadingScene.tscn",
		PROPERTY_HINT_FILE,
		"*.tscn"
	),
	USE_SUB_THREADS: AceSettingConfig.new(
		USE_SUB_THREADS,
		TYPE_BOOL,
		true
	)
}


# ==============================================================================
# VARIABLES
# ==============================================================================

static var settings: AceSettings

var loaded_resource: PackedScene
var loading_screen: Node = null
var scene_path: String = ""
var progress: Array = []
var use_sub_threads: bool = true
var pending_scene_data: Variant = null
var current_transition: Variant = null


# ==============================================================================
# ENGINE VIRTUAL METHODS
# ==============================================================================

func _ready() -> void:
	set_process(false)
	call_deferred("initialize_settings")


func _process(_delta: float) -> void:
	if scene_path.is_empty():
		set_process(false)
		return

	var load_status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(scene_path, progress)
	if progress.size() > 0:
		progress_changed.emit(progress[0])

	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, \
		ResourceLoader.THREAD_LOAD_FAILED:
			AceLog.printLog(["ResourceLoader Load Failed for: %s (Status: %s)" % [scene_path, load_status]], AceLog.LOG_LEVEL.ERROR)
			set_process(false)
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			loaded_resource = ResourceLoader.load_threaded_get(scene_path)
			if loaded_resource != null:
				_on_content_loaded(loaded_resource.instantiate())
			else:
				AceLog.printLog(["Loaded resource is null for path: %s" % scene_path], AceLog.LOG_LEVEL.ERROR)
			set_process(false)


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

static func initialize_settings() -> void:
	settings = AceSettings.new()
	settings.initialize_settings(SETTINGS_CONFIGURATION, SETTINGS_ROOT)
	_process_settings(settings)
	settings.prepare()
	AceLog.printLog(["AceSceneManager settings initialized."])


func is_scene_eligible(scene_key_or_path: String) -> bool:
	return AceScenes.is_scene_eligible(scene_key_or_path, settings)


func load_scene(scene_key_or_path: String, transition_name: String = "", scene_data: Variant = null) -> void:
	if not is_scene_eligible(scene_key_or_path):
		AceLog.printLog(["Scene '%s' is not registered in scene_registry!" % scene_key_or_path], AceLog.LOG_LEVEL.ERROR)
		return

	var resolved_path: String = AceScenes.resolve_scene_path(scene_key_or_path, settings)
	if resolved_path.is_empty():
		AceLog.printLog(["Could not resolve scene path for key/path: '%s'" % scene_key_or_path], AceLog.LOG_LEVEL.ERROR)
		return

	scene_path = resolved_path
	pending_scene_data = scene_data

	if settings != null:
		use_sub_threads = settings.get_setting(USE_SUB_THREADS, true)

	if not transition_name.is_empty():
		current_transition = AceTransitions.get_transition(transition_name, settings)
		transition_started.emit(transition_name)

	# Instantiate default loading screen if configured
	var default_loading_path: String = "res://addons/anomalyAcesSceneManager/scenes/LoadingScene/AceDefaultLoadingScene.tscn"
	var loading_screen_path: String = settings.get_setting(DEFAULT_LOADING_SCREEN, default_loading_path) if settings != null else default_loading_path
	if not loading_screen_path.is_empty() and ResourceLoader.exists(loading_screen_path):
		var loading_scene_res: PackedScene = load(loading_screen_path)
		if loading_scene_res != null:
			loading_screen = loading_scene_res.instantiate()
			get_tree().root.add_child(loading_screen)
			if loading_screen.has_method("_on_progress_changed"):
				progress_changed.connect(loading_screen._on_progress_changed)
			if loading_screen.has_method("_on_load_finished"):
				load_finished.connect(loading_screen._on_load_finished)
				
			if loading_screen.has_method("play_transition"):
				loading_screen.play_transition(transition_name if not transition_name.is_empty() else AceTransitions.TRANSITION_FADE_BLACK)
				if loading_screen.has_signal("loading_screen_ready"):
					await loading_screen.loading_screen_ready

	start_load()


func start_load() -> void:
	var state: Error = ResourceLoader.load_threaded_request(scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)
		AceLog.printLog(["Started threaded load for scene: %s" % scene_path], AceLog.LOG_LEVEL.INFO)
	else:
		AceLog.printLog(["Failed to request threaded load for scene: %s (Error: %s)" % [scene_path, state]], AceLog.LOG_LEVEL.ERROR)


# ==============================================================================
# PRIVATE / CALLBACK METHODS
# ==============================================================================

static func _process_settings(p_settings: AceSettings) -> void:
	if p_settings == null:
		return


func _on_content_loaded(content: Node) -> void:
	var outgoing_scene: Node = get_tree().current_scene
	var incoming_data: Variant = pending_scene_data

	# If no scene_data was explicitly passed, attempt to preserve outgoing scene data
	if incoming_data == null and outgoing_scene != null:
		if "scene_data" in outgoing_scene:
			incoming_data = outgoing_scene.get("scene_data")

	# Transfer data to incoming scene if supported
	if content != null and incoming_data != null:
		if "scene_data" in content:
			content.set("scene_data", incoming_data)
		elif content.has_method("set_scene_data"):
			content.call("set_scene_data", incoming_data)

	AceLog.printLog(["Switching from scene '%s' to '%s'" % [outgoing_scene, content]], AceLog.LOG_LEVEL.INFO)

	# Remove outgoing scene
	if outgoing_scene != null:
		outgoing_scene.queue_free()

	# Add incoming scene
	get_tree().root.add_child(content)
	get_tree().current_scene = content

	# Clean up loading screen
	if loading_screen != null:
		if loading_screen.has_method("finish_transition"):
			loading_screen.call("finish_transition")
		else:
			loading_screen.queue_free()
		loading_screen = null

	load_finished.emit()
	transition_completed.emit()
	pending_scene_data = null
