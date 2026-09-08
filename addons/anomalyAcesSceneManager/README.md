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
class_name AceTransitionType extends Resource

@export var transition_root_node: NodePath # NodePath link to root container node
@export var has_progress_bar: bool = false # Whether this layout includes a progress bar
@export var progress_bar_node: NodePath    # NodePath link to progress bar visual
@export var has_shader: bool = false       # Whether this transition uses a custom shader
@export var shader_node: NodePath          # NodePath link to shader target node (defaults to transition_root_node if empty)
@export var shader: Shader                 # Shader resource (.gdshader)
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
| `aceSceneManager/available_transitions` | `Dictionary[String, String]` | `{}` | Custom transition configurations mapping transition names to `AceTransitionConfig` resource file paths (`*.tres`). |
| `aceSceneManager/transition_types` | `Dictionary[String, String]` | `{}` | Maps Transition Type names to `AceTransitionType` layout resource file paths (`*.tres`). |
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

### 2. Available Helper & Lifecycle Methods (`AceLoadingScene`)

`AceLoadingScene` provides built-in helper methods to make implementing custom loading screens straightforward, as well as abstract lifecycle hooks that subclasses implement:

#### Dynamic Helper Methods (Available to Subclasses)
- **`get_transition_config(transition: AceTransitionConfig = null) -> AceTransitionConfig`**: Resolves the transition configuration object, returning `transition` if provided or falling back to the project default (`"Fade"`).
- **`get_transition_type_info(transition: AceTransitionConfig) -> AceTransitionType`**: Retrieves the `AceTransitionType` layout resource for the specified transition using the resolution waterfall (scene dictionary &rarr; global project settings &rarr; fallback).
- **`get_transition_node(transition: AceTransitionConfig) -> Control`**: Resolves and returns the root container `Control` node for the active transition type (falls back to the first child `Control` node).
- **`get_progress_bar_node(transition: AceTransitionConfig) -> Control`**: Resolves and returns the progress bar visual `Control` node if `has_progress_bar` is `true` on the active `AceTransitionType` (falls back to searching children for `"ProgressBar"`).
- **`get_shader_node(transition: AceTransitionConfig) -> CanvasItem`**: Resolves the target `CanvasItem` node for shader attachment (falls back to `transition_root_node`).
- **`setup_shader_material(transition: AceTransitionConfig) -> ShaderMaterial`**: Instantiates and assigns a `ShaderMaterial` with `info.shader` to the target shader node if `has_shader` is `true`.

#### Abstract Lifecycle Methods (To Implement in Subclasses)
- **`play_transition(transition: AceTransitionConfig) -> void`**: Called by `AceSceneManager` to begin the transition-in animation. Subclasses must emit `loading_screen_ready` once the screen is covered.
- **`finish_transition() -> void`**: Called by `AceSceneManager` when resource loading completes to begin the transition-out animation. Subclasses must emit `loading_screen_finished` and call `queue_free()` when finished.
- **`_on_progress_changed(new_value: float) -> void`**: Called by `AceSceneManager` when background thread load progress updates (`0.0` to `1.0`).
- **`_on_load_finished() -> void`**: Called by `AceSceneManager` the moment resource loading has finished, allowing loading screens to update UI (e.g. snap progress to 100%, show "Press Any Key" prompt) before `finish_transition()`.

#### Signals
- **`loading_screen_ready`**: Emit when the transition-in animation finishes to signal `AceSceneManager` to begin background loading.
- **`loading_screen_finished`**: Emit when the transition-out animation finishes so `AceSceneManager` knows the transition has completely finished.

### 3. Transition Type Resolution Waterfall Order (`get_transition_type_info`)

When resolving an `AceTransitionType` layout for an `AceTransitionConfig`, `AceLoadingScene` evaluates potential sources in the following priority order:

1. **Exported Scene Dictionary (`transition_types`)**: Matches transition search name against `@export var transition_types: Dictionary[String, AceTransitionType]` on the active `AceLoadingScene`.
2. **Global Project Settings**: Looks up global settings under `aceSceneManager/transition_types`.
3. **Default Fallback**: Instantiates a default blank `AceTransitionType.new()`.

### 4. Container & Progress Bar Resolution Fallbacks

- **Root Control Container (`get_transition_node`)**: Returns `info.transition_root_node`. If unassigned/null, falls back to returning the **first child `Control` node** in the loading scene hierarchy.
- **Progress Bar Node (`get_progress_bar_node`)**: Returns `info.progress_bar_node` if `has_progress_bar` is `true`. If unassigned/null, searches the container children for any node named `"ProgressBar"`.

---

## Step-by-Step Guide: Configuring a Custom `AceLoadingScene`

This guide walks through creating and configuring a custom loading screen scene (`.tscn`) step-by-step, including scene structure, `AnimationPlayer` setup, shader integration, `transition_types` configuration, and Project Settings registration.

### Step 1: Create Scene & Attach `AceLoadingScene` Script

