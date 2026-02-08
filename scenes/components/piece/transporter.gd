class_name Transporter
extends Node

var source_container: ItemContainer


func setup(src_container: ItemContainer):
	source_container = src_container


func tick(_delta: float):
	# クールダウン廃止のため何もしない
	pass


func is_ready() -> bool:
	# 常に準備完了
	return true


func push(targets: Array):
	if not source_container or source_container._items.is_empty():
		return

	if targets.is_empty():
		return

	# 送れるアイテムがなくなるまで、または全ターゲットが満杯になるまでループ
	var still_pushing = true
	while still_pushing and not source_container._items.is_empty():
		still_pushing = false
		var items_to_push = source_container._items.keys().duplicate()

		for item_name in items_to_push:
			for target in targets:
				if target.has_method("add_item") and target.has_method("can_accept_item"):
					if target.can_accept_item(item_name):
						target.add_item(item_name, 1)
						source_container.consume_item(item_name, 1)
						still_pushing = true
						# 1個送れたら、まだ送れる可能性があるので続行
						# (複数種類のアイテムや複数ターゲットを公平に扱うため、一度ここでループを回す)
						break

			# 1つのアイテム種類を1個送ったら、次のアイテム種類へ（またはwhileの先頭へ）
			if still_pushing:
				break
