class_name SfxPlayer
extends Node

## 効果音の再生を担当するコンポーネント。
## 各AudioStreamPlayerは子ノードとして静的配置し、シグナル経由で再生する。

@onready var _place_building: AudioStreamPlayer = $PlaceBuilding
@onready var _place_belt: AudioStreamPlayer = $PlaceBelt
@onready var _destroy_building: AudioStreamPlayer = $DestroyBuilding


func on_piece_placed(piece: Piece):
	if piece.piece_type == PieceData.Type.CONVEYOR:
		_place_belt.play()
	else:
		_place_building.play()


func on_piece_removed():
	_destroy_building.play()
