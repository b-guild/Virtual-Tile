@tool
extends VBoxContainer
class_name VirtualTilePanel

const VIRTUAL_TILE_GROUP = preload("res://addons/virtual_tile/toolbar_group.tres")

signal mode_changed

@onready
var paintButton: Button = $Toolbar/PaintButton
@onready
var rectButton: Button = $Toolbar/RectButton
@onready
var info_label: Label = $Toolbar/Info
@onready
var tiles_node: Control = $Tiles

enum Mode {
	NONE,
	PAINT,
	RECT
	}

var current_tile: VirtualTile:
	get: return current_tile
	set(value):
		current_tile = value
		info_label.text = current_tile.scene_file_path

var _inner_mode: Mode
var mode: Mode:
	get: return _inner_mode
	set(value):
		_inner_mode = value
		paintButton.set_pressed_no_signal(_inner_mode == Mode.PAINT)
		rectButton.set_pressed_no_signal(_inner_mode == Mode.RECT)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	paintButton.pressed.connect(_on_mode_button)
	rectButton.pressed.connect(_on_mode_button)
	
func _on_mode_button() -> void:
	_inner_mode = Mode.NONE
	if paintButton.button_pressed:
		_inner_mode = Mode.PAINT
	if rectButton.button_pressed:
		_inner_mode = Mode.RECT

func set_tiles(tiles: Array[VirtualTile]) -> void:
	for n in tiles_node.get_children():
		n.queue_free()
	for n in tiles:
		tiles_node.add_child(n)
		n.button_group = VIRTUAL_TILE_GROUP
		n.toggle_mode = true
		n.pressed.connect(_on_tile_selected)

func _on_tile_selected() -> void:
	var info: String = ""
	for n in tiles_node.get_children():
		if n.button_pressed:
			current_tile = n as VirtualTile
			return
