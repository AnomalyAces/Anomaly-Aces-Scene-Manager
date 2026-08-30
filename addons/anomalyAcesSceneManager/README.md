# Ace Scene Manager (`anomalyAcesSceneManager`)

An advanced Godot 4 editor plugin and scene management system for controlling scene transitions, registering available target scenes, managing transition visual effects, and passing data between scenes.

---

## Features

- **Scene Registry**: Map human-readable scene keys (e.g. `"Title"`, `"Login"`) to scene paths (`"res://Scenes/TitleScene.tscn"`) in a single central project setting.
- **Asynchronous Threaded Loading**: Uses `ResourceLoader.load_threaded_request` to load scenes smoothly in background threads with real-time progress signals.
- **Customizable Transitions & `AceTransitionType` Objects**: Configurable transition types defining container root NodePaths, progress bar flags, and progress bar visual NodePaths.
- **Base Loading Screen Class (`AceLoadingScene`)**: Extensible base class for custom loading screen scenes, with a default implementation in `AceDefaultLoadingScene`.
- **Cross-Scene Data Transfer**: Transfer state between outgoing and incoming scenes via `AceSceneData`.
- **Project Settings Integration**: Configured directly in Godot's Project Settings via `AceSettings`.

---

## Dedicated Model Object: `AceTransitionType` ([AceTransitionType.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Scene-Manager/addons/anomalyAcesSceneManager/scripts/models/AceTransitionType.gd))

Resource model representing the layout configuration for a specific transition type:

```gdscript
class_name AceTransitionType extends Resource

@export var transition_root_node: NodePath = ^"" # Path to root container node
@export var has_progress_bar: bool = false       # Whether this layout includes a progress bar
@export var progress_bar_node: NodePath = ^""    # Path to the progress bar visual node
```

---

## Project Settings (`aceSceneManager`)

The plugin registers settings directly under `aceSceneManager` in Godot's **Project Settings**.

| Setting Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `aceSceneManager/scene_registry` | `Dictionary[String, String]` | `{}` | Key-value pairs mapping scene aliases (e.g. `"Title"`, `"Login"`) to target `.tscn` file paths. |
| `aceSceneManager/available_transitions` | `Dictionary[String, Dictionary]` | `{}` | Custom transition configurations mapping transition names to dictionary properties (`start`, `end`, `type`). |
| `aceSceneManager/transition_types` | `Dictionary` | *(See below)* | Maps Transition Type names to `AceTransitionType` configuration properties. |
| `aceSceneManager/default_loading_screen` | `String` | `"res://.../AceDefaultLoadingScene.tscn"` | File path (`*.tscn`) to the loading screen scene instantiated during threaded load operations. |
| `aceSceneManager/use_sub_threads` | `bool` | `true` | When `true`, uses background sub-threads during `ResourceLoader.load_threaded_request` for non-blocking UI frame updates. |

---

## Configurable Transition Node Mapping in Custom Loading Screens (`AceLoadingScene`)

`AceLoadingScene` provides built-in transition type resolution:

### 1. Exported Dictionary on Custom Loading Screen Script

```gdscript
extends AceLoadingScene
class_name MyCustomLoadingScene

@export var transition_types: Dictionary = {
    "Fade": AceTransitionType.new(^"UI/FadePanel", true, ^"UI/FadePanel/ProgressBar"),
    "Wipe": AceTransitionType.new(^"UI/WipeMask", false, ^"")
}
```

### 2. Dynamic Helpers (`AceLoadingScene`)
- **`get_transition_type_info(type_name: String) -> AceTransitionType`**: Retrieves `AceTransitionType` configuration object.
- **`get_transition_node(type_name: String) -> Control`**: Resolves and returns the root container node for the active transition type.
- **`get_progress_bar_node(type_name: String) -> Control`**: Resolves and returns the progress bar visual node if `has_progress_bar` is `true`.
