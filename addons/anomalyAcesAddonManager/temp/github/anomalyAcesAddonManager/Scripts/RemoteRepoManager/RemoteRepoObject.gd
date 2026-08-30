class_name RemoteRepoObject extends Object


var owner: String
var repo: String
var isRelease: bool
var version: String
var branch: String
var subfolder: String
var metadata: RemoteRepoMetadata = RemoteRepoMetadata.new()
var dependencies: Array[RemoteRepoObject] = []



func _to_string() -> String:
    return "RemoteRepoObject[owner: %s, repo: %s, isRelease: %s, version: %s, branch: %s, subfolder: %s, metadata: %s, dependencies: %s"  \
        % [owner, repo, isRelease, version, branch, subfolder, metadata._to_string(), str(dependencies)]



