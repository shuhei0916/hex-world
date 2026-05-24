# todo

## ゲームプレイ・コンテンツ
### 自動化要素の強化
- [ ] 強化鉄板のレシピを追加する（複数入力対応後）
- [ ] mixerでscrewを生産するなど、直感的でないレシピを調整する。

### ドラッグ設置
- [x] start_drag() を呼ぶと is_dragging が true になる
- [x] stop_drag() を呼ぶと is_dragging が false になる
- [x] ドラッグ中に update_hover で新しいヘックスに移動するとピースが設置される
- [x] ドラッグ中に同じヘックスに連続して hover しても 2 回設置されない
- [x] stop_drag() 後は hover が更新されても設置されない
- [ ] ピースが未選択の状態でドラッグしても設置されない

### 納品所（Delivery Zone）実装
- [ ] 地面のタイルを多様化させる（kenney assetsを使うのもありかも）

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッドの上をキャラクターが移動したり（chessのような感じ）、敵と戦ったりできる要素（gloomhavenなど）

## リファクタリング

### piece, test_piece関連
- [ ] いまはoutputとinputを同じへクスに表示しているが、これを別々のへクスに表示したい。

#### 将来検討
- [ ] プレビュー矢印と OutputPort の位置計算ロジックを一本化する（output_port.gd の PORT_OFFSET とマジックナンバーの重複、port.hex vs port["hex"] の不統一を解消）
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
