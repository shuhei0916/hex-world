class_name Main
extends Node2D

const PaletteScript = preload("res://scenes/ui/palette/palette.gd")
const HexTileScene = preload("res://scenes/components/hex_tile/hex_tile.tscn")

@onready var hud: HUD = $HUD
@onready var grid_manager:= $GridManager

var palette: Palette
var preview_layer: Node2D
var current_piece_preview: Node2D

func _init():
	palette = PaletteScript.new()

func _ready():
	# Create Preview Layer
	preview_layer = Node2D.new()
	preview_layer.name = "PreviewLayer"
	add_child(preview_layer)
	
	current_piece_preview = Node2D.new()
	current_piece_preview.name = "CurrentPiecePreview"
	preview_layer.add_child(current_piece_preview)
	
	grid_manager.create_hex_grid(grid_manager.grid_radius)
	
	hud.setup_ui(palette)
	
	palette.active_slot_changed.connect(_on_active_slot_changed)
	_update_preview(palette.get_active_index())

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			if palette:
				var index = event.keycode - KEY_1
				palette.select_slot(index)
	elif event is InputEventMouseMotion:
		if current_piece_preview:
			var local_event = make_input_local(event)
			current_piece_preview.position = local_event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 左クリックでピースを配置
		var local_mouse_pos = make_input_local(event).position
		var clicked_hex = Layout.pixel_to_hex_rounded(grid_manager.layout, local_mouse_pos)
		
		var selected_piece_data = palette.get_piece_data_for_slot(palette.get_active_index())
		if not selected_piece_data.is_empty():
			var shape = selected_piece_data["shape"]
			
			if grid_manager.can_place(shape, clicked_hex):
				grid_manager.place_piece(shape, clicked_hex)
				print("piece has been placed!")
				# ピース配置後、プレビューを非表示にするなどの処理が必要になるが、
				# まずはテストを通すことに集中
				# TODO: プレビューを非表示にするロジックを追加
				# 例: _update_preview(-1) のようにして選択を解除するか、
				# preview_layer.visible = false にする
			else:
				print("piece cannot be placed...")
				

func _on_active_slot_changed(new_index: int, _old_index: int):
	_update_preview(new_index)

func _update_preview(slot_index: int):
	# Clear existing preview
	for child in current_piece_preview.get_children():
		child.queue_free()
	
	var piece_data = palette.get_piece_data_for_slot(slot_index)
	if piece_data.is_empty():
		return
	
	var shape = piece_data["shape"]
	var color = piece_data["color"]
	
	for hex_coord in shape:
		var hex_tile = HexTileScene.instantiate()
		current_piece_preview.add_child(hex_tile)
		
		var pos = grid_manager.hex_to_pixel(hex_coord)
		hex_tile.position = pos
		hex_tile.setup_hex(hex_coord)
		
		var sprite = hex_tile.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = color
