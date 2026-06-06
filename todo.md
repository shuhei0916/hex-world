# todo

## ゲームプレイ・コンテンツ
### 自動化要素の強化
- [ ] 強化鉄板のレシピを追加する（複数入力対応後）
- [ ] mixerでscrewを生産するなど、直感的でないレシピを調整する。


### 納品所（Delivery Zone）実装
- [ ] 地面のタイルを多様化させる（kenney assetsを使うのもありかも）

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッドの上をキャラクターが移動したり（chessのような感じ）、敵と戦ったりできる要素（gloomhavenなど）

## リファクタリング

### piece, test_piece関連
- [ ] いまはoutputとinputを同じへクスに表示しているが、これを別々のへクスに表示したい。
  - [x] smelter に input_hex 設定済み・回転追従実装済み
  - [ ] assembler, cutter, mixer, painter に input_hex を設定する
  - [ ] output アイコンも回転追従させるか検討（port_hex を利用）
  - [ ] 1ヘックスピース（conveyor, chest）は現状のまま（変更不要か確認）

#### 将来検討
- [ ] output_port.tscn を作成し、設置済みピースのOutputPortとプレビュー矢印を共用化する（PORT_OFFSET・色・スケール・位置計算の重複解消、port.hex vs port["hex"] の統一）
- [ ] InputHandler クラスを抽出し main.gd の入力処理を委譲
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] output.gd の _push_items() をキューベースに最適化
- [ ] piece.gd / input.gd の `add_item` / `consume_item` インターフェースを整理
- [ ] input.gd / output.gd の共通 InventoryContainer 基底クラスを抽出する
- [ ] OutputPort の複数ポート対応テストを追加する
- [ ] コンベア設置UXの改善（Factorio: 直線制約、shapez2: パス収集＋自動向き、を参考に検討）
- [ ] コンベアアイテム搬送アニメーション（TransportLine方式）
  - 設計方針: シミュレーション+描画分離。アイテムを progress 付き配列で管理し _physics_process で前進、描画は Sprite2D プール or MultiMeshInstance2D
  - ベルト表面は UV スクロールシェーダー
  - 難易度: 高（描画位置の座標系、詰まり・分岐ロジック、既存アーキテクチャとの統合が複雑）

### それ以外
- [ ] item_dbをtresファイルを使ったリソースファイルへ移行する

## 検討中のタスク・メモなど（AIはこれを編集・削除しないでください）
- [ ] マウスホイールでツールバーに割り当てられたピースの選択ができるようにする
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
