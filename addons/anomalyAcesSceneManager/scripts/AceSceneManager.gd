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
static var default_transition_types: Dictionary[String, AceTransitionType] = {}


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
		"res://addons/anomalyAcesSceneManager/scenes/DefaultLoadingScene/AceDefaultLoadingScene.tscn",
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
var current_transition: AceTransitionConfig = null
var _loading_scene_cache: Dictionary = {}


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


func _get_cached_packed_scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	if _loading_scene_cache.has(path):
		var cached_res: Variant = _loading_scene_cache[path]
		if cached_res is PackedScene and is_instance_valid(cached_res as PackedScene):
			return cached_res as PackedScene
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var res: PackedScene = load(path) as PackedScene
		if res != null:
			_loading_scene_cache[path] = res
			return res
	return null


func load_scene(scene_key_or_path: String, transition_name: String = "", scene_data: Variant = null) -> void:
	if not is_scene_eligible(scene_key_or_path):
		AceLog.printLog(["Scene '%s' is not registered in scene_registry!" % scene_key_or_path], AceLog.LOG_LEVEL.ERROR)
		return

	var resolved_path: String = AceScenes.resolve_scene_path(scene_key_or_path, settings)
	if resolved_path.is_empty():
		AceLog.printLog(["Could not resolve scene path for key/path: '%s'" % scene_key_or_path], AceLog.LOG_LEVEL.ERROR)
		return

	set_process(false)
	scene_path = resolved_path
	pending_scene_data = scene_data

	if settings != null:
		use_sub_threads = settings.get_setting(USE_SUB_THREADS, true)

	if not transition_name.is_empty():
		current_transition = AceTransitions.get_transition_config(transition_name, settings)
		transition_started.emit(transition_name)

	# Resolve loading screen path: check transition config first, then fallback to project setting default
	var loading_screen_path: String = current_transition.loading_screen_path if current_transition != null else ""

	var default_loading_path: String = "res://addons/anomalyAcesSceneManager/scenes/DefaultLoadingScene/AceDefaultLoadingScene.tscn"

	if loading_screen_path.is_empty():
		if settings != null:
			var s_val: Variant = settings.get_setting(DEFAULT_LOADING_SCREEN, default_loading_path)
			if s_val is String and not (s_val as String).is_empty():
				loading_screen_path = s_val as String
		if loading_screen_path.is_empty():
			loading_screen_path = default_loading_path

	var loading_scene_res: PackedScene = _get_cached_packed_scene(loading_screen_path)
	if loading_scene_res == null and loading_screen_path != default_loading_path:
		loading_scene_res = _get_cached_packed_scene(default_loading_path)

	if loading_scene_res != null:
		loading_screen = loading_scene_res.instantiate()
		get_tree().root.add_child(loading_screen)
		if loading_screen.has_method("_on_progress_changed"):
			if not progress_changed.is_connected(loading_screen._on_progress_changed):
				progress_changed.connect(loading_screen._on_progress_changed)
		if loading_screen.has_method("_on_load_finished"):
			if not load_finished.is_connected(loading_screen._on_load_finished):
				load_finished.connect(loading_screen._on_load_finished)
			
		if loading_screen.has_method("play_transition"):
			var active_config: AceTransitionConfig = current_transition if current_transition != null else AceTransitions.get_transition_config("Fade", settings)
			loading_screen.play_transition(active_config)
			if loading_screen.has_signal("loading_screen_ready"):
				await loading_screen.loading_screen_ready

	start_load()


func start_load() -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(scene_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var res: PackedScene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
		if res == null and ResourceLoader.exists(scene_path):
			res = load(scene_path) as PackedScene
		if res != null:
			_on_content_loaded(res.instantiate())
			return

	var state: Error = ResourceLoader.load_threaded_request(scene_path, "", use_sub_threads)
	if state == OK or state == ERR_ALREADY_IN_USE:
		set_process(true)
		AceLog.printLog(["Started threaded load for scene: %s" % scene_path], AceLog.LOG_LEVEL.INFO)
	else:
		if ResourceLoader.exists(scene_path):
			var res: PackedScene = load(scene_path) as PackedScene
			if res != null:
				_on_content_loaded(res.instantiate())
				return
		AceLog.printLog(["Failed to request threaded load for scene: %s (Error: %s)" % [scene_path, state]], AceLog.LOG_LEVEL.ERROR)


# ==============================================================================
# PRIVATE / CALLBACK METHODS
# ==============================================================================

static func _process_settings(p_settings: AceSettings) -> void:
	if p_settings == null:
		return


func _on_content_loaded(content: Node) -> void:
	set_process(false)
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

	# Notify listeners (including the active loading screen) that loading has completed
	load_finished.emit()

	# Clean up loading screen
	if loading_screen != null:
		if loading_screen.has_method("_on_progress_changed") and progress_changed.is_connected(loading_screen._on_progress_changed):
			progress_changed.disconnect(loading_screen._on_progress_changed)
		if loading_screen.has_method("_on_load_finished") and load_finished.is_connected(loading_screen._on_load_finished):
			load_finished.disconnect(loading_screen._on_load_finished)

		var ls: Node = loading_screen
		loading_screen = null

		if ls.has_method("finish_transition"):
			ls.call("finish_transition")
			if is_instance_valid(ls) and ls.has_signal("loading_screen_finished"):
				await ls.loading_screen_finished
		else:
			ls.queue_free()

	transition_completed.emit()

	# Reset manager state completely for subsequent transitions
	scene_path = ""
	loaded_resource = null
	pending_scene_data = null
	current_transition = null
	progress.clear()
