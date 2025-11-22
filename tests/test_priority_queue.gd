extends GutTest

# PriorityQueue - 動作するドキュメント
# A*アルゴリズム用の優先度付きキュー実装
class_name TestPriorityQueue

const PriorityQueue = preload("res://scripts/priority_queue.gd")

var priority_queue: PriorityQueue

func before_each():
	priority_queue = PriorityQueue.new()

func after_each():
	priority_queue = null

func test_PriorityQueueクラスが正しく初期化される():
	assert_not_null(priority_queue)
	assert_true(priority_queue is PriorityQueue)
	assert_true(priority_queue.empty())

func test_要素を優先度付きで追加できる():
	priority_queue.put("item1", 3.0)
	priority_queue.put("item2", 1.0) 
	priority_queue.put("item3", 2.0)
	
	assert_false(priority_queue.empty())

func test_最低優先度の要素を取得できる():
	priority_queue.put("high", 5.0)
	priority_queue.put("low", 1.0)
	priority_queue.put("medium", 3.0)
	
	var first = priority_queue.pop()
	assert_eq(first, "low")
	
	var second = priority_queue.pop()
	assert_eq(second, "medium")
	
	var third = priority_queue.pop()
	assert_eq(third, "high")
	
	assert_true(priority_queue.empty())

func test_同じ優先度の要素は追加順で取得される():
	priority_queue.put("first", 2.0)
	priority_queue.put("second", 2.0)
	priority_queue.put("third", 2.0)
	
	var result1 = priority_queue.pop()
	var result2 = priority_queue.pop()
	var result3 = priority_queue.pop()
	
	# 同じ優先度では追加順が保たれることを確認
	assert_eq(result1, "first")
	assert_eq(result2, "second")
	assert_eq(result3, "third")
