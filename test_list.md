# 六角形座標システム テストリスト

## Red Blob Games 六角形ライブラリ移植計画

### Phase 1: 基本構造とデータ型
- [x] Hex座標の制約チェック（q + r + s = 0）
- [x] Vector2の使用（Pointクラスの代わりにGodotのBuilt-in使用）

### Phase 2: 基本的な六角形操作
- [x] hex_add関数の実装とテスト
- [x] hex_subtract関数の実装とテスト
- [x] hex_scale関数の実装とテスト
- [x] hex_rotate_left関数の実装とテスト
- [x] hex_rotate_right関数の実装とテスト
- [x] hex_directions配列の実装
- [x] hex_direction関数の実装とテスト
- [x] hex_neighbor関数の実装とテスト
- [x] hex_diagonals配列の実装
- [x] hex_diagonal_neighbor関数の実装とテスト

### Phase 3: 距離と補間
- [x] hex_length関数の実装とテスト
- [ ] hex_distance関数の実装とテスト
- [ ] hex_round関数の実装とテスト
- [ ] hex_lerp関数の実装とテスト
- [ ] hex_linedraw関数の実装とテスト

### Phase 4: 座標変換システム
- [ ] OffsetCoordクラスの実装
- [ ] EVEN/ODD定数の実装
- [ ] qoffset_from_cube関数の実装とテスト
- [ ] qoffset_to_cube関数の実装とテスト
- [ ] roffset_from_cube関数の実装とテスト
- [ ] roffset_to_cube関数の実装とテスト
- [ ] DoubledCoordクラスの実装
- [ ] qdoubled_from_cube関数の実装とテスト
- [ ] qdoubled_to_cube関数の実装とテスト
- [ ] rdoubled_from_cube関数の実装とテスト
- [ ] rdoubled_to_cube関数の実装とテスト
- [ ] オフセット-ダブル座標変換関数群の実装とテスト

### Phase 5: レイアウトとピクセル変換
- [ ] Orientationクラスの実装
- [ ] Layoutクラスの実装
- [ ] layout_pointy定数の実装
- [ ] layout_flat定数の実装
- [ ] hex_to_pixel関数の実装とテスト
- [ ] pixel_to_hex_fractional関数の実装とテスト
- [ ] pixel_to_hex_rounded関数の実装とテスト
- [ ] hex_corner_offset関数の実装とテスト
- [ ] polygon_corners関数の実装とテスト

### Phase 6: 全テストケースの移植
- [ ] Pythonのすべてのテスト関数をGutテストに移植
- [ ] test_hex_arithmetic関数のテスト
- [ ] test_hex_direction関数のテスト
- [ ] test_hex_neighbor関数のテスト
- [ ] test_hex_diagonal関数のテスト
- [ ] test_hex_distance関数のテスト
- [ ] test_hex_rotate_right関数のテスト
- [ ] test_hex_rotate_left関数のテスト
- [ ] test_hex_round関数のテスト
- [ ] test_hex_linedraw関数のテスト
- [ ] test_layout関数のテスト
- [ ] test_offset_roundtrip関数のテスト
- [ ] test_offset_from_cube関数のテスト
- [ ] test_offset_to_cube関数のテスト
- [ ] test_offset_to_doubled関数のテスト
- [ ] test_doubled_roundtrip関数のテスト
- [ ] test_doubled_from_cube関数のテスト
- [ ] test_doubled_to_cube関数のテスト