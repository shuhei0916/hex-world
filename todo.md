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
- [x] コンベアの基礎タイル(オレンジ)を廃止しベルト画像に一本化
- [x] コンベアの出力方向矢印を廃止（ベルト画像が方向を示すため）

### コンベアの曲がりをマイター接合で滑らかにする（Phase 2・リトライ予定）
- [ ] 曲がり角でベルトの継ぎ目をマイター（角の二等分線カット）で綺麗に繋ぐ
  - 前回失敗: 鋭角(60°)でマイタースパイクが発生し自己交差ポリゴンで描画消失した
  - 対策案: マイター長のクランプ（miter limit、超過時はベベルに切替）／または hex 専用の
	left/right カーブ素材(60°/120°×14コマ)を生成AIで用意して shapez 同様にタイルごとに選ぶ
  - 根本: forward は直線矢印テクスチャなので幾何接合だけでは曲がりの「折れ」は消えない

### コンベア上のアイテム間隔の調整
- [ ] アイテム同士の間隔が疎すぎる印象があるため調整する
  - 現仕様は 1ヘックス=最大1アイテム。参考: shapez は itemSpacingOnBelts = 0.63 タイル
  - 1コンベアに複数アイテムを載せるなら「コンベアアイテム搬送アニメーション（TransportLine方式）」
	（将来検討の項）と合わせて設計する

## リファクタリング

### アイテム描画を shapez の System 分担に合わせて再配置する
- [x] splitter: ConveyorVisuals 流用をやめ ItemEjectorVisual に分離、出力ポートへ飛び出し表示、
  ItemEjector をスロット/方向対応にして「表示＝実排出」を一致（片側接続・詰まりでも食い違わない）
- [ ] miner/機械の「はみ出し出力アイテム(現 Inventory アイコン)」も ItemEjector 駆動描画へ統一
  （shapez: ItemEjectorSystem が全建物の出力を一括描画）。確立済みの ItemEjector/ItemEjectorVisual を流用
- [ ] 取り込まれるアイテムの描画を acceptor 駆動に（shapez: ItemAcceptorSystem）※現状機械入力は非表示
  - ベルト上を流れるアイテム → ベルト固有描画（shapez: BeltPath）。ejector/acceptor とは別系統（現状維持）
  - 確立済み: ItemEjector(部品=ItemEjectorComponent相当) / ItemEjectorVisual(描画=System相当)
  - HeldItemVisual のような共通部品は shapez に無いため作らない。Crafter(≒ItemProcessor)は描画を持たない

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
- [x] Output→ItemEjector / PieceInput→ItemAcceptor / 旧RefCounted ItemEjector→EjectorRouter に改名
  （挙動維持。Node は従来どおり Inventory を子に持つ。Piece の member も ejector/acceptor へ）
- [x] ItemEjector のスロット忠実化: 出力 Inventory を廃止しスロットが item を直接保持。
  miner/機械の出力アイテム描画も ItemEjectorVisual に統一（挙動維持）
- [x] ItemEjector スロットに progress を持たせ、出力アイテムを出力hex中心→ポート端へスライド
  （shapez ルック）。EJECT_TIME=TRANSFER_TIME で排出上限＝転送レート（スループット悪化なし）。
  tick を Piece に集約
- [~] SplitterLogic を ItemEjector に統合 → **見送り**。ItemEjector に can_accept_item を持たせると
  二役化し、get_acceptor 判定や miner（出力のみ）の意味論に波及して逆に濁るため。SplitterLogic は
  balancer ロジックとして独立維持が妥当（忠実分割 ItemAcceptor+mover+ItemEjector は規模に見合わず保留）
- [ ] `_key` / `hex_to_key` の薄いラッパー（PieceRegistry/HexGrid/GridRenderer ×3）を Hex.to_key 直呼びに統一（軽微）
- [ ] InputHandler クラスを抽出し main.gd の入力処理を委譲
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] _push_items() をキューベースに最適化（Output 分解後は ItemEjector 側のロジックになる）
- [ ] piece.gd / input.gd の `add_item` / `consume_item` インターフェースを整理（ItemAcceptor 分解と一緒に）
- [ ] ~~input.gd / output.gd の共通 InventoryContainer 基底クラスを抽出する~~
  → 廃案。Output/PieceInput は「共通基底で束ねる」のではなく「ItemEjector/ItemAcceptor＋Inventory へ分解」する方針に変更
- [ ] OutputPort の複数ポート対応テストを追加する
- [ ] コンベア設置UXの改善（Factorio: 直線制約、shapez2: パス収集＋自動向き、を参考に検討）
- [ ] Splitter/Mergerを専用ピースではなく、既存コンベアラインからの分岐・合流操作で実現する（shapez2ではsplitter/merger自体が廃止されている）。UXとして親切だが大掛かりな変更になるため、専用ピース方式が立ち行かなくなった場合に再検討する
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
- [ ] item_dbをtresファイルを使ったリソースファイルへ移行する
- [ ] 各ピース(miner/smelter等)に hex 用の画像スプライトを用意し、コンベア同様に
  設置描画＋プレビューをスプライト化する（現状はフラットな色付き六角形のため）
  - 要アセット準備（生成AI 等）。仕組み(設置スプライト＋半透明プレビュー)はコンベアで確立済み

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッドの上をキャラクターが移動したり（chessのような感じ）、敵と戦ったりできる要素（gloomhavenなど）
