@tool
class_name AceScale extends Object

# --- Constants for Scaling Properties ---
const FONT_OVERRIDE_KEYS := [
	"font_size", "normal_font_size", "bold_font_size", 
	"bold_italics_font_size", "italics_font_size", "mono_font_size"
]

const CONSTANT_OVERRIDE_KEYS := [
	"margin_left", "margin_top", "margin_right", "margin_bottom",
	"separation", "h_separation", "v_separation", "icon_max_width"
]

const VALID_RULE_KEYS := [
	"height_offset", "width_offset", "square_width_offset", 
	"flat", "font_size", "size_flags_vertical",
	"skip_scaling", "theme_properties"
]

const DEFAULT_REFERENCE_WIDTH := 1920.0
const DEFAULT_DOUBLE_SCALE_THRESHOLD := 3840.0
const DEFAULT_SCALE_STEP := 0.25

## Estimates display scale relative to a 1080p viewport (1920x1080).
## Normalizes multi-monitor bounds and rounds scale to the nearest step (e.g. 0.25).
static func get_estimated_scale(
	reference_width: float = DEFAULT_REFERENCE_WIDTH,
	double_scale_threshold: float = DEFAULT_DOUBLE_SCALE_THRESHOLD,
	scale_step: float = DEFAULT_SCALE_STEP
) -> float:
	var current_screen = DisplayServer.window_get_current_screen()
	var screen_size = DisplayServer.screen_get_size(current_screen)
	var os_scale = DisplayServer.screen_get_scale(current_screen)
	if os_scale <= 0:
		os_scale = 1.0
		
	var physical_width = float(screen_size.x)
	if os_scale > 1.0:
		if physical_width < reference_width:
			# Godot returned logical size. Multiply to get physical.
			physical_width = physical_width * os_scale
		elif physical_width > double_scale_threshold:
			# Godot returned double-scaled size. Divide to get physical.
			physical_width = physical_width / os_scale
		
	var logical_width = physical_width / os_scale
	var ratio = logical_width / reference_width
	var steps = 1.0 / scale_step
	var est = max(1.0, round(ratio * steps) / steps)
	
	print("[Scaling Debug] Current Screen: ", current_screen, " | OS Scale: ", os_scale, " | Physical Size: ", screen_size, " | Normalized Physical Width: ", physical_width, " | Logical Width: ", logical_width, " | Estimated Scale: ", est)
	AceLog.printLog(["[Scaling Debug] OS Scale: ", os_scale, " | Physical Size: ", screen_size, " | Physical Width: ", physical_width, " | Estimated Scale: ", est], AceLog.LOG_LEVEL.DEBUG)
	return est

## Parses and retrieves the target scale value from a settings dictionary.
## Falls back to the estimated scale if no custom scale is configured.
static func get_scale_from_settings(settings: Dictionary) -> float:
	if settings.get("is_custom_scale", false) == true:
		if settings.has("scale"):
			var custom_scale = settings.get("scale")
			if custom_scale is float or custom_scale is int:
				return float(custom_scale)
	return max(1.0, get_estimated_scale())

## Programmatically resizes an SVG texture to the specified target size.
## Interpolates using Lanczos to ensure high visual clarity.
static func scale_svg_icon(svg: Texture2D, target_size: int) -> Texture2D:
	if svg:
		var img = svg.get_image()
		if img:
			img.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
			return ImageTexture.create_from_image(img)
	return svg

