@tool
extends Button
class_name VirtualTile

## Called when the user erases an individual cell using this tile.
## By default nothing happens. Override this to draw something into the TileMap.
## Edit the TileMap using the set_cell method of the plugin in order to make
## the changes undoable.
func erase_tile_cell(plugin: VirtualTilePlugin, pos: Vector2i) -> void:
	pass

## Called when the user draws an individual cell using this tile.
## By default nothing happens. Override this to draw something into the TileMap.
## Edit the TileMap using the set_cell method of the plugin in order to make
## the changes undoable.
func draw_tile_cell(plugin: VirtualTilePlugin, pos: Vector2i) -> void:
	pass

## Called when the user erases a rectangle using this cell.
## By default, it erases each indvidual cell within the given rectangle.
func erase_tile_rect(plugin: VirtualTilePlugin, area: Rect2i) -> void:
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			erase_tile_cell(plugin, Vector2i(x,y))

## Called when the user draws a rectangle using this cell.
## By default, it draws each indvidual cell within the given rectangle.
func draw_tile_rect(plugin: VirtualTilePlugin, area: Rect2i) -> void:
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			draw_tile_cell(plugin, Vector2i(x,y))


