class_name RemoteRepoMetadata extends Object

var addon_file: String
var branch_last_commit_date: String
var version_release_date: String
var download_url: String
var status: int = RemoteRepoConstants.STATUS.NOT_AVAILABLE



func _to_string() -> String:
	return "RemoteRepoMetadata[addon_file: %s, branch_last_commit_date: %s, version_release_date: %s, download_url: %s, status: %s]"  % [addon_file, branch_last_commit_date, version_release_date, download_url, RemoteRepoConstants.STATUS.keys()[status]]