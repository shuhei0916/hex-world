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
### feature/refactor-piece-types

#### Step 1: Type enum と role 文字列の統一（リファクタリング）
- [x] PieceData.Type を機能名にリネーム（BEE→MINER, WORM→SMELTER, WAVE→ASSEMBLER, BAR→CONVEYOR, PISTOL→CUTTER, PROPELLER→MIXER, ARCH→PAINTER）
- [x] role 文字列を機能名に統一（"hoge"→"conveyor", "foo"→"cutter", "bar"→"mixer", "hoho"→"painter", "constructor"→"assembler"）
- [x] FACILITY_COLORS のキーを新 role 名に更新
- [x] hud.gd の _assignments を新 Type 名に更新
- [x] 全テストファイルの Type・role 参照を新名称に更新

#### Step 2: ピース個別シーン化（CHEST は保留）
- [ ] PieceData に scene フィールドを追加する
- [ ] PieceData.get_data(Type.MINER) が null でない scene を返す
- [ ] PieceData.get_data(Type.SMELTER) が null でない scene を返す
- [ ] PieceData.get_data(Type.ASSEMBLER) が null でない scene を返す
- [ ] miner.tscn を piece.tscn の継承シーンとして作成し、Input ノードを持たない
- [ ] smelter.tscn を piece.tscn の継承シーンとして作成する
- [ ] assembler.tscn を piece.tscn の継承シーンとして作成する
- [ ] island.place_piece() が piece.tscn の固定参照ではなく data.scene を使う

### piece, test_piece関連
- [ ] インベントリ周りのUIの改良

#### 将来検討
- [x] Island を PieceRegistry / NeighborManager に分割（責務分離）
- [ ] InputHandler クラスを抽出し main.gd の入力処理を委譲
- [x] HexGrid.hex_to_key() と GridRenderer._key() の重複ロジックを統一（Hex.to_key() に集約）
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] output.gd の _push_items() をキューベースに最適化
- [ ] piece.gd / input.gd の `add_item` / `consume_item` インターフェースを整理
- [ ] input.gd / output.gd の共通 InventoryContainer 基底クラスを抽出する
- [ ] OutputPort の複数ポート対応テストを追加する

### それ以外
- [ ] item_dbをtresファイルを使ったリソースファイルへ移行する

## 検討中のタスク・メモなど（AIはこれを編集・削除しないでください）
- [ ] マウスホイールでツールバーに割り当てられたピースの選択ができるようにする
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] 詳細表示モード時に、インプットとアウトプットの表示が重なる問題を修正する（レイアウト調整）。
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
