Virtual Tile is a simple Godot 4.1 plugin that provides a tool for enhancing how we edit TileMaps.

A virtual tile is not a tile and so it cannot be in a TileMap. Instead, a virtual tile is a script that can programatically determine what tiles should be drawn into a TileMap. You select the virtual tile and then either click individual cells or rectangular areas and the virtual tile decides what to do with those cells and the surrounding cells. This could be used to create variations on terrain tiling, but it can be scripted to do whatever you might want while editing your TileMap. It can change which cells are being drawn based on context or procedurally generate large structures with a single click.

Virtual Tile provides:

* A UI that creates a bottom panel and automatically fills it with virtual tiles from your res://virtual_tiles directory.
* While the bottom panel is open, you can select tools to either edit the TileMap by individual cells ore by dragging rectangles, and methods are automatically called on the selected virtual tile to inform it of where in the TileMap you are clicking.
* The virtual tile script is given an interface that takes care of recording the changes for undo, so virtual tile edits can be undone and redone. This may be useful if the virtual tile does something unexpected.