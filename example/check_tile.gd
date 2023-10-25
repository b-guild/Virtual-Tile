@tool
extends VirtualTile

func erase_tile_cell(plugin: VirtualTilePlugin, pos: Vector2i) -> void:
	plugin.set_cell(0, pos, -1, Vector2i(-1, -1), -1)

func draw_tile_cell(plugin: VirtualTilePlugin, pos: Vector2i) -> void:
	if (pos.x + pos.y) % 2 == 0:
		plugin.set_cell(0, pos, 0, Vector2i(1,0), 0)
	else: plugin.set_cell(0, pos, 0, Vector2i(0,0), 0)
