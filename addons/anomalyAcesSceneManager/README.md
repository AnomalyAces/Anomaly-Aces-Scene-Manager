# Ace Scene Manager (`anomalyAcesSceneManager`)

An advanced Godot 4 editor plugin and scene management system for controlling scene transitions, registering available target scenes, managing transition visual effects, and passing data between scenes.

---

## Features

- **Scene Registry**: Map human-readable scene keys (e.g. `"Title"`, `"Login"`) to scene paths (`"res://Scenes/TitleScene.tscn"`) in a single central project setting.
- **Asynchronous Threaded Loading**: Uses `ResourceLoader.load_threaded_request` to load scenes smoothly in background threads with real-time progress signals.
- **Customizable Transitions & `AceTransitionType` Nodes**: Configurable `Control`-based transition nodes defining node picker links for transition container root controls, progress bar flags, and progress bar visual controls. Live `@tool` warnings update automatically in the Godot Inspector.
- **Base Loading Screen Class (`AceLoadingScene`)**: Extensible base class for custom loading screen scenes, with a default implementation in `AceDefaultLoadingScene`.
- **Strictly Typed Configuration**: All transition configurations use `AceTransitionConfig` instances without untyped dictionaries or `Variant` fallbacks.
- **Cross-Scene Data Transfer**: Transfer state between outgoing and incoming scenes via `AceSceneData`.
- **Project Settings Integration**: Configured directly in Godot's Project Settings via `AceSettings`.

---

## Dedicated Model Objects

### `AceTransitionType` ([AceTransitionType.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Scene-Manager/addons/anomalyAcesSceneManager/scripts/models/AceTransitionType.gd))

Node model representing the layout configuration for a specific transition type:

```gdscript
class_name AceTransitionType extends Control

@export var transition_root_node: Control # Control node picker link to root container
@export var has_progress_bar: bool = false # Whether this layout includes a progress bar
@export var progress_bar_node: Control    # Control node picker link to progress bar visual
```

### `AceTransitionConfig` ([AceTransitionConfig.gd](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Scene-Manager/addons/anomalyAcesSceneManager/scripts/models/AceTransitionConfig.gd))

Resource model representing a transition animation configuration:

```gdscript
class_name AceTransitionConfig extends Resource

@export var start: String = ""                           # Start animation name
@export var end: String = ""                             # End animation name
@export_file("*.tscn") var loading_screen_path: String = "" # Optional custom loading screen path (falls back to Project Settings default if empty)
```

---

## Project Settings (`aceSceneManager`)

The plugin registers settings directly under `aceSceneManager` in Godot's **Project Settings**.

| Setting Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `aceSceneManager/scene_registry` | `Dictionary[String, String]` | `{}` | Key-value pairs mapping scene aliases (e.g. `"Title"`, `"Login"`) to target `.tscn` file paths. |
| `aceSceneManager/available_transitions` | `Dictionary[String, AceTransitionConfig]` | `{}` | Custom transition configurations mapping transition names to `AceTransitionConfig` objects. |
| `aceSceneManager/transition_types` | `Dictionary[String, AceTransitionType]` | `{}` | Maps Transition Type names to `AceTransitionType` layout nodes. |
| `aceSceneManager/default_loading_screen` | `String` | `"res://addons/anomalyAcesSceneManager/scenes/DefaultLoadingScene/AceDefaultLoadingScene.tscn"` | Default file path (`*.tscn`) to the loading screen scene instantiated during threaded load operations. |
| `aceSceneManager/use_sub_threads` | `bool` | `true` | When `true`, uses background sub-threads during `ResourceLoader.load_threaded_request` for non-blocking UI frame updates. |

---

## Configurable Transition Node Mapping in Custom Loading Screens (`AceLoadingScene`)

`AceLoadingScene` provides built-in transition type resolution and live editor configuration warnings:

### 1. Exported Dictionary on Custom Loading Screen Script

```gdscript
extends AceLoadingScene
class_name MyCustomLoadingScene

@export var transition_types: Dictionary[String, AceTransitionType] = {
    "Fade": $TransitionTypes/FadeTransition,
    "Circle": $TransitionTypes/CircleTransition
}
```

