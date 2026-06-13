# todo

## 入出力アイテム表示の shapez 化（feature/boundary-item-display）

機械のバッファレス化に伴い、入出力の「数量バッジ」表示を見直す。
入力バッジは廃止、出力はポート端に「はみ出し」表示（shapez の抽出器ルック）。
Chest/Delivery はバッファなのでバッジ維持。

### Inventory の表示フラグ
- [ ] Inventory に show_icon フラグを追加（false で何も表示しない）
- [ ] Inventory に show_count フラグを追加（false で数量ラベルを隠す）

### 入力バッジ廃止
- [ ] 加工機（smelter等）の入力にアイテムを入れてもアイコンが表示されない
- [ ] piece.gd から input_hex と入力位置決めを削除する
- [ ] Chest の入力バッジは引き続き表示される

### 出力はみ出し表示
- [ ] 機械の Output ノードが出力ポート端（中心＋0.5×方向）に配置される
- [ ] Output 位置はピース回転に追従する
- [ ] 機械の出力は数量ラベルを表示しない（アイコンのみ）

## 直近タスク
- [ ] WASDでカメラを動かせるようにする。
- [ ] chunk自体がinput, output等を持ち、他のchunkと接続できるようにする。

### UI: 選択中ピースの情報表示
- [ ] ピース選択時、画面右上にピース名と簡単な説明文を UI として表示する

### コンベア上のアイテム間隔の調整
- [ ] アイテム同士の間隔が疎すぎる印象があるため調整する
  - 現仕様は 1ヘックス=最大1アイテム。参考: shapez は itemSpacingOnBelts = 0.63 タイル
  - 1コンベアに複数アイテムを載せるなら「コンベアアイテム搬送アニメーション（TransportLine方式）」
	（将来検討の項）と合わせて設計する

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

### chunk.gd の責務分離（Tier2・最有力）
- [ ] 世界生成ロジック（generate_ore_deposits / place_delivery_zone / mark_resource_hex）を
  WorldGenerator 等へ切り出し、Chunk をグリッド＋ピース管理のファサードに絞る
  - shapez が MapGenerator を分けているのと同じ方向。chunk.gd は現状 ~255 行で責務過多

### テストの棚卸し（動作するドキュメント化）
- [ ] 振る舞いテストに包含された足場テスト（型チェック・存在確認のみ）を削除する
  - 基準: 「このテストが落ちたとき、どの仕様違反を教えてくれるか」に答えられないものは削除候補
  - 注意: .tscn の配線はコンパイル時チェックが効かないため、存在確認に見えても配線スモークとして価値が残る場合あり。代替テストの有無を確認してから消す
  - 候補: test_piece_data の `PieceDataをインスタンス化できる`・否定存在テスト（低価値）。enum値テストは .tscn が int に依存するため残す

### piece, test_piece関連
- [ ] いまはoutputとinputを同じへクスに表示しているが、これを別々のへクスに表示したい。
  - [x] smelter に input_hex 設定済み・回転追従実装済み
  - [ ] assembler, cutter, mixer, painter に input_hex を設定する
  - [ ] output アイコンも回転追従させるか検討（port_hex を利用）
  - [ ] 1ヘックスピース（conveyor, chest）は現状のまま（変更不要か確認）

#### 将来検討
- [ ] 命名を shapez に揃えるリネーム検討（Output→ItemEjector / PieceInput→ItemAcceptor、ヘルパー改名。piece→building はスコープ外）
  - 背景: 六角形版 shapez を軸としており、構造・命名を shapez 語彙へ寄せたい（合成リファクタ済みの今が低コスト）
  - 影響範囲: クラス名＋ノード名＋get_node文字列＋テスト。Crafter は据え置き推奨
- [ ] `_key` / `hex_to_key` の薄いラッパー（PieceRegistry/HexGrid/GridRenderer ×3）を Hex.to_key 直呼びに統一（軽微）
- [ ] InputHandler クラスを抽出し main.gd の入力処理を委譲
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] output.gd の _push_items() をキューベースに最適化
- [ ] piece.gd / input.gd の `add_item` / `consume_item` インターフェースを整理
- [ ] input.gd / output.gd の共通 InventoryContainer 基底クラスを抽出する
- [ ] OutputPort の複数ポート対応テストを追加する
- [ ] コンベア設置UXの改善（Factorio: 直線制約、shapez2: パス収集＋自動向き、を参考に検討）
- [ ] Splitter/Mergerを専用ピースではなく、既存コンベアラインからの分岐・合流操作で実現する（shapez2ではsplitter/merger自体が廃止されている）。UXとして親切だが大掛かりな変更になるため、専用ピース方式が立ち行かなくなった場合に再検討する
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
