@tool
class_name _AceTableCell extends Node

func compose_cell(theme: Theme, cell_node: Node, col_def: AceTableColumnDef) -> Node:
	var cell_container: PanelContainer = PanelContainer.new()
	var cell_margin: MarginContainer = MarginContainer.new()

	if col_def.columnType == AceTableConstants.ColumnType.SELECTION:
		cell_container.size_flags_stretch_ratio = 0.1
	
	cell_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell_container.set_theme(theme)
	cell_container.name = cell_node.name + "PC"
	cell_margin.add_child(cell_node)
	cell_margin.name = cell_node.name + "MC"
	cell_container.add_child(cell_margin)
	return cell_container
