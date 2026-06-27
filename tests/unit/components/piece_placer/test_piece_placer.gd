# gdlint:disable=constant-name
extends GutTest

const PiecePlacerScene = preload("res://scenes/components/piece_placer/piece_placer.tscn")
const CONVEYOR_SCENE = preload("res://scenes/components/piece/conveyor.tscn")
const MINER_SCENE = preload("res://scenes/components/piece/miner.tscn")
const HUB_SCENE = preload("res://scenes/components/piece/hub.tscn")


class TestPiecePlacement:
	extends GutTest

	var piece_placer: PiecePlacer
	var chunk: Chunk
	var shape_arch: Array[Hex]
	var shape_arch_rotated: Array[Hex]

	func before_all():
		shape_arch = [Hex.new(0, -1, 1), Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1)]
		shape_arch_rotated = [
			Hex.new(1, -1, 0), Hex.new(1, 0, -1), Hex.new(0, 1, -1), Hex.new(-1, 1, 0)
		]

	func before_each():
		chunk = Chunk.new()
		add_child_autofree(chunk)
		chunk.create_hex_grid(2)
		piece_placer = PiecePlacerScene.instantiate()
		add_child_autofree(piece_placer)
		piece_placer.setup(chunk)

	func after_each():
		await get_tree().process_frame

	func test_指定したHexに選択中のピースを配置できる():
		piece_placer.select_piece(CONVEYOR_SCENE)
		var target_hex = Hex.new(0, 0)
		var result = piece_placer.place_piece_at_hex(target_hex)
		assert_true(result, "Should return true on success")
		for offset in piece_placer.current_piece_shape:
			var h = Hex.add(target_hex, offset)
			assert_true(chunk.is_occupied(h))

	func test_回転メソッドを呼ぶと現在の形状が更新される():
		piece_placer.current_piece_shape = shape_arch
		piece_placer.rotate_current_piece()
		var current_shape = piece_placer.current_piece_shape
		assert_eq(current_shape.size(), shape_arch_rotated.size())
		for i in range(shape_arch_rotated.size()):
			assert_true(
				Hex.equals(current_shape[i], shape_arch_rotated[i]),
				"Rotated hex at index %d should be correct" % i
			)

	func test_select_pieceでシーンを外部からセットして配置できる():
		piece_placer.select_piece(CONVEYOR_SCENE)
		var target_hex = Hex.new(1, 1)
		var result = piece_placer.place_piece_at_hex(target_hex)
		assert_true(result, "シーンをセットすれば配置できるべき")
		assert_true(chunk.is_occupied(target_hex), "指定した座標が占有されているべき")


class TestPreview:
	extends GutTest

	var piece_placer: PiecePlacer
	var chunk: Chunk

	func before_each():
		chunk = Chunk.new()
		add_child_autofree(chunk)
		chunk.create_hex_grid(2)
		piece_placer = PiecePlacerScene.instantiate()
		add_child_autofree(piece_placer)
		piece_placer.setup(chunk)

	func after_each():
		await get_tree().process_frame

	func test_cursor_previewはマウス位置に追従する():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.update_hover(Vector2(10, 10))
		assert_eq(piece_placer.cursor_preview.position, Vector2(10, 10))

	func test_snap_previewはグリッドにスナップする():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.update_hover(Vector2(10, 10))
		assert_eq(piece_placer.snap_preview.position, Vector2(0, 0))

	func test_cursor_previewにタイルが描画される():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.update_hover(Vector2(10, 10))
		assert_gt(piece_placer.cursor_preview.get_child_count(), 0)

	func test_snap_previewにタイルが描画される():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.update_hover(Vector2(10, 10))
		assert_gt(piece_placer.snap_preview.get_child_count(), 0)

	func test_出力ポートを持つピースのプレビューに矢印が追加される():
		piece_placer.select_piece(CONVEYOR_SCENE)
		var shape_size = piece_placer.current_piece_shape.size()
		assert_eq(piece_placer.cursor_preview.get_child_count(), shape_size + 1)

	func test_出力ポートを持たないピースのプレビューには矢印が追加されない():
		# hub は出力ポートを持たない（矢印が出ない）ピース
		piece_placer.select_piece(HUB_SCENE)
		var shape_size = piece_placer.current_piece_shape.size()
		assert_eq(piece_placer.cursor_preview.get_child_count(), shape_size)

	func test_回転後にプレビューの矢印向きが変わる():
		piece_placer.select_piece(CONVEYOR_SCENE)
		var shape_size = piece_placer.current_piece_shape.size()
		var arrow_before = piece_placer.cursor_preview.get_child(shape_size)
		var rotation_before = arrow_before.rotation
		piece_placer.rotate_current_piece()
		var arrow_after = piece_placer.cursor_preview.get_child(shape_size)
		assert_ne(arrow_after.rotation, rotation_before)

	func test_コンベアのカーソルプレビューはHexTileを使わない():
		# ベルト画像でプレビューするため、旧来の色付き HexTile は使わない。
		piece_placer.select_piece(CONVEYOR_SCENE)
		var has_hextile = false
		for c in piece_placer.cursor_preview.get_children():
			if c is HexTile:
				has_hextile = true
		assert_false(has_hextile)

	func test_コンベアのカーソルプレビューはベルトスプライトを使う():
		piece_placer.select_piece(CONVEYOR_SCENE)
		var has_belt = false
		for c in piece_placer.cursor_preview.get_children():
			if c is Sprite2D and c.texture == PiecePlacer.BELT_PREVIEW_TEXTURE:
				has_belt = true
		assert_true(has_belt)


