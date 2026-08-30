# AceScale

`AceScale` is a generalized, high-DPI UI scaling utility class for Godot 4 editor plugins and custom UI controls. It enables resolution-independent layouts, handles multi-monitor scaling anomalies, and prevents `@tool` serialization traps.

---

## Core Features
1.  **DPI & Resolution Normalization**: Auto-estimates system scale factor.
2.  **Generic Property Scaling**: Scales standard font sizes, margins, separation constants, and SVG icons.
3.  **Compounding Scale Protection**: Caches design-time values in node metadata to allow continuous scaling changes without sizing drift or cumulative enlargement.
4.  **Strategy-3 Rules Dictionary**: Fine-tune custom scaling logic on a per-node, per-class, or per-path basis without hardcoding layout hierarchies.
5.  **Dynamic Theme Scaling**: Automatically duplicates and resizes font sizes and constants inside local node `Theme` resources or custom theme property slots.

---

## The Rules Dictionary (Strategy 3)

The rules dictionary specifies adjustments (such as sizing offsets, button flattening, or custom theme properties) that are applied to matching nodes *before* they are scaled.

### Schema Options (`VALID_RULE_KEYS`)
When defining rules inside the dictionary, use the following keys:

| Property | Type | Description |
| :--- | :--- | :--- |
| `height_offset` | `int` / `float` | Pixels added to the design-time base height before scaling. |
| `width_offset` | `int` / `float` | Pixels added to the design-time base width before scaling. |
| `square_width_offset` | `int` / `float` | Pixels added to width instead of `width_offset` if the control is square (width $\approx$ height). |
| `font_size` | `int` | Overrides the base font size to a specific value before scaling. |
| `flat` | `bool` | Sets the `flat` property of a `Button` to `true` / `false`. |
| `size_flags_vertical` | `int` | Overrides the `size_flags_vertical` flag (e.g. `Control.SIZE_SHRINK_CENTER`). |
| `skip_scaling` | `bool` | Bypasses scaling for this node (and its children) when `skip_marked` parameter is enabled on traversal. |
| `theme_properties` | `Array[String]` | Lists custom `Theme` resource property names on the node to duplicate and scale. |

### Selector Matching Types
Selectors can target nodes in three ways:
1.  **Class Selectors**: Keys matching Godot class names or registered script class names (e.g., `"Button"`, `"AceTablePlugin"`).
2.  **Name Selectors**: Keys matching exact node names (e.g., `"AddonCountLabel"`).
3.  **Relative Path Selectors**: Keys matching `"Parent/Child"` node hierarchies (e.g., `"Header/Button"`). Checks if the specified parent exists anywhere in the node's ancestor chain.

---

## Integration Blueprints

### 1. Basic Scaling (Automatic)
Call `apply_editor_scaling` inside your layout script. This will scale all standard font sizes and sizes:
```gdscript
@tool
extends Control

var plugin_ref = null

func initialize_view(p_ref, _extra_data) -> void:
	plugin_ref = p_ref
	_apply_scaling()

func _ready() -> void:
	# Guard check to prevent serialization traps in the editor
	if Engine.is_editor_hint() and plugin_ref != null:
		_apply_scaling()

func _apply_scaling() -> void:
	var current_scale = AceScale.get_estimated_scale()
	AceScale.apply_editor_scaling(self, current_scale)
```

### 2. Custom Scaling Rules Dictionary (Strategy 3)
Define a custom rule dictionary to tweak layout elements (e.g., header elements):
```gdscript
const MY_CUSTOM_RULES := {
	"Header/Button": {
		"flat": true,
		"height_offset": 8,
		"width_offset": 8,
		"font_size": 16
	},
	"Header/SearchBox": {
		"size_flags_vertical": Control.SIZE_SHRINK_CENTER,
		"font_size": 16
	},
	"AceTablePlugin": {
		"skip_scaling": true,
		"theme_properties": ["header_theme", "row_theme"]
	}
}

func _apply_scaling() -> void:
	var current_scale = AceScale.get_estimated_scale()
	# Apply scaling using custom rules
	AceScale.apply_editor_scaling(self, current_scale, true, MY_CUSTOM_RULES)
```

### 3. Dynamic Resize Binding
To support dynamic resizing when the window moves between monitors or resizes, connect the window signal:
```gdscript
func _ready() -> void:
	if Engine.is_editor_hint() and plugin_ref != null:
		_apply_scaling()
		get_window().size_changed.connect(_on_window_size_changed)

func _on_window_size_changed() -> void:
	_apply_scaling()
```
