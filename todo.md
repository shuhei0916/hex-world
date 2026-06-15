# todo

## 直近タスク
- [ ] コンベアの見た目を調整する：
- [ ] WASDでカメラを動かせるようにする。
- [ ] chunk自体がinput, output等を持ち、他のchunkと接続できるようにする。

### UI: 選択中ピースの情報表示
- [x] ピース選択時、画面右上にピース名と簡単な説明文を UI として表示する

#### テストリスト
- [x] PieceInfoPanel.show_info() で NameLabel にピース名が入る
- [x] PieceInfoPanel.show_info() で DescriptionLabel に説明文が入る
- [x] PieceInfoPanel.show_info() でパネルが visible = true になる
- [x] PieceInfoPanel.clear() でパネルが visible = false になる
- [x] HUD でスロット選択時に該当ピースの名前がパネルに表示される
- [x] HUD で選択解除（null）時にパネルが非表示になる
- [x] piece.gd に piece_name / piece_description の export がある（各 .tscn に設定）

### UI: 生産速度を SpeedLabel から情報パネルへ移設（shapez準拠・基準速度/毎分）
- [x] ピース上の SpeedLabel を廃止し、右上の情報パネルに基準生産速度を表示する

#### テストリスト
- [x] Recipe.items_per_minute() が 60/craft_time を返す
- [x] PieceInfoPanel.show_info() で速度テキストが RateLabel に入る
- [x] PieceInfoPanel.show_info() で速度が空文字なら RateLabel が非表示
- [x] HUD でスロット選択（機械）時に情報パネルに生産速度が表示される
- [x] HUD でスロット選択（レシピ無ピース）時に RateLabel が非表示
- [x] 各 .tscn から SpeedLabel ノードと speed_label.gd を削除（旧 visuals テスト削除）

### 修正: minerの出力アイテムが生産前からはみ出ている
- [x] 出力アイコンは実際に生産されてから表示する（加工中プレビュー expected_item を廃止）

#### テストリスト
- [x] 加工開始直後（完了前）は出力Iconが表示されない
- [x] 加工完了後は出力Iconが表示される
- [x] expected_item 機構（inventory/output/crafter）を削除（旧テスト削除）

### コンベアのアニメーション描画（forward 2セグメント・Phase 1）
- [x] Line2D を「パス幾何＋ベルトスプライト」に置換し、forward フレームでベルトを動かす

#### テストリスト
- [x] フレーム index が経過時間で進み 14 で循環する
- [x] forward フレーム配列が14枚ある
- [x] _path が3点（in_edge/center/out_edge）を持つ（旧 _line テスト移行）
- [x] 出力側エッジ点が出力方向にある（旧 _line テスト移行）
- [x] rotate_cw 後に出力エッジ点が更新される（旧 _line テスト移行）
- [x] アイテムアイコンがベルト(z=6)より手前(z=7)に描画される（旧 _line.z_index テスト移行）

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

## 将来構想（長期）

### chunk の階層化と LOD 圧縮
- [ ] chunk に6方向の input/output ポート（エッジ契約）を持たせ、隣接 chunk と接続できるようにする
  - chunk = 製造ラインを内包した「合成可能な部品」。chunk of chunks の多重構造で大工場を構築する構想
  - **設計の核はエッジ I/O 契約**（各辺＝アイテム種別＋レート＋背圧 backpressure のストリーム）。これを先にきれいに作る
- [ ] 定常状態の chunk を「入力レート→出力レート＋遅延」の集約モデルに圧縮する（LOD / ブラックボックス化）
  - 圧縮トリガーは「定常 かつ 非観測（画面外/非編集）」。過渡状態（起動・充填・詰まり）はフル sim にフォールバック
  - 主効果は CPU とアイテム実体数の削減（毎フレーム tick とアイテムノード生成の停止）。RAM 削減は副次的
  - 注意: 背圧の chunk 境界越え伝播、パズル性（編集中 chunk は常にフル sim）との両立
  - 方針: いきなり実装せず、まず単一 chunk のフル sim＋クリーンな I/O 契約を作る。圧縮はスケール問題に当たってから

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
