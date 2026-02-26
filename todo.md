# todo

## ゲームプレイ・コンテンツ
### 自動化要素の強化
- [ ] 裁断機やプレス機など、ほかのroleも追加する
- [ ] 鉄パイプ、強化鉄板のレシピを追加する
- [ ] グリッドのランダムなヘックスに納品所を設置する実装を行う

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッドの上をキャラクターが移動したり（chessのような感じ）、敵と戦ったりできる要素（gloomhavenなど）

## リファクタリング
### piece, test_piece関連
- [ ] インベントリ周りのUIの改良
- [ ] pieceを継承シーンとし、それぞれのピースごとのシーンを作成する（miner.tscn, assembler.tscn, chest.tscnなど）

### コード品質改善（全スクリプトレビューより）
#### 優先度高
- [ ] `piece.gd`: `_update_visuals()` メソッドと `_ready()` からの呼び出しを削除（空メソッド）
- [ ] `island.gd`: `has_method("setup")` / `has_method("set_detail_mode")` を直接呼び出しに変更
- [ ] `speed_label.gd`: `class_name SpeedLabel` を追加
- [ ] `piece.gd`: `input_storage: PieceInput`, `output: Output` に型注釈強化
- [ ] `island.gd`: `_renderer: GridRenderer` に型注釈強化
- [ ] `piece_placer.gd`: `island: Island`, `setup(island_ref: Island)` に型注釈追加
- [ ] `hex_grid.gd`: `occupy_many(hexes: Array[Hex])` に型注釈追加
- [ ] `hud.gd`: `deselect()` メソッドを追加し、`main.gd` の `hud.on_slot_pressed(-1)` を `hud.deselect()` に変更

#### 将来検討
- [ ] Island を PieceRegistry / NeighborManager に分割（責務分離）
- [ ] InputHandler クラスを抽出し main.gd の入力処理を委譲
- [ ] HexGrid.hex_to_key() と GridRenderer._key() の重複ロジックを統一
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] output.gd の _push_items() をキューベースに最適化
- [ ] piece.gd / input.gd の `add_item` / `consume_item` インターフェースを整理

### それ以外
- [x] PiecePlacer をシーン化する（piece_placer.tscn）
	- [x] setup(island) だけで初期化できる（コンテナは内部管理）
	- [x] cursor_preview と snap_preview を内部コンテナとして持つ
	- [x] cursor_preview はマウス位置に追従する
	- [x] snap_preview はグリッドにスナップした位置に移動する
	- [x] cursor_preview にタイルが描画される
	- [x] snap_preview にタイルが描画される
- [ ] Islandをシーン化するべきかどうか検討する
- [ ] item_dbをtresファイルを使ったリソースファイルへ移行する
- [x] HUDがPiecePlacerを知っているのは密結合なので、これを修正する
	- [x] HUDは「何番のスロットが選ばれたか」という シグナル（signal） を発行するだけに留める
	- [x] それをmainが受け取って PiecePlacer を動かす形にする


## 検討中のタスク・メモなど（AIはこれを編集・削除しないでください）
- [ ] マウスホイールでツールバーに割り当てられたピースの選択ができるようにする
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] 詳細表示モード時に、インプットとアウトプットの表示が重なる問題を修正する（レイアウト調整）。
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