## Recursively scales control nodes and theme properties inside the given node's tree.
##
## [code]custom_sizing[/code] accepts a Dictionary mapping node selectors to override rules.
## Supported rule properties:
## - [code]height_offset[/code] (int): Offset added to base height before scaling.
## - [code]width_offset[/code] (int): Offset added to base width before scaling.
## - [code]square_width_offset[/code] (int): Offset added to width if width and height are nearly equal.
## - [code]font_size[/code] (int): Sets a custom base font size to scale from.
## - [code]flat[/code] (bool): Sets flat styling on Button nodes.
## - [code]size_flags_vertical[/code] (int): Sets size_flags_vertical override.
## - [code]skip_scaling[/code] (bool): Bypasses scaling for this node (and its children) when [code]skip_marked[/code] is enabled.
## - [code]theme_properties[/code] (Array[String]): Lists custom Theme properties to scale.
static func apply_editor_scaling(
	node: Node, 
	scale: float, 
	skip_marked: bool = true, 
	custom_sizing: Dictionary = {}
) -> void:
	if node == null:
		return
		
	# Validate custom sizing dictionary only once at the root level of traversal
	if node.get_parent() == null or not node.get_parent().has_meta("original_custom_min_size"):
		_validate_custom_sizing(custom_sizing)
		
	# Resolve matching rule configuration for this node
	var sizing = _get_custom_sizing_for_node(node, custom_sizing)
	
	# Skip if bypass is requested and node is marked for skipping
	if skip_marked and sizing.get("skip_scaling", false) == true:
		return
		
	if node is Control:
		var custom_scaled = false
		
		# If sizing is explicitly configured in the rules dictionary
		if not sizing.is_empty():
			if sizing.has("size_flags_vertical"):
				node.size_flags_vertical = sizing["size_flags_vertical"]
				
			if sizing.has("flat"):
				node.flat = sizing["flat"]
				
			# Scale custom minimum size with cached base values
			var meta_key = "original_custom_min_size"
			var base_min = Vector2.ZERO
			if node.has_meta(meta_key):
				base_min = node.get_meta(meta_key)
			else:
				base_min = node.custom_minimum_size
				node.set_meta(meta_key, base_min)
				
			if base_min != Vector2.ZERO:
				var height_offset = sizing.get("height_offset", 0)
				var width_offset = sizing.get("width_offset", 0)
				var square_width_offset = sizing.get("square_width_offset", width_offset)
				
				var new_h = base_min.y + height_offset
				if base_min.x > 0:
					var new_w = base_min.x
					if abs(base_min.x - base_min.y) < 2:
						new_w = base_min.x + square_width_offset
					else:
						new_w = base_min.x + width_offset
					node.custom_minimum_size = Vector2(new_w, new_h) * scale
				else:
					node.custom_minimum_size = Vector2(0, new_h * scale)
					
			# Scale font size with cached/configured base values
			if sizing.has("font_size"):
				var base_font = sizing["font_size"]
				node.add_theme_font_size_override("font_size", int(round(base_font * scale)))
				
			custom_scaled = true
			
		# Fallback to standard property scaling (fonts & custom minimum size)
		if not custom_scaled:
			var meta_key = "original_custom_min_size"
			var base_min = Vector2.ZERO
			if node.has_meta(meta_key):
				base_min = node.get_meta(meta_key)
			else:
				base_min = node.custom_minimum_size
				node.set_meta(meta_key, base_min)
				
			if base_min != Vector2.ZERO:
				node.custom_minimum_size = base_min * scale
				
			# Scale standard theme font overrides cleanly from cached base values
			for key in FONT_OVERRIDE_KEYS:
				if node.has_theme_font_size_override(key):
					var f_meta = "original_font_size_" + key
					var orig_size = 0
					if node.has_meta(f_meta):
						orig_size = node.get_meta(f_meta)
					else:
						orig_size = node.get_theme_font_size(key)
						node.set_meta(f_meta, orig_size)
					node.add_theme_font_size_override(key, int(round(orig_size * scale)))
					
		# Scale standard theme constant overrides cleanly from cached base values
		for key in CONSTANT_OVERRIDE_KEYS:
			if node.has_theme_constant_override(key):
				var c_meta = "original_constant_" + key
				var orig_val = 0
				if node.has_meta(c_meta):
					orig_val = node.get_meta(c_meta)
				else:
					orig_val = node.get_theme_constant(key)
					node.set_meta(c_meta, orig_val)
				node.add_theme_constant_override(key, int(round(orig_val * scale)))
				
		# Scale generic theme properties listed in the custom sizing rule
		if sizing.has("theme_properties"):
			for prop_name in sizing["theme_properties"]:
				var p_meta = "original_prop_" + prop_name
				var orig = null
				if node.has_meta(p_meta):
					orig = node.get_meta(p_meta)
				else:
					orig = node.get(prop_name)
					if orig != null:
						node.set_meta(p_meta, orig)
				if orig != null and orig is Theme:
					node.set(prop_name, _scale_theme(orig, scale))
					
		# Scale the main theme resource on the control node itself
		if node.theme != null:
			var t_meta = "original_node_theme"
			var orig = null
			if node.has_meta(t_meta):
				orig = node.get_meta(t_meta)
			else:
				orig = node.theme
				node.set_meta(t_meta, orig)
			if orig != null:
				node.theme = _scale_theme(orig, scale)
				
		# Scale theme properties configured via rules
		if sizing.has("theme_properties"):
			var theme_properties = sizing["theme_properties"]
			if theme_properties is Array:
				scale_custom_themes(node, scale, theme_properties)
			
	for child in node.get_children():
		apply_editor_scaling(child, scale, skip_marked, custom_sizing)

