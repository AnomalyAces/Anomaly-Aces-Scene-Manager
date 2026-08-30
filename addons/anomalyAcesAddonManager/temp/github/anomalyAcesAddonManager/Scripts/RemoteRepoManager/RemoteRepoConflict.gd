class_name RemoteRepoConflict extends Object


var addon: RemoteRepoObject
var parent_addon: RemoteRepoObject
var conflicting_addon: RemoteRepoObject
var releaseConflict: bool
var versionConflict: bool
var branchConflict: bool


func initializeConflict(_addon: RemoteRepoObject, _conflicting_addon: RemoteRepoObject, _parent_addon: RemoteRepoObject = null) -> void:
	addon = _addon
	conflicting_addon = _conflicting_addon
	parent_addon = _parent_addon

func isConflicting() -> bool:

	if addon.isRelease != conflicting_addon.isRelease:
		releaseConflict = true
		return true
	else:
		if addon.isRelease:
			versionConflict = addon.version != conflicting_addon.version
			return versionConflict
		else:
			branchConflict = addon.branch != conflicting_addon.branch
			return branchConflict

func getRepoDesc(addon) -> String:
	return "Repo %s(addonFile: %s, isRelease: %s, version: %s, branch: %s)" % [addon.repo, addon.metadata.addon_file, addon.isRelease, addon.version, addon.branch]


func createConflictDesc() -> String:
	var addon_desc: String = getRepoDesc(addon)
	var conflict_desc: String = getRepoDesc(conflicting_addon)
	if parent_addon != null:
		var parent_desc: String = getRepoDesc(parent_addon)
		return "%s -> Dependent %s conflicts with %s" % [parent_desc, addon_desc, conflict_desc]
	else:
		return "%s conflicts with %s" % [addon_desc, conflict_desc]


func _to_string() -> String:
	return "RemoteRepoConflict[addon: %s, conflicting_addon: %s, parent_addon: %s, releaseConflict: %s, versionConflict: %s, branchConflict: %s]"  % [addon._to_string(), conflicting_addon._to_string(), parent_addon._to_string() if parent_addon != null else "null", releaseConflict, versionConflict, branchConflict]