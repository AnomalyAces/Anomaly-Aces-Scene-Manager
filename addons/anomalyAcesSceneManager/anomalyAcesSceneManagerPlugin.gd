@tool
extends EditorPlugin

const AUTOLOAD_NAME: String = "AceSceneManager"
const AUTOLOAD_PATH: String = "res://addons/anomalyAcesSceneManager/scripts/AceSceneManager.gd"


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass

