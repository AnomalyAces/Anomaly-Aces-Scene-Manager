@tool
class_name AceSceneManagerDemoSettings extends RefCounted

## Demo settings configuration for Ace Scene Manager.
## Provides a separate copy of settings pre-configured for the demo scenes and transitions.

const SETTINGS_ROOT: String = "aceSceneManager/demo"

static var demo_scene_registry: Dictionary[String, String] = {
	"DemoMain": "res://addons/anomalyAcesSceneManager/demo/scenes/DemoMainScene/DemoMainScreen.tscn",
	"DemoDetail": "res://addons/anomalyAcesSceneManager/demo/scenes/DemoDetailScene/DemoDetailScreen.tscn"
}

static var demo_transitions: Dictionary[String, AceTransitionConfig] = {
	"Fade": AceTransitionConfig.new("fade_to_black", "fade_from_black"),
	"Circle": AceTransitionConfig.new("fade_to_black_circle", "fade_from_black_circle"),
	"CustomLoading": AceTransitionConfig.new("fade_to_black", "fade_from_black", "res://addons/anomalyAcesSceneManager/demo/scenes/DemoCustomLoadingScene/DemoCustomLoadingScreen.tscn"),
	"ShaderFade": AceTransitionConfig.new("shader_fade_to_black", "shader_fade_from_black"),
	"HorizontalSweep": AceTransitionConfig.new("horizontal_sweep_start", "horizontal_sweep_end"),
	"VerticalSweep": AceTransitionConfig.new("vertical_sweep_start", "vertical_sweep_end"),
	"DiagonalSweep": AceTransitionConfig.new("diagonal_sweep_start", "diagonal_sweep_end"),
	"TileSquare": AceTransitionConfig.new("tile_square_start", "tile_square_end"),
}

static var demo_transition_types: Dictionary[String, AceTransitionType] = {}

static var SETTINGS_CONFIGURATION: Dictionary[String, AceSettingConfig] = {
	AceSceneManager.SCENE_REGISTRY: AceSettingConfig.new(
		AceSceneManager.SCENE_REGISTRY,
		TYPE_DICTIONARY,
		demo_scene_registry,
		PROPERTY_HINT_TYPE_STRING,
		"%s/%s:;%s/%s:%s" % [TYPE_STRING, PROPERTY_HINT_NONE, TYPE_STRING, PROPERTY_HINT_FILE, "*.tscn"]
	),
	AceSceneManager.AVAILABLE_TRANSITIONS: AceSettingConfig.new(
		AceSceneManager.AVAILABLE_TRANSITIONS,
		TYPE_DICTIONARY,
		demo_transitions,
		PROPERTY_HINT_TYPE_STRING,
		"%s/%s:;%s/%s:%s" % [TYPE_STRING, PROPERTY_HINT_NONE, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "AceTransitionConfig"]
	),
	AceSceneManager.TRANSITION_TYPES: AceSettingConfig.new(
		AceSceneManager.TRANSITION_TYPES,
		TYPE_DICTIONARY,
		demo_transition_types,
		PROPERTY_HINT_TYPE_STRING,
		"%s/%s:;%s/%s:%s" % [TYPE_STRING, PROPERTY_HINT_NONE, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "AceTransitionType"]
	),
	AceSceneManager.DEFAULT_LOADING_SCREEN: AceSettingConfig.new(
		AceSceneManager.DEFAULT_LOADING_SCREEN,
		TYPE_STRING,
		"res://addons/anomalyAcesSceneManager/scenes/DefaultLoadingScene/AceDefaultLoadingScene.tscn",
		PROPERTY_HINT_FILE,
		"*.tscn"
	),
	AceSceneManager.USE_SUB_THREADS: AceSettingConfig.new(
		AceSceneManager.USE_SUB_THREADS,
		TYPE_BOOL,
		true
	)
}


static func setup_demo_settings() -> void:
	if AceSceneManager.settings != null and AceSceneManager.settings.settings_root == SETTINGS_ROOT:
		return

	var demo_settings: AceSettings = AceSettings.new()
	demo_settings.initialize_settings(SETTINGS_CONFIGURATION, SETTINGS_ROOT)
	demo_settings.prepare()
	
	# Explicitly set ProjectSettings values for demo execution
	ProjectSettings.set_setting("%s/%s" % [SETTINGS_ROOT, AceSceneManager.SCENE_REGISTRY], demo_scene_registry)
	ProjectSettings.set_setting("%s/%s" % [SETTINGS_ROOT, AceSceneManager.AVAILABLE_TRANSITIONS], demo_transitions)
	ProjectSettings.set_setting("%s/%s" % [SETTINGS_ROOT, AceSceneManager.TRANSITION_TYPES], demo_transition_types)
	ProjectSettings.set_setting("%s/%s" % [SETTINGS_ROOT, AceSceneManager.DEFAULT_LOADING_SCREEN], "res://addons/anomalyAcesSceneManager/scenes/DefaultLoadingScene/AceDefaultLoadingScene.tscn")

	AceSceneManager.settings = demo_settings
	AceLog.printLog(["AceSceneManager demo settings initialized under root '%s'." % SETTINGS_ROOT])