class TestDragBehavior:
	extends GutTest

	var piece_placer: PiecePlacer
	var chunk: Chunk

	func before_each():
		chunk = Chunk.new()
		add_child_autofree(chunk)
		chunk.create_hex_grid(3)
		piece_placer = PiecePlacerScene.instantiate()
		add_child_autofree(piece_placer)
		piece_placer.setup(chunk)

	func after_each():
		await get_tree().process_frame

	func test_ドラッグパスにコンベアが追加されるとシグナルが発火する():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		watch_signals(piece_placer)
		piece_placer.place_piece_at_hex(Hex.new(0, 0))
		assert_signal_emitted(piece_placer, "conveyor_path_extended")

	func test_コンベアドラッグのstop_drag後snap_previewはホバー位置にある():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		piece_placer.update_hover(Layout.hex_to_pixel(chunk.layout, Hex.new(1, 0)))
		piece_placer.update_hover(Layout.hex_to_pixel(chunk.layout, Hex.new(2, 0)))
		piece_placer.stop_drag()
		var expected = Layout.hex_to_pixel(chunk.layout, Hex.new(2, 0))
		assert_eq(piece_placer.snap_preview.position, expected)

	func test_削除ドラッグ中にhoverしたヘックスのピースが削除される():
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(1, 0))
		piece_placer.start_delete_drag()
		piece_placer.update_hover(Layout.hex_to_pixel(chunk.layout, Hex.new(0, 0)))
		piece_placer.update_hover(Layout.hex_to_pixel(chunk.layout, Hex.new(1, 0)))
		assert_false(chunk.is_occupied(Hex.new(0, 0)) or chunk.is_occupied(Hex.new(1, 0)))

	func test_stop_delete_drag後はhoverしてもピースが削除されない():
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(0, 0))
		piece_placer.start_delete_drag()
		piece_placer.stop_delete_drag()
		piece_placer.update_hover(Layout.hex_to_pixel(chunk.layout, Hex.new(0, 0)))
		assert_true(chunk.is_occupied(Hex.new(0, 0)))

	func test_重複ヘックスへのパス追加ではシグナルが発火しない():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		piece_placer.place_piece_at_hex(Hex.new(0, 0))
		watch_signals(piece_placer)
		piece_placer.place_piece_at_hex(Hex.new(0, 0))  # 同じヘックスに再追加
		assert_signal_not_emitted(piece_placer, "conveyor_path_extended")

	func test_start_dragを呼ぶとis_draggingがtrueになる():
		piece_placer.start_drag()
		assert_true(piece_placer.is_dragging)

	func test_stop_dragを呼ぶとis_draggingがfalseになる():
		piece_placer.start_drag()
		piece_placer.stop_drag()
		assert_false(piece_placer.is_dragging)

	func test_ドラッグ中にupdate_hoverで新しいヘックスに移動するとピースが設置される():
		piece_placer.select_piece(MINER_SCENE)
		piece_placer.start_drag()
		var target_hex = Hex.new(0, 0)
		var target_pos = chunk.hex_to_pixel(target_hex)
		piece_placer.update_hover(target_pos)
		assert_true(chunk.is_occupied(target_hex))

	func test_ドラッグ中に同じヘックスにhoverしても2回設置されない():
		piece_placer.select_piece(MINER_SCENE)
		piece_placer.start_drag()
		var target_pos = chunk.hex_to_pixel(Hex.new(0, 0))
		piece_placer.update_hover(target_pos)
		var placed_count_before = chunk.get_piece_count()
		piece_placer.update_hover(target_pos)
		assert_eq(chunk.get_piece_count(), placed_count_before)

	func test_stop_drag後はhoverが更新されても設置されない():
		piece_placer.select_piece(MINER_SCENE)
		piece_placer.start_drag()
		piece_placer.stop_drag()
		var count_before = chunk.get_piece_count()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		assert_eq(chunk.get_piece_count(), count_before)

	func test_ピースが未選択の状態でドラッグしても設置されない():
		piece_placer.start_drag()
		var count_before = chunk.get_piece_count()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		assert_eq(chunk.get_piece_count(), count_before)

	func test_コンベア選択時はドラッグ中にhoverしてもピースが設置されない():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		assert_false(chunk.is_occupied(Hex.new(0, 0)))

	func test_コンベアドラッグでstop_dragするとパス上のヘックスにコンベアが設置される():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.stop_drag()
		assert_true(chunk.is_occupied(Hex.new(0, 0)))

	func test_コンベアチェーンで最初のコンベアは次のヘックスへの方向を向く():
		# (0,0)→(1,0) のチェーン: 方向0(East)なのでrotation_state=0
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.stop_drag()
		var first = chunk.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(first.rotation_state, 0)

	func test_コンベアチェーンで最後のコンベアは最後の移動方向を向く():
		# (0,0)→(1,0)→(1,-1) のチェーン: 最後のステップはNW=方向2 → rotation=(0-2+6)%6=4
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, -1)))
		piece_placer.stop_drag()
		var last = chunk.get_piece_at_hex(Hex.new(1, -1))
		assert_eq(last.rotation_state, 4)

	func test_コンベアドラッグ中のsnap_previewはパス上のヘックス数のタイルを表示する():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		assert_eq(piece_placer.snap_preview.get_child_count(), 2)

	func test_stop_drag後にhoverするとsnap_previewが通常の1ピースゴーストに戻る():
		piece_placer.select_piece(CONVEYOR_SCENE)
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.stop_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(-1, 0)))
		assert_eq(piece_placer.snap_preview.get_child_count(), 1)


