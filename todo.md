# todo

## ゲームプレイ・コンテンツ
- [ ] 裁断機

## リファクタリング
### Piece初期化APIの改善
- [x] `Piece.setup` の引数を辞書形式から型指定された個別引数に変更する
- [x] `Piece.gd` 内の不要になった `_get_rotated_ports` などのロジックを `PieceData` に完全に移行する（残骸の整理）
- [x] `GridManager` およびテストコードの `setup` 呼び出し箇所をすべて修正する
- [x] 不要になった `setup({"type": ...})` 形式のテストをクリーンアップする
- [x] `initialize` を `setup` にリネームして簡潔にする
- [x] `facility_type` を `role` にリネームする

### Piece相対座標化 (完了)
- [x] Piece: `hex_coordinates` プロパティを削除する
- [x] Piece: `get_hex_shape()` が回転状態に応じた相対形状を返すことを検証するテストを書く
- [x] Piece: `get_hex_shape()` を実装する
- [x] GridManager: `get_piece_occupied_hexes()` を `get_hex_shape()` を使った計算に置き換える
- [x] GridManager: `place_piece` で `Piece` に絶対座標を渡さないように変更する
- [x] GridManager: `_update_piece_neighbors` などのロジックを修正し、`Piece` の絶対座標プロパティに依存しないようにする

### piece, test_piece関連
- [ ] pieceクラスにおいて、機能部分とview部分が混在しているので, これを修正するべきか検討する
- [ ] チェスト(Storage)などのピースタイプに応じて、ItemContainerコンポーネントの生成構成を最適化する（Input/Outputで実体を共有するなど）
- [ ] crafter.gdにある、0.001等のマジックナンバーは不吉な臭いなので、これを修正する
- [ ] piece.gd: destinationよりもconnected_pieceの方が分かりやすいか、命名変更を検討する。
- [ ] PIECE_SCENEを使っているところを削除し、Piece.new()で代用する（純粋な単体テスト化）

### それ以外
- [ ] grid_managerのテストコードに内部クラスを追加して構造化する
- [ ] test_main: 内部クラスに整理し、命名を日本語に統一する
- [ ] paletteとpalette_uiの責務分離が分かりづらい。統合したほうが良いか検討する。

## 将来的なタスク・メモなど（AIはこれを編集・削除しないでください）
- [ ] マウスホイールでツールバーに割り当てられたピースの選択ができるようにする
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] 詳細表示モード時に、インプットとアウトプットの表示が重なる問題を修正する（レイアウト調整）。
- [ ] pallette uiをhexfrvrによせる。
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される