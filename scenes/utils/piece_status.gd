class_name PieceStatus
extends RefCounted

## 設置済みピースの「いま何をしているか」を判定し、ホバー表示用の文章にする。
## 工場のどこが止まっているか（材料待ち・搬出詰まり）を見つけるための情報。

enum State { NONE, WORKING, WAITING_INPUT, OUTPUT_BLOCKED, NO_OUTPUT_TARGET, NO_DEPOSIT }

const STATE_TEXTS = {
	State.WORKING: "稼働中",
	State.OUTPUT_BLOCKED: "搬出先が詰まっている",
	State.NO_OUTPUT_TARGET: "搬出先がない",
	State.NO_DEPOSIT: "鉱床がない",
}


# 加工する機械（Crafter を持つピース）の状態。それ以外のピースは NONE。
static func state_of(piece: Piece) -> State:
	var crafter = piece.crafter
	if crafter == null:
		return State.NONE
	if crafter.current_recipe == null:
		return State.NO_DEPOSIT if piece.piece_type == PieceData.Type.MINER else State.NONE
	if crafter.processing_progress > 0.0:
		return State.WORKING
	# 完成品が残っていて次を作れない場合は、材料より搬出側が原因
	if piece.ejector and piece.ejector.is_full():
		return State.OUTPUT_BLOCKED if piece.has_connected_piece() else State.NO_OUTPUT_TARGET
	if not crafter.get_missing_inputs().is_empty():
		return State.WAITING_INPUT
	return State.WORKING


static func missing_inputs(piece: Piece) -> Array:
	return piece.crafter.get_missing_inputs() if piece.crafter else []


# ホバー表示の本文（複数行）
static func describe(piece: Piece) -> String:
	var lines: Array[String] = []
	var hub = piece.get_node_or_null("Hub")
	var conveyor = piece.get_node_or_null("ConveyorLogic")
	var chest_input = piece.get_node_or_null("ChestInput")
	var chest_output = piece.get_node_or_null("ChestOutput")
	if chest_input:
		lines.append("倉庫: %s" % _storage_text(chest_input.get_storage()))
	elif chest_output:
		lines.append(_chest_output_text(chest_output))
		if not piece.has_connected_piece():
			lines.append(_no_target_text(piece))
	elif hub:
		lines.append(
			"目標: %s %d/%d" % [_item_name(hub.goal_item), hub.received_count, hub.goal_count]
		)
	elif piece.crafter:
		lines.append("状態: %s" % _state_text(piece))
		var recipe = piece.crafter.current_recipe
		if recipe:
			lines.append("生産: %s" % _item_names(recipe.outputs.keys()))
	elif conveyor:
		var held = conveyor.get_held_item()
		lines.append("運んでいるもの: %s" % (_item_name(held) if held != "" else "なし"))
		if not piece.has_connected_piece():
			lines.append(_no_target_text(piece))
	return "\n".join(lines)


# 実績と最大の生産速度。速度を持たないピースや止まっている Miner は空文字。
static func rate_text(piece: Piece) -> String:
	var crafter = piece.crafter
	if crafter == null or crafter.current_recipe == null:
		return ""
	return (
		"実績: %d/分（最大 %d/分）"
		% [
			roundi(crafter.get_measured_items_per_minute()),
			roundi(crafter.get_max_items_per_minute())
		]
	)


# 共有倉庫の中身。上限に達したアイテムには（満杯）を付ける
static func _storage_text(storage: SharedStorage) -> String:
	var contents = storage.get_contents() if storage else {}
	if contents.is_empty():
		return "空"
	var parts: Array[String] = []
	for item_id in contents:
		var text = "%s %d" % [_item_name(item_id), contents[item_id]]
		if not storage.can_add(item_id):
			text += "（満杯）"
		parts.append(text)
	return "、".join(parts)


static func _chest_output_text(chest_output: Node) -> String:
	var item = chest_output.selected_item
	if item == "":
		return "取り出すアイテム: 未選択（クリックして選ぶ）"
	var storage = chest_output.get_storage()
	var remaining = storage.get_count(item) if storage else 0
	return "取り出すアイテム: %s（倉庫に %d）" % [_item_name(item), remaining]


static func _state_text(piece: Piece) -> String:
	var state = state_of(piece)
	if state == State.WAITING_INPUT:
		return "材料待ち（%s が足りない）" % _item_names(missing_inputs(piece))
	return STATE_TEXTS.get(state, "停止中")


static func _no_target_text(piece: Piece) -> String:
	if piece.piece_type == PieceData.Type.SENDER:
		return "接続先の Receiver がない"
	return "搬出先がない"


static func _item_names(ids: Array) -> String:
	return "、".join(ids.map(func(id): return _item_name(id)))


static func _item_name(id: String) -> String:
	var item = ItemDB.get_item(id)
	return item.display_name if item else id
