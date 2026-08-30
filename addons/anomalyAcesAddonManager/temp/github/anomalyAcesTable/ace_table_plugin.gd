@tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	#Add Custom Types
	add_custom_type(
		"AceTablePlugin", 
		"Control", 
		preload("res://addons/anomalyAcesTable/Scripts/ace_table_properties.gd"),
		preload("res://addons/anomalyAcesTable/AceTable.svg")
	)

func _exit_tree():
	#remove custom types
	remove_custom_type("AceTablePlugin")