1. In Godot 4, create a new scene with a **CanvasLayer** (or **Control**) as the root node.
2. Attach a GDScript extending `AceLoadingScene` (or `AceDefaultLoadingScene`):

```gdscript
@tool
extends AceLoadingScene
class_name MyCustomLoadingScene

var _selected_transition: AceTransitionConfig

func play_transition(transition: AceTransitionConfig) -> void:
	_selected_transition = get_transition_config(transition)
	
	# Resolve active transition container node and hide inactive containers
	var active_node: Control = get_transition_node(_selected_transition)
	for child in get_children():
		if child is Control:
			(child as Control).visible = (child == active_node)

	# Dynamically assign ShaderMaterial if configured on AceTransitionType
	setup_shader_material(_selected_transition)

	# Play transition-in animation
	var start_anim: String = _selected_transition.start if _selected_transition != null else ""
	if animation_player != null and not start_anim.is_empty() and animation_player.has_animation(start_anim):
		animation_player.play(start_anim)
		await animation_player.animation_finished

	loading_screen_ready.emit()

func finish_transition() -> void:
	# Play transition-out animation
	var end_anim: String = _selected_transition.end if _selected_transition != null else ""
	if animation_player != null and not end_anim.is_empty() and animation_player.has_animation(end_anim):
		animation_player.play(end_anim)
		await animation_player.animation_finished

	loading_screen_finished.emit()
	queue_free()

func _on_progress_changed(new_value: float) -> void:
	var pb_node: Control = get_progress_bar_node(_selected_transition)
	if pb_node is ProgressBar:
		(pb_node as ProgressBar).value = new_value * 100.0

func _on_load_finished() -> void:
	pass
```

---

### Step 2: Build the Node Hierarchy (Loading Scene Structure)

Organize your loading scene container nodes cleanly under the root node:

```text
MyCustomLoadingScene (CanvasLayer, extends AceLoadingScene)
├── Fade (Control - Fullscreen container for standard fade)
│   ├── Panel (Panel - Self-modulating black background)
│   └── ProgressBar (ProgressBar - Optional progress indicator)
├── Circle (Control - Fullscreen container for circle wipe)
│   └── TextureRect (TextureRect - Scaling radial gradient texture)
├── Shader (Control - Fullscreen container for shader wipe effects)
│   └── TransitionColor (ColorRect - Material-driven shader target)
└── AnimationPlayer (AnimationPlayer - Handles all transition animations)
```

> [!TIP]
> Group each transition type into its own top-level `Control` child under the root loading scene. `AceLoadingScene.get_transition_node()` will automatically toggle visibility for the active container.

---

### Step 3: Configure the `AnimationPlayer`

1. Add an **AnimationPlayer** node to the scene.
2. Select the root node of your loading scene and assign the `animation_player` export property to `NodePath("AnimationPlayer")`.
3. Create animation tracks for your start and end transitions:
   - **`fade_to_black`** (Start): Animate `Fade/Panel:self_modulate:a` from `0.0` to `1.0`.
   - **`fade_from_black`** (End): Animate `Fade/Panel:self_modulate:a` from `1.0` to `0.0`.
   - **`shader_fade_to_black`** (Start): Animate track `Shader/TransitionColor:material:shader_parameter/progress` from `0.0` to `1.0`.
   - **`shader_fade_from_black`** (End): Animate track `Shader/TransitionColor:material:shader_parameter/progress` from `1.0` to `0.0`.
   - **`horizontal_sweep_start`** (Start): Animate track `HorizontalSweep/TransitionColor:material:shader_parameter/progress` from `0.0` to `1.0`.
   - **`horizontal_sweep_end`** (End): Animate track `HorizontalSweep/TransitionColor:material:shader_parameter/progress` from `1.0` to `0.0`.

---

### Step 4: Configure `transition_types` in the Inspector

On the root node of your loading scene, expand the exported `transition_types` dictionary in the Inspector to register your layout mapping:

1. **Add Entry `"Fade"`**:
   - Sub-resource: `AceTransitionType`
   - `transition_root_node` = `NodePath("Fade")`
   - `has_progress_bar` = `true`
   - `progress_bar_node` = `NodePath("Fade/ProgressBar")`

2. **Add Entry `"Circle"`**:
   - Sub-resource: `AceTransitionType`
   - `transition_root_node` = `NodePath("Circle")`
   - `has_progress_bar` = `false`

3. **Add Entry `"ShaderFade"` or `"HorizontalSweep"` (Using Shaders)**:
   - Sub-resource: `AceTransitionType`
   - `transition_root_node` = `NodePath("Shader")`
   - `has_shader` = `true`
   - `shader_node` = `NodePath("Shader/TransitionColor")` *(Optional: defaults to `transition_root_node` if empty)*
   - `shader` = Assign your `.gdshader` resource (e.g. `res://addons/anomalyAcesSceneManager/shaders/horizontal_sweep.gdshader`)

