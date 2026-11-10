extends RefCounted
## 分岐コンベアにアイテムを流し続け、分岐元のアイテムアイコンの位置を毎フレーム出力する。
## 確認したいこと: アイコンが入口→中心→出口を連続的に動き、別のパスへ飛び移らないこと。
##
## 配置（アクティブチャンク）: 本線 (-1,0)→(0,0)→(1,0)→(2,0)（East）、
## (0,0) から (1,-1)→(2,-2)（NE）へ分岐。分岐元は (0,0)。
## 下流に搬出先が無いので、しばらくすると分岐の両側が詰まる。
## EXTEND_FRAME で NE 側の分岐を1マス延長する（「片方の分岐だけ延長すると瞬間移動する」バグの再現操作）。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const FRAMES = 1500
const EXTEND_FRAME = 1100
const JUMP_THRESHOLD = 12.0  # 1フレームでこれ以上動いたら「飛び移り」とみなす（px）


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	for q in [-1, 0, 1, 2]:
		chunk.place_piece(CONVEYOR, Hex.new(q, 0), 0)
	chunk.place_piece(CONVEYOR, Hex.new(1, -1), 5)
	chunk.place_piece(CONVEYOR, Hex.new(2, -2), 5)

	var feeder: Piece = chunk.get_piece_at_hex(Hex.new(-1, 0))
	var origin: Piece = chunk.get_piece_at_hex(Hex.new(0, 0))
	var logic: ConveyorLogic = origin.get_node("ConveyorLogic")
	var icon: Sprite2D = origin.get_node("ConveyorVisuals/ItemIcon")
	print("[scenario] origin connections=%d" % logic.get_connected_pieces().size())

	var prev = null
	var jumps := 0
	var max_step := 0.0
	var prev_target := -2
	for frame in FRAMES:
		if frame == EXTEND_FRAME:
			chunk.place_piece(CONVEYOR, Hex.new(3, -3), 5)
			print("f%03d [extend] NE 側の分岐を (3,-3) へ延長" % frame)
		if feeder.get_node("ConveyorLogic").can_accept_item("iron_ore"):
			feeder.add_item("iron_ore", 1)
		await scene.get_tree().process_frame
		var shown = icon.visible
		var pos: Vector2 = icon.position
		var ratio = logic.get_progress_ratio()
		var line = (
			"f%03d visible=%s ratio=%.2f target=%d pos=(%.1f,%.1f)"
			% [frame, shown, ratio, logic.get_target_direction(), pos.x, pos.y]
		)
		# 同じアイテムが進んでいる間（比率が増えている間）の移動量だけを見る
		if shown and prev != null and ratio >= prev.ratio:
			var step = pos.distance_to(prev.pos)
			max_step = maxf(max_step, step)
			if step > JUMP_THRESHOLD:
				jumps += 1
				line += "  <-- JUMP %.1fpx" % step
		prev = {"pos": pos, "ratio": ratio} if shown else null
		var target = logic.get_target_direction()
		if frame % 50 == 0 or "JUMP" in line or target != prev_target:
			print(line)
		prev_target = target
	print("[scenario] max_step=%.1fpx jumps=%d" % [max_step, jumps])
