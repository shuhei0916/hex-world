@tool
class_name Conveyor
extends Piece

## コンベア専用ピース。容量1・位置ベースでアイテムを搬送する。


func can_accept_item(_item_name: String) -> bool:
	return input_storage.get_total_item_count() + output.get_total_item_count() == 0
