@tool
class_name AceSettings extends Node


## Dictionary that has a key value pair describing the setting and the setting properties [br]
## [b]Key[/b] - String, settings path [br]
## [b]Value[/b] - [GodotSettingConfig] - ccontains all of the properties for the setting added
var settings_config : Dictionary[String, AceSettingConfig]

## Root where the settings should be nested in the Project settings
var settings_root: String


func initialize_settings(config: Dictionary[String, AceSettingConfig], root: String) -> void:
	settings_config = config
	settings_root = root

func prepare() -> void:
	AceLog.printLog(["Settings to set: %s" % settings_config])
	# Set up initial settings
	for key: String in settings_config:
		AceLog.printLog(["Loading setting: %s" % key])
		var setting_config: AceSettingConfig = settings_config[key]
		var setting_name: String = "%s/%s" % [settings_root,key]
		if not ProjectSettings.has_setting(setting_name):
			AceLog.printLog(["setting %s is not present" % setting_name])
			ProjectSettings.set_setting(setting_name, setting_config.value)
		ProjectSettings.add_property_info({
			"name" = setting_name,
			"type" = setting_config.type,
			"hint" = setting_config.hint,
			"hint_string" = setting_config.hint_string
		})
		ProjectSettings.set_as_basic(setting_name, true)
		ProjectSettings.set_initial_value(setting_name, setting_config.value)
		# ProjectSettings.set_as_internal(setting_name, setting_config.has("is_hidden"))


func set_setting(key: String, value) -> void:
	var setting_val: Variant = get_setting(key,value)
	AceLog.printLog(["Setting val: %s" % setting_val])
	if setting_val != null && setting_val != value:
		AceLog.printLog(["Setting %s to %s" % ["%s/%s" % [settings_root,key], setting_val]])
		ProjectSettings.set_setting("%s/%s" % [settings_root,key], setting_val)
		ProjectSettings.set_initial_value("%s/%s" % [settings_root,key], setting_val)
		ProjectSettings.save()


func get_setting(key: String, default: Variant = null)-> Variant:
	if ProjectSettings.has_setting("%s/%s" % [settings_root,key]):
		return ProjectSettings.get_setting("%s/%s" % [settings_root,key])
	else:
		return default