### 2. Strictly Typed Dynamic Helpers (`AceLoadingScene`)
- **`play_transition(transition: AceTransitionConfig) -> void`**: Begins transition-in animation for the specified configuration.
- **`finish_transition() -> void`**: Begins transition-out animation when loading completes.
- **`get_transition_type_info(transition: AceTransitionConfig) -> AceTransitionType`**: Retrieves `AceTransitionType` layout node using the resolution waterfall.
- **`get_transition_node(transition: AceTransitionConfig) -> Control`**: Resolves and returns the root container Control node for the active transition type.
- **`get_progress_bar_node(transition: AceTransitionConfig) -> Control`**: Resolves and returns the progress bar visual Control node if `has_progress_bar` is `true`.

### 3. Transition Type Resolution Waterfall Order (`get_transition_type_info`)

When resolving an `AceTransitionType` layout for an `AceTransitionConfig`, `AceLoadingScene` evaluates potential sources in the following priority order:

1. **Exported Scene Dictionary (`transition_types`)**: Matches transition search name against `@export var transition_types: Dictionary[String, AceTransitionType]` on the active `AceLoadingScene`.
2. **Global Project Settings**: Looks up global settings under `aceSceneManager/transition_types`.
3. **Default Fallback**: Instantiates a default blank `AceTransitionType.new()`.

### 4. Container & Progress Bar Resolution Fallbacks

- **Root Control Container (`get_transition_node`)**: Returns `info.transition_root_node`. If unassigned/null, falls back to returning the **first child `Control` node** in the loading scene hierarchy.
- **Progress Bar Node (`get_progress_bar_node`)**: Returns `info.progress_bar_node` if `has_progress_bar` is `true`. If unassigned/null, searches the container children for any node named `"ProgressBar"`.

---

## Running the Demo Project

A built-in demo project is located in `addons/anomalyAcesSceneManager/demo/` demonstrating scene transitions, custom loading screen overrides, and `AceSceneData` transfers.

### Demo Components
- **Main Demo Scene**: [`res://addons/anomalyAcesSceneManager/demo/scenes/DemoMainScene/DemoMainScreen.tscn`](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Scene-Manager/addons/anomalyAcesSceneManager/demo/scenes/DemoMainScene/DemoMainScreen.tscn)
- **Detail Scene**: [`res://addons/anomalyAcesSceneManager/demo/scenes/DemoDetailScene/DemoDetailScreen.tscn`](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Scene-Manager/addons/anomalyAcesSceneManager/demo/scenes/DemoDetailScene/DemoDetailScreen.tscn)
- **Custom Loading Screen**: [`res://addons/anomalyAcesSceneManager/demo/scenes/DemoCustomLoadingScene/DemoCustomLoadingScreen.tscn`](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Scene-Manager/addons/anomalyAcesSceneManager/demo/scenes/DemoCustomLoadingScene/DemoCustomLoadingScreen.tscn)
- **Demo Settings Configuration**: [`AceSceneManagerDemoSettings.gd`](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Scene-Manager/addons/anomalyAcesSceneManager/scripts/settings/demo/AceSceneManagerDemoSettings.gd) (registers settings under `aceSceneManager/demo`)

### Steps to Run
1. Open the project in **Godot 4**.
2. Open [`res://addons/anomalyAcesSceneManager/demo/scenes/DemoMainScene/DemoMainScreen.tscn`](file:///c:/Users/Jerek/Documents/Anomaly%20Aces/Anomaly%20Aces%20Plugins/Anomaly-Aces-Scene-Manager/addons/anomalyAcesSceneManager/demo/scenes/DemoMainScene/DemoMainScreen.tscn) in the editor.
3. Press **F6** (or click **Run Current Scene**).
4. Use the interface buttons to test:
   - **Fade Transition**: Loads `DemoDetail` with fade animation and passes `AceSceneData`.
   - **Circle Wipe**: Loads `DemoDetail` with circle wipe animation.
   - **Custom Loading Screen**: Demonstrates overriding the default loading screen with `DemoCustomLoadingScreen.tscn`.
