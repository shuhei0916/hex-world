@tool
class_name Conveyor
extends Piece

## コンベア専用ピース。容量1・位置ベースでアイテムを搬送する。
## インベントリを持たず、保持アイテムの管理は $ConveyorLogic に委譲する。

@onready var _logic: ConveyorLogic = get_node_or_null("ConveyorLogic")


func can_accept_item(_item_name: String) -> bool:
	return _logic.can_accept()


func add_item(item_name: String, _amount: int):
	_logic.receive_item(item_name)


func get_item_count(item_name: String) -> int:
	return 1 if _logic.held_item == item_name else 0


func set_connected_pieces(pieces: Array) -> void:
	_logic.connected_pieces = pieces


func get_connected_pieces() -> Array:
	return _logic.connected_pieces
