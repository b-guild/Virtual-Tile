@tool
extends EditorPlugin
class_name VirtualTilePlugin

const VIRTUAL_TILE_PATH = "res://virtual_tiles"
const PANEL = preload("res://addons/virtual_tile/bottom_panel.tscn")
const UNDO_REVERSE = true
const RECT_COLOR = Color(1, 1 , 1, 0.5)

var panel: VirtualTilePanel
var panel_button: Button
var mouse_inside: bool = false
var erasing: bool = false
var initial_click: Vector2i
var rect_tool: bool = false
var tilemap: TileMap
var left_button_down: bool = false
var right_button_down: bool = false
var prev_position: Vector2i
var current_position: Vector2i

func _enter_tree() -> void:
	panel = PANEL.instantiate() as VirtualTilePanel
	var ei = get_editor_interface()
	var main = ei.get_editor_main_screen()
	main.mouse_entered.connect(_on_mouse_enter)
	main.mouse_exited.connect(_on_mouse_exit)
	var sys: EditorFileSystem = ei.get_resource_filesystem()
	sys.filesystem_changed.connect(_refresh)
	panel_button = add_control_to_bottom_panel(panel, "Virtual Tile")
	_make_visible(false)

func _exit_tree() -> void:
	if is_instance_valid(panel):
		remove_control_from_bottom_panel(panel)
		panel.queue_free()

func _refresh() -> void:
	var sys: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	var dir: EditorFileSystemDirectory = sys.get_filesystem_path(VIRTUAL_TILE_PATH)
	if not dir: return
	var count = dir.get_file_count()
	var list: Array[VirtualTile] = []
	for i in count:
		var path = dir.get_file_path(i)
		if not path.ends_with(".tscn"): continue
		var scene = ResourceLoader.load(path, "PackedScene") as PackedScene
		if not scene or not scene.can_instantiate(): continue
		var node = scene.instantiate()
		if not node is VirtualTile: continue
		list.push_back(node as VirtualTile)
	panel.set_tiles(list)
	
func _on_mouse_enter() -> void:
	mouse_inside = true

func _on_mouse_exit() -> void:
	mouse_inside = false
	
func _make_visible(visible: bool) -> void:
	panel_button.visible = visible

func _handles(object: Object) -> bool:
	return object is TileMap

func _edit(object: Object) -> void:
	tilemap = object as TileMap

func _clear() -> void:
	tilemap = null

func get_cell_source_id(layer: int, pos: Vector2i) -> int:
	return tilemap.get_cell_source_id(layer, pos)
func get_cell_atlas_coords(layer: int, pos: Vector2i) -> Vector2i:
	return tilemap.get_cell_atlas_coords(layer, pos)
func get_cell_alternative_tile(layer: int, pos: Vector2i) -> int:
	return tilemap.get_cell_alternative_tile(layer, pos)

func set_cell(layer: int, pos: Vector2i, source: int, atlas_cell: Vector2i, alt: int) -> void:
	var prev_source = tilemap.get_cell_source_id(layer, pos)
	var prev_atlas = tilemap.get_cell_atlas_coords(layer, pos)
	var prev_alt = tilemap.get_cell_alternative_tile(layer, pos)
	tilemap.set_cell(layer, pos, source, atlas_cell, alt)
	var undo_manager = get_undo_redo()
	undo_manager.add_do_method(tilemap, &"set_cell", layer, pos, source, atlas_cell, alt)
	undo_manager.add_undo_method(tilemap, &"set_cell", layer, pos, prev_source, prev_atlas, prev_alt) 

func _paint_cell(pos: Vector2i, paint: bool, drag: bool) -> void:
	var tile = panel.current_tile
	if not is_instance_valid(tile): return
	var undo_manager = get_undo_redo()
	var merge = UndoRedo.MERGE_DISABLE
	if drag: merge = UndoRedo.MERGE_ALL
	undo_manager.create_action("Draw virtual cell", merge, tilemap, UNDO_REVERSE)
	if paint: tile.draw_tile_cell(self, pos)
	else: tile.erase_tile_cell(self, pos)
	undo_manager.commit_action(false)

func paint_rect(pos: Rect2i, paint: bool) -> void:
	var tile = panel.current_tile
	if not is_instance_valid(tile): return
	var undo_manager = get_undo_redo()
	var merge = UndoRedo.MERGE_DISABLE
	undo_manager.create_action("Draw virtual cell rect", merge, tilemap, UNDO_REVERSE)
	if paint: tile.draw_tile_rect(self, pos)
	else: tile.erase_tile_rect(self, pos)
	undo_manager.commit_action(false)

func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not panel.visible or not is_instance_valid(tilemap)\
		or not is_instance_valid(tilemap.tile_set): return false
	if not event is InputEventWithModifiers: return false
	if event.is_echo(): return false
	var mode: VirtualTilePanel.Mode = panel.mode
	event = event as InputEventWithModifiers
	var undo_manager = get_undo_redo()
	rect_tool = panel.mode == VirtualTilePanel.Mode.RECT\
		or event.shift_pressed and event.ctrl_pressed
	var clicked: bool = false
	var released: bool = false
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		if !event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			right_button_down = false
			released = true
		if !event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			left_button_down = false
			released = true
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			right_button_down = true
			clicked = true
			erasing = true
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			left_button_down = true
			clicked = true
			erasing = false
	if event is InputEventMouseMotion:
		event = event as InputEventMouseMotion
		var tr := tilemap.get_viewport_transform() * tilemap.global_transform
		var pos := tr.affine_inverse() * Vector2(event.position)
		var event_position := tilemap.local_to_map(pos)
		prev_position = current_position
		if event_position == current_position:
			return false
		current_position = event_position
		if not left_button_down and not right_button_down:
			initial_click = event_position
		elif not rect_tool:
			_paint_cell(current_position, not erasing, true)
		update_overlays()
		return true
	
	if clicked:
		initial_click = current_position
		if not rect_tool:
			_paint_cell(current_position, not erasing, false)
		return true
	if released:
		if rect_tool:
			var x0 = mini(initial_click.x, current_position.x)
			var y0 = mini(initial_click.y, current_position.y)
			var x1 = maxi(initial_click.x, current_position.x)
			var y1 = maxi(initial_click.y, current_position.y)
			var area := Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)
			paint_rect(area, not erasing)
		update_overlays()
		return true
	return false

func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not mouse_inside or not panel.visible\
		or not is_instance_valid(tilemap)\
		or not is_instance_valid(tilemap.tile_set):
		return
	var transform := tilemap.get_viewport_transform() * tilemap.global_transform
	var area: Rect2i
	if rect_tool and (left_button_down or right_button_down):
		area = Rect2i(initial_click, current_position - initial_click).abs()
	else:
		area = Rect2i(current_position, Vector2i(0,0))
	var offset = tilemap.tile_set.tile_size / 2.0
	var start = area.position
	var end = area.end + Vector2i(1,1)
	var shortcut := PackedVector2Array([
		tilemap.map_to_local(start) - offset,
		tilemap.map_to_local(Vector2i(end.x, start.y)) - offset,
		tilemap.map_to_local(end) - offset,
		tilemap.map_to_local(Vector2i(start.x, end.y)) - offset
	])
	overlay.draw_colored_polygon(transform * shortcut, RECT_COLOR)