## Resolves the matching rule dictionary from custom sizing configuration.
## Evaluates direct name matching, parent/child path matching, and class matching.
static func _get_custom_sizing_for_node(node: Control, custom_sizing: Dictionary) -> Dictionary:
	if custom_sizing.is_empty():
		return {}
		
	# 1. Exact node name match
	if custom_sizing.has(node.name):
		return custom_sizing[node.name]
		
	# 2. Relative ancestor/child path match (e.g. "Header/Button")
	for selector in custom_sizing:
		if "/" in selector:
			var parts = selector.split("/")
			if parts.size() == 2:
				var parent_name = parts[0]
				var child_name = parts[1]
				if node.name == child_name or node.get_class() == child_name:
					var p = node.get_parent()
					while p != null:
						if p.name == parent_name:
							return custom_sizing[selector]
						p = p.get_parent()
					
	# 3. Node class name match (checks class name or registered global script class name)
	var class_name_str = node.get_class()
	if custom_sizing.has(class_name_str):
		return custom_sizing[class_name_str]
		
	var scr = node.get_script()
	if scr:
		var global_name = scr.get_global_name()
		if not global_name.is_empty() and custom_sizing.has(global_name):
			return custom_sizing[global_name]
			
	return {}

## Validates the custom sizing rule properties and raises console warnings for unknown keys.
static func _validate_custom_sizing(custom_sizing: Dictionary) -> void:
	for selector in custom_sizing:
		var rules = custom_sizing[selector]
		if rules is Dictionary:
			for rule_key in rules:
				if not rule_key in VALID_RULE_KEYS:
					push_warning("AceScale: Unsupported scaling rule property '%s' for selector '%s'. Valid options: %s" % [rule_key, selector, str(VALID_RULE_KEYS)])

## Scales custom themes configured on a control.
static func scale_custom_themes(control: Control, scale: float, theme_keys: Array) -> void:
	if scale == 1.0 or control == null:
		return
		
	for key in theme_keys:
		var meta_key = "original_" + key
		var orig = null
		if control.has_meta(meta_key):
			orig = control.get_meta(meta_key)
		if orig == null:
			orig = control.get(key)
			if orig != null:
				control.set_meta(meta_key, orig)
		else:
			control.set(key, orig)
			
		var current = control.get(key)
		if current != null and current is Theme:
			control.set(key, _scale_theme(current, scale))

## Deprecated: Use scale_custom_themes instead. For backwards compatibility.
static func scale_table_themes(table_plugin: Control, scale: float, theme_keys: Array = ["header_theme", "header_cell_theme", "row_theme", "row_cell_theme"]) -> void:
	scale_custom_themes(table_plugin, scale, theme_keys)

## Deeply duplicates and scales the font sizes and constants of a Theme resource.
static func _scale_theme(theme: Theme, scale: float) -> Theme:
	var dup = theme.duplicate(true)
	for type in dup.get_type_list():
		for name in dup.get_font_size_list(type):
			var val = dup.get_font_size(name, type)
			dup.set_font_size(name, type, int(round(val * scale)))
		for name in dup.get_constant_list(type):
			var val = dup.get_constant(name, type)
			dup.set_constant(name, type, int(round(val * scale)))
	return dup
