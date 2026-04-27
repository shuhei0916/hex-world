# todo

## ゲームプレイ・コンテンツ
### 自動化要素の強化
- [ ] 強化鉄板のレシピを追加する（複数入力対応後）
- [ ] mixerでscrewを生産するなど、直感的でないレシピを調整する。
- [ ] 鉄板を10個納品するなどのミッションを追加する

### 納品所（Delivery Zone）実装
- [x] PieceData.Type.DELIVERY が存在する
- [x] Delivery.setup(item_name, count) で goal_item と goal_count を設定できる
- [x] Delivery.received_count の初期値は 0
- [x] Delivery.add_received(1) で received_count が 1 増える
- [x] received_count < goal_count のとき is_completed() は false
- [x] received_count >= goal_count のとき is_completed() は true
- [x] Island.get_outer_hexes() が外縁ヘックス（max(|q|,|r|,|s|)==radius）のみを返す
- [x] Island.get_outer_hexes() が内側のヘックスを含まない
- [x] Island.remove_piece_at() が DELIVERY ピースに対して false を返す（削除拒否）
- [ ] minerが鉱石を採掘する際、地面が鉱石タイルでないといけない、などの制約を設ける
- [ ] 地面のタイルを多様化させる（kenney assetsを使うのもありかも）

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッドの上をキャラクターが移動したり（chessのような感じ）、敵と戦ったりできる要素（gloomhavenなど）

## リファクタリング

### piece, test_piece関連
- [ ] ピースの設置前プレビューは既存ピースのアイコンより手前に表示されるように変更する。
- [ ] いまはoutputとinputを同じへクスに表示しているが、これを別々のへクスに表示したい。
- [ ] 個別シーンファイル化（miner.tscn, smelter.tscn）は果たして必要だったのか、検討する。

#### 将来検討
- [ ] InputHandler クラスを抽出し main.gd の入力処理を委譲
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
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
