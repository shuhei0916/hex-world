class_name ConveyorLogic
extends Node

const TRANSFER_TIME = 0.5

var _progress: float = 0.0
var _input: Node
var _output: Node


func _ready():
	_input = get_parent().get_node_or_null("Input")
	_output = get_parent().get_node_or_null("Output")


func _process(delta: float):
	if Engine.is_editor_hint():
		return
	tick(delta)


func tick(delta: float):
	if not _input or not _output:
		return
	if _input.get_total_item_count() == 0:
		_progress = 0.0
		return
	_progress += delta
	if _progress >= TRANSFER_TIME:
		_transfer_items()
		_progress = 0.0


func _transfer_items():
	var items = _input.inventory.get_item_names()
	for item_name in items:
		var count = _input.get_item_count(item_name)
		if count > 0:
			_input.consume_item(item_name, count)
			_output.add_item(item_name, count)
