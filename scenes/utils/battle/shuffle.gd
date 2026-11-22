class_name Shuffle
## 乱数生成器を指定して配列を並べ替える。同じシードなら同じ並びになる。


static func in_place(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swapped: Variant = items[i]
		items[i] = items[j]
		items[j] = swapped
