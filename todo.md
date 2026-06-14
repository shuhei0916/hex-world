# todo

## 直近タスク
- [ ] WASDでカメラを動かせるようにする。
- [ ] chunk自体がinput, output等を持ち、他のchunkと接続できるようにする。

### UI: 選択中ピースの情報表示
- [ ] ピース選択時、画面右上にピース名と簡単な説明文を UI として表示する

#### テストリスト
- [x] PieceInfoPanel.show_info() で NameLabel にピース名が入る
- [ ] PieceInfoPanel.show_info() で DescriptionLabel に説明文が入る
- [ ] PieceInfoPanel.show_info() でパネルが visible = true になる
- [ ] PieceInfoPanel.clear() でパネルが visible = false になる
- [ ] HUD でスロット選択時に該当ピースの名前がパネルに表示される
- [ ] HUD で選択解除（null）時にパネルが非表示になる
- [ ] piece.gd に piece_name / piece_description の export がある（各 .tscn に設定）

### コンベア上のアイテム間隔の調整
- [ ] アイテム同士の間隔が疎すぎる印象があるため調整する
  - 現仕様は 1ヘックス=最大1アイテム。参考: shapez は itemSpacingOnBelts = 0.63 タイル
  - 1コンベアに複数アイテムを載せるなら「コンベアアイテム搬送アニメーション（TransportLine方式）」
	（将来検討の項）と合わせて設計する

## リファクタリング

### chunk.gd の責務分離
- [ ] 世界生成ロジック（generate_ore_deposits / place_delivery_zone / mark_resource_hex）を
  WorldGenerator 等へ切り出し、Chunk をグリッド＋ピース管理のファサードに絞る
  - shapez が MapGenerator を分けているのと同じ方向。chunk.gd は現状 ~255 行で責務過多

## 将来検討
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
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
- [ ] item_dbをtresファイルを使ったリソースファイルへ移行する

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッドの上をキャラクターが移動したり（chessのような感じ）、敵と戦ったりできる要素（gloomhavenなど）
