class_name ConveyorOrienter
extends RefCounted

# コンベアの向きの自動調整（shapez の computeOptimalDirectionAndRotationVariantAtTile 相当）。
# chunk に置いてあるピースを見て、新しく置くコンベアの向きと、周りのベルトの向き直しを決める

var chunk: Chunk


func _init(chunk_ref: Chunk) -> void:
	chunk = chunk_ref


# hex にコンベアを1つ置くときの [出口の方向, 入力側（-1 は真後ろ）]。out は手持ちの向き。
# - 真後ろから入れてくる相手がいれば直進
# - 入れてくる相手が1つだけなら、出口はそのままで、その相手の側から受ける曲がり
#   （相手が正面にいるときは曲がれないので、相手から遠ざかる直進に反転する）
# - 入れてくる相手がいなければ、正面が空いていて横に受け取るベルトが1つだけあるとき、そちらへ曲がる
func orientation_at(hex: Vector2i, out: int) -> Array:
	var back := (out + 3) % 6
	var feeders := _port_feeders(hex)
	if back in feeders or feeders.size() >= 2:
		return [out, -1]
	if feeders.size() == 1:
		var feeder: int = feeders[0]
		if feeder == out:
			return [back, -1]
		return [out, feeder]
	var turn := _turn_toward_taker(hex, out, back)
	if turn >= 0:
		return [turn, back]
	return [out, -1]


# hex へ出力ポートを向けている隣のピースの方向（0-5）
func _port_feeders(hex: Vector2i) -> Array:
	var directions := []
	for direction in range(6):
		var neighbor = chunk.get_piece_at_hex(Hex.neighbor(hex, direction))
		if neighbor == null or neighbor == chunk.get_piece_at_hex(hex):
			continue
		for port in chunk.get_output_ports_on_grid(neighbor):
			if Hex.neighbor(port["hex"], port["direction"]) == hex:
				directions.append(direction)
				break
	return directions


# 正面（out）が空いていて、横（out・input 以外）に hex から受け取るベルトが1つだけあれば、その方向。
# なければ -1。ベルトは入力側でだけ受け取るので、入力側が hex を向いているベルトだけを数える
func _turn_toward_taker(hex: Vector2i, out: int, input: int) -> int:
	if chunk.get_piece_at_hex(Hex.neighbor(hex, out)) != null:
		return -1
	var takers := []
	for direction in range(6):
		if direction == out or direction == input:
			continue
		var neighbor = chunk.get_piece_at_hex(Hex.neighbor(hex, direction))
		if neighbor != null and neighbor.is_conveyor():
			if neighbor.belt_input_side() == (direction + 3) % 6:
				takers.append(direction)
	return takers[0] if takers.size() == 1 else -1


# プレイヤーが hexes に置いた／撤去したあと、その周りのベルトの向きを直す
# （shapez の updateSurroundingBeltPlacement 相当）。セーブの読み込みなど、chunk に直接置くときは行わない
func reorient_around(hexes: Array) -> void:
	var visited := {}
	for hex in hexes:
		for direction in range(6):
			var neighbor_hex = Hex.neighbor(hex, direction)
			if neighbor_hex in hexes or visited.has(neighbor_hex):
				continue
			visited[neighbor_hex] = true
			var belt = chunk.get_piece_at_hex(neighbor_hex)
			if belt != null and belt.is_conveyor():
				_reorient_belt(neighbor_hex, belt)


# 置いてあるベルト1つの向き直し。いま受け取れているベルトの入力側は変えない。
# - 入力側に相手がいなくなっていて、入れてくる相手が（正面以外に）1つだけあれば、その側から受ける
# - 正面が空いていて、横に受け取るベルトが1つだけあれば、そちらへ曲がる
func _reorient_belt(hex: Vector2i, belt: Piece) -> void:
	var out := belt.output_direction()
	var input := belt.belt_input_side()
	var new_input: int = belt.input_direction
	if not input in chunk.get_feeding_directions(hex):
		var feeders = _port_feeders(hex).filter(func(d): return d != out)
		if feeders.size() == 1:
			input = feeders[0]
			new_input = input
	var new_out := out
	var turn := _turn_toward_taker(hex, out, input)
	if turn >= 0:
		new_out = turn
		new_input = input
	if new_out == out and new_input == belt.input_direction:
		return
	chunk.reorient_conveyor(hex, Hex.rotation_between(belt.port_direction, new_out), new_input)