class TestOptimalConveyorDirection:
	extends GutTest

	var piece_placer: PiecePlacer
	var chunk: Chunk

	func before_each():
		chunk = Chunk.new()
		add_child_autofree(chunk)
		chunk.create_hex_grid(3)
		piece_placer = PiecePlacerScene.instantiate()
		add_child_autofree(piece_placer)
		piece_placer.setup(chunk)
		piece_placer.select_piece(CONVEYOR_SCENE)

	func after_each():
		await get_tree().process_frame

	func test_隣接ピースが出力を向けているとき直進方向を返す():
		# (1,0) に方向3(West)向きのコンベアを置くと (0,0) に向かって出力する
		# → (0,0) での最適出力方向は (0+3)%6=3 (West、直進)
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 3)
		var result = piece_placer._compute_optimal_conveyor_direction(Hex.new(0, 0), 0)
		assert_eq(result, 3, "Westからの入力に対し直進(West=3)を返すべき")

	func test_隣接ピースが出力を向けていないときfallbackを返す():
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 0)  # East向き＝(0,0)には向いていない
		var result = piece_placer._compute_optimal_conveyor_direction(Hex.new(0, 0), 2)
		assert_eq(result, 2, "出力が向いていないとき fallback_direction を返すべき")

	func test_複数の隣接ピースが出力を向けているときfallbackを返す():
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 3)  # (0,0)へ向けて出力
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(-1, 0), 0)  # (0,0)へ向けて出力
		var result = piece_placer._compute_optimal_conveyor_direction(Hex.new(0, 0), 1)
		assert_eq(result, 1, "複数入力が競合するとき fallback_direction を返すべき")

	func test_単一クリック配置で隣接ピースの出力に合わせた向きになる():
		# (1,0) にWest(3)向きコンベアを設置 → (0,0)へ向けて出力
		# (0,0) をクリック配置するとき、最適方向3(West)で設置されるべき
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 3)
		piece_placer.place_piece_at_hex(Hex.new(0, 0))
		var placed = chunk.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(placed.rotation_state, 3, "隣接出力に合わせてWest(3)向きで設置されるべき")

	func test_単一クリック配置で隣接ピースがなければcurrent_rotationで設置される():
		piece_placer.current_rotation = 2
		piece_placer.place_piece_at_hex(Hex.new(0, 0))
		var placed = chunk.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(placed.rotation_state, 2, "隣接出力がないとき current_rotation で設置されるべき")

	func test_ドラッグパス先頭で隣接ピースの出力に合わせた向きになる():
		# (-1,0) にEast(0)向きコンベアを設置 → (0,0)へ向けて出力
		# ドラッグ: (0,0)→(1,0) のとき先頭(0,0)は隣接入力に関係なくパス方向(East=0)で設置される
		# (shapez同様、パス方向が優先される)
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(-1, 0), 0)
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.stop_drag()
		var first = chunk.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(first.rotation_state, 0, "パス方向East(0)で設置されるべき")

	func test_ドラッグパス中間はパス前後の方向が優先される():
		# (0,0)→(1,0)→(2,0): 全てEast向きになる
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(2, 0)))
		piece_placer.stop_drag()
		var mid = chunk.get_piece_at_hex(Hex.new(1, 0))
		assert_eq(mid.rotation_state, 0, "中間コンベアはパス方向East(0)で設置されるべき")

	func test_ドラッグ終端のhexが占有済みピースのとき最後のコンベアはその方向を向く():
		# (1,0) にHUB(1マス)を設置。ドラッグ (0,0) → hover(1,0) でstop_drag
		# current_rotation=3 (West向き) だが、HUBはEast(direction=0)方向にあるので
		# 最後のコンベアは rotation=0 (East) になるべき
		chunk.place_piece(HUB_SCENE, Hex.new(1, 0))
		piece_placer.current_rotation = 3
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.stop_drag()
		var last = chunk.get_piece_at_hex(Hex.new(0, 0))
		assert_eq(last.rotation_state, 0, "最後のコンベアはHUB方向East(rotation=0)を向くべき")

	func test_ドラッグ終端のhexが空のとき最後のコンベアはパス進行方向を向く():
		# (0,0)→(1,0) とドラッグし (2,0) は空。(1,0) が East(rotation=0) になるべき
		piece_placer.current_rotation = 3
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.stop_drag()
		var last = chunk.get_piece_at_hex(Hex.new(1, 0))
		assert_eq(last.rotation_state, 0, "終端が空のとき進行方向East(rotation=0)を向くべき")

	func test_ドラッグ終端のhexが占有済みコンベアのとき既存が上書きされてパス方向を向く():
		# (1,0) にSouth(rotation=1)のコンベアを設置、その上で stop_drag
		# → East(rotation=0)に上書きされるべき
		chunk.place_piece(CONVEYOR_SCENE, Hex.new(1, 0), 1)
		piece_placer.current_rotation = 3
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		piece_placer.stop_drag()
		var updated = chunk.get_piece_at_hex(Hex.new(1, 0))
		assert_eq(updated.rotation_state, 0, "既存コンベアがEast(rotation=0)に上書きされるべき")

	func test_ドラッグ中に占有済みピースのhexはパスに追加されない():
		const SMELTER_SCENE = preload("res://scenes/components/piece/smelter_t2.tscn")
		chunk.place_piece(SMELTER_SCENE, Hex.new(1, 0))
		piece_placer.start_drag()
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(0, 0)))
		watch_signals(piece_placer)
		piece_placer.update_hover(chunk.hex_to_pixel(Hex.new(1, 0)))
		assert_signal_not_emitted(piece_placer, "conveyor_path_extended")
