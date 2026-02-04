class_name Transporter
extends Node

var source_container: ItemContainer
var transfer_rate: float = 1.0
var transfer_cooldown: float = 0.0

func setup(src_container: ItemContainer):
	source_container = src_container

func tick(delta: float):
	if transfer_cooldown > 0:
		transfer_cooldown -= delta

func is_ready() -> bool:
	return transfer_cooldown <= 0

func push(targets: Array):
	if transfer_cooldown > 0:
		return

	if not source_container or source_container._items.is_empty():
		return

	if targets.is_empty():
		return

	var items_to_push = source_container._items.keys().duplicate()
	
	for item_name in items_to_push:
		for target in targets:
			if target.has_method("add_item") and target.has_method("can_accept_item"):
				if target.can_accept_item(item_name):
					target.add_item(item_name, 1)
					source_container.consume_item(item_name, 1)
					
					transfer_cooldown = transfer_rate
					return # 1個送ったら終了
