class_name SfxPlayer
extends Node

## 効果音の再生を担当するコンポーネント。
## 各AudioStreamPlayerは子ノードとして静的配置し、シグナル経由で再生する。

@onready var _place_building: AudioStreamPlayer = $PlaceBuilding
@onready var _place_belt: AudioStreamPlayer = $PlaceBelt
@onready var _destroy_building: AudioStreamPlayer = $DestroyBuilding
@onready var _ui_click: AudioStreamPlayer = $UiClick


func on_piece_placed(piece: Piece):
	# コンベアはドラッグパス追加時(conveyor_path_extended)に1本ずつ鳴らすため、
	# リリース時の一括設置では重ねて鳴らさない
	if piece.piece_type == PieceData.Type.CONVEYOR:
		return
	_place_building.play()


func on_conveyor_path_extended():
	_place_belt.play()


func on_piece_removed():
	_destroy_building.play()


func on_slot_selected(scene: PackedScene):
	if scene:
		_ui_click.play()