> [!TIP]
> **Looking for more transition shaders?** A great place to find additional loading screen transition shaders (such as diamond wipes, dissolves, pixelations, blinds, etc.) is [GodotShaders.com Transition Shaders](https://godotshaders.com/shader/?orderby=relevance&order=DESC&q=transition).

---

### Step 5: Creating and Registering Transitions

#### Creating Transition Configs (`.tres`)
To keep `project.godot` clean, safe, and free from early-boot script parsing errors, transitions are stored as `.tres` resource files (`AceTransitionConfig`). You can create them using any of the following methods:

- **Method A: Godot Tools Menu (Fastest)**:
  1. In the top editor menu, go to **Project** &rarr; **Tools** &rarr; **Create Ace Transition Config...**
  2. Choose a save location and filename in the dialog (e.g., `res://Transitions/DefaultTransition.tres`).
  3. The editor automatically creates the `.tres` file, rescans the filesystem, and opens it directly in the **Inspector**.
  4. In the **Inspector**, configure `start` (enter-animation name), `end` (exit-animation name), and optional `loading_screen_path`.

- **Method B: FileSystem Dock**:
  1. In the **FileSystem** dock, right-click any folder &rarr; **Create New** &rarr; **Resource...**
  2. Search for **`AceTransitionConfig`** and save as `.tres`.
  3. Set properties in the **Inspector**.

- **Method C: Programmatic Creation**:
  ```gdscript
  AceTransitions.create_transition_config(
      "res://Transitions/DefaultTransition.tres",
      "circuit_fade_start",
      "circuit_fade_end",
      "res://Scenes/Global/Scenes/LoadingScene/LoadingScene.tscn"
  )
  ```

#### Registering Transitions in Project Settings
1. Open **Project Settings** &rarr; **General** &rarr; **Ace Scene Manager**.
2. **Default Loading Screen**: Set `aceSceneManager/default_loading_screen` to your default loading screen scene (e.g., `"res://addons/anomalyAcesSceneManager/scenes/DefaultLoadingScene/AceDefaultLoadingScene.tscn"`).
3. **Available Transitions**: In `aceSceneManager/available_transitions`, add key-value pairs mapping transition names to your `.tres` files:
   - Key: `"Default"`
   - Value: `"res://Transitions/DefaultTransition.tres"` (picked directly with the file browser)
4. Trigger transitions anywhere in code:
   ```gdscript
   AceSceneManager.load_scene("Login", "Default", scene_data)
   ```

---

## Scene Lifecycle & Signals (`load_finished` vs. `transition_completed`)

When `AceSceneManager.load_scene(...)` is called, the manager progresses through distinct phases:
1. **`transition_started(transition_name)`**: The loading screen is instantiated and begins the transition-in animation.
2. **Threaded Loading & `progress_changed(progress)`**: Background thread loads resources while progress updates are emitted.
3. **`load_finished`**: Background loading completes; the new scene is instantiated and added to the scene tree. Loading screens receive `_on_load_finished()` to snap progress bars to 100% or display completion prompts (e.g. *"Press Any Key"*).
4. **Transition Out (`finish_transition`)**: The loading screen plays its exit animation (or waits for user key press).
5. **`transition_completed`**: The exit animation completes, the loading screen is freed, and the newly loaded scene is completely uncovered and visible.

### What Happens by Default vs. What Needs `transition_completed`

| Aspect | Behavior by default | Do you need `transition_completed`? |
| :--- | :--- | :--- |
| **Mouse / GUI Clicks** | Blocked automatically because the loading screen is a high-layer `CanvasLayer` with `mouse_filter = STOP`. | **No** (the overlay absorbs clicks until it fades). |
| **Process / Physics Ticking** | Begins immediately when the scene enters the tree (`_ready()`, `_physics_process()`). | **Yes**, if you don't want enemies moving, timers counting down, or gravity ticking while hidden. |
| **Player Controls / Actions** | Key bindings (`Input.is_action_pressed()`) can respond unless gated. | **Yes**, to prevent characters moving or jumping before the screen is visible. |
| **Cutscenes / Level Intro** | Dialogue or intro sequences would start playing behind the black screen. | **Yes**, so intros trigger only once the view is clear. |

### Recommended Pattern in a Loaded Scene

In your loaded scene's script, you can gate gameplay initialization by awaiting `AceSceneManager.transition_completed` in `_ready()`:

```gdscript
func _ready() -> void:
	# 1. Setup scene state, HUD, or data
	set_process(false)
	set_physics_process(false)

	# 2. Wait until the transition animation has completely finished
	await AceSceneManager.transition_completed

	# 3. Enable gameplay / start round
	set_process(true)
	set_physics_process(true)
	start_level()
```

Or connect via a one-shot signal:

```gdscript
func _ready() -> void:
	AceSceneManager.transition_completed.connect(_on_scene_revealed, CONNECT_ONE_SHOT)

func _on_scene_revealed() -> void:
	# Start player controls, music, or level timers here
	pass
```

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
