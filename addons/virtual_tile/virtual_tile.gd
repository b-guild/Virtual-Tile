@tool
extends Button
class_name VirtualTile

var tilemap: TileMap
var undo_redo: EditorUndoRedoManager

func erase_tile_cell(plugin: VirtualTilePlugin, position: Vector2i) -> void:
	pass

func draw_tile_cell(plugin: VirtualTilePlugin, position: Vector2i) -> void:
	pass

func erase_tile_rect(plugin: VirtualTilePlugin, position: Rect2i) -> void:
	pass

func draw_tile_rect(plugin: VirtualTilePlugin, position: Rect2i) -> void:
	pass


