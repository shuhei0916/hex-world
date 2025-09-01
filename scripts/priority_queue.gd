class_name PriorityQueue
extends RefCounted

# PriorityQueue - A*アルゴリズム用の優先度付きキュー実装
# redblobgames implementationを参考にGDScriptで実装

var elements: Array = []
var counter: int = 0  # 挿入順序を追跡

func _init():
	pass

func empty() -> bool:
	return elements.is_empty()

func put(item, priority: float):
	# 要素を[priority, counter, item]の形で格納（counterで挿入順を保証）
	elements.append([priority, counter, item])
	counter += 1
	_heapify_up(elements.size() - 1)

func pop():
	if empty():
		push_error("PriorityQueue: Cannot get from empty queue")
		return null
		
	# ルート要素（最小優先度）を取得
	var result = elements[0][2]  # itemは3番目の要素
	
	# 最後の要素をルートに移動
	if elements.size() > 1:
		elements[0] = elements[elements.size() - 1]
		elements.pop_back()
		_heapify_down(0)
	else:
		elements.pop_back()
	
	return result

# ヒープ条件を上向きに修復
func _heapify_up(index: int):
	if index == 0:
		return
		
	var parent_index = (index - 1) / 2
	if _is_higher_priority(index, parent_index):
		# 親より高優先度の場合、交換
		var temp = elements[index]
		elements[index] = elements[parent_index]
		elements[parent_index] = temp
		_heapify_up(parent_index)

# ヒープ条件を下向きに修復
func _heapify_down(index: int):
	var highest_priority = index
	var left_child = 2 * index + 1
	var right_child = 2 * index + 2
	
	# 左の子と比較
	if left_child < elements.size() and _is_higher_priority(left_child, highest_priority):
		highest_priority = left_child
		
	# 右の子と比較
	if right_child < elements.size() and _is_higher_priority(right_child, highest_priority):
		highest_priority = right_child
	
	# 交換が必要な場合
	if highest_priority != index:
		var temp = elements[index]
		elements[index] = elements[highest_priority]
		elements[highest_priority] = temp
		_heapify_down(highest_priority)

# 優先度比較関数（priority値が小さいほど高優先度、同じ場合はcounter値が小さいほど高優先度）
func _is_higher_priority(index_a: int, index_b: int) -> bool:
	var priority_a = elements[index_a][0]
	var priority_b = elements[index_b][0]
	var counter_a = elements[index_a][1]
	var counter_b = elements[index_b][1]
	
	if priority_a != priority_b:
		return priority_a < priority_b
	else:
		return counter_a < counter_b