# todo

## 現在のタスク (Current Focus)

### リファクタリング: デフォルトレシピ指定の削除
- [x] **RecipeDB機能拡張**: `RecipeDB` に `get_recipes_by_facility(facility_type: String) -> Array` を実装する。
	- [x] Test: `test_recipe.gd` に `test_指定した施設タイプのレシピ一覧を取得できる` を追加 (Red)。
	- [x] Implement: `scenes/utils/recipe.gd` に実装 (Green)。
- [x] **Piece初期化ロジック変更**: `Piece.setup` で `default_recipe_id` の代わりに `facility_type` からレシピを取得する。
	- [x] Test: `test_piece.gd` は既に抽象化済みだが、実際の `PieceDB` データを使う統合テスト的な動作が変わらないか確認。
	- [x] Implement: `scenes/components/piece/piece.gd` を修正。
- [x] **PieceDataの変更**: `default_recipe_id` を削除する。
	- [x] Refactor: `scenes/utils/piece_db.gd` (旧 piece_shapes.gd) からプロパティとコンストラクタ引数を削除。
	- [x] Verify: 全テストが通過することを確認。

### UI/UX改善
- [ ] **表示重なり問題の解決**: 詳細表示モード時に、インプットとアウトプットの表示が重なる問題を修正する（レイアウト調整）。

### ゲームプレイ・コンテンツ
- [ ] **出力ポート方向の調整**: 現在すべてのピースの出力が「右」など固定的な方向になっているため、形状ごとに適切な方向へ調整する（回転時の挙動含む）。
- [ ] **強化鉄板ラインの作成**:
	- [ ] 強化鉄板 (Reinforced Plate) のアイテム定義を追加（未存在の場合）。
	- [ ] 強化鉄板のレシピを追加。
	- [ ] 実際にラインを構築して動作確認する。
- [ ] output接続が行われていないピースで、アイテムが流入してしまっている問題を解決する。
- [ ] スタック数の導入について検討する

## 将来的なタスク
- [ ] クリックでパレットからピースを選択できるようにする
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] 即座にアイテムが接続先ピースに送られる挙動（upload lab方式）の方が正直な実装なのでは？？


## メモなど（AIはこれを編集・削除しないでください）
- [ ] 回転ロジックのコードレビュー、重心の変更
- [ ] pallette uiをhexfrvrによせる。
- [ ] マウスオーバーでピースの詳細情報ラベルが表示される
