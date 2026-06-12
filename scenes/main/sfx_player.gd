class_name SfxPlayer
extends Node

## 効果音の再生を担当するコンポーネント。
## 各AudioStreamPlayerは子ノードとして静的配置し、シグナル経由で再生する。

@onready var _place_building: AudioStreamPlayer = $PlaceBuilding


func on_piece_placed(_piece: Piece):
	_place_building.play()
