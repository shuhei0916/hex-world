# todo

- [ ] world mapにおいて、カーソルを合わせたchunkをハイライトするように変更する
- [ ] クリックされてローカルマップに即移行するのではなく、クリックでworld mapの中央にクリックされたchunkを据える用カメラを移動し、その状態でspaceでそのチャンクのローカルマップに移動するよう変更するか、検討する。

## チャンク間転送（feature/chunk-transporter）

**方針**: Sender/Receiver は別ピース。搬送は既存の acceptor/ejector 参照ベース機構をそのまま再利用し、
World は「配線」（点対称位置の相手解決 → set_connected_pieces）のみを担う。
辺ヘックス（座標1つだけが±R）にのみ設置可。角ヘックス（座標2つが±R）はどの辺にも属さない。
受信位置は Sender の点対称位置（h → -h）。当面アンロック条件なし。

### 辺方向判定
- [x] 辺ヘックスは get_edge_direction() が属する辺方向 0〜5 を返す
- [x] 角ヘックスは -1 を返す
- [x] 内側ヘックスは -1 を返す

### Sender / Receiver ピース
**方式**: どちらも ConveyorLogic を持つピース（＝配線元が違うコンベア）。搬送ロジックの新規実装なし。
Sender は出力ポートを持たない（port_direction=-1）ため NeighborManager はチャンク内配線しない。
Receiver の下流配線は既存 NeighborManager がそのまま担う。

- [x] PieceData.Type に SENDER / RECEIVER を追加（アンロック条件なし）
- [x] sender.tscn: アイテムを受け入れて保持する
- [x] sender: set_connected_pieces で接続した相手（別チャンクのピース）へ tick で渡せる
- [x] sender: 接続先不在ならアイテムを保持し続ける
- [x] sender: チャンク内の隣接ピースへは自動配線されない（NeighborManager が SENDER を除外）
- [x] receiver.tscn: アイテムを受け入れ、チャンク内の下流へ搬出する（既存配線で動く）
- [x] sender/receiver は辺ヘックス以外には設置できない（Chunk.can_place に piece_type 引数を追加）
- [x] PiecePlacer が can_place に piece_type を渡す（UI経由の設置でも制約が効く）

### World 配線
- [x] Sender 設置時、隣接チャンクの点対称位置に Receiver があれば接続される
- [x] Receiver 設置時、隣接チャンクの点対称位置に Sender があれば接続される（後置きでも配線される）
- [x] 隣接チャンク未生成・Receiver 不在なら接続されない（Sender は詰まる）
- [x] Sender/Receiver の撤去で配線が解除される
- [x] 非アクティブ（非表示）チャンクの Receiver でも受信できる（結合テスト）

### UI・結線
- [x] HUD ツールバーに Sender / Receiver スロットを追加（スロット8「送」・9「受」）
- [x] （目視）配置・搬送の画面確認（2026-07-15 スクリーンショットでチャンク間搬送を確認）
- [x] SE 方向（南東チャンク）への配線もテストで確認

### 受信候補ハイライト（UX改善）
背景: 辺⇔隣接チャンク方向は30°ずれるため、Receiver をどこに置けばよいか直感で分からない。
Sender の対岸（点対称位置）をハイライトし、置き場所を一目で分かるようにする。

- [x] World.get_receiver_hint_hexes(chunk_hex): 隣接チャンクの Sender の点対称位置一覧を返す
- [x] すでに Receiver が置かれている位置は候補から除外される
- [x] Chunk.show_receiver_hints(hexes): 指定タイルがハイライトされる
- [x] ハイライトは再表示のたびに前回分がクリアされる
- [x] World: アクティブチャンク切替時・配線更新時にアクティブチャンクのヒントが更新される
- [x] （目視）ハイライトの見た目確認（Receiver橙の暗色に調整、2026-07-18）
- [ ] Sender/Receiver の接続状態可視化（矢印・色）※ハイライト実装後に着手

### 接続状態可視化（3段階で実装）
1. 接続成立時の色変化: Sender/Receiverが接続中は緑系、未接続はデフォルトの色になる
2. 矢印表示: Senderの辺の外側に、接続先チャンクへ向かう矢印アイコンを表示する
3. ワールドマップでの接続辺表示: Sender/Receiverが実際に繋がっているチャンク間の辺を線・矢印で表示する

#### 1. 接続時の色変化
- [x] Piece.has_connected_piece()は接続先ピースがあるときtrueを返す（is_connectedはObject既存メソッドと衝突するため改名）
- [x] Sender/Receiverは接続時にmodulateが変わる
- [x] 接続解除でmodulateが元に戻る
- [ ] （目視）色変化の見た目確認

#### 2. 矢印表示
- [x] Senderが接続中のとき、辺の外側（接続先チャンクへ向かう方向）に矢印が表示される
- [x] 接続解除で矢印が消える
- [x] 未接続のSenderには矢印が表示されない
- [ ] （目視）矢印の見た目確認

### 辺方向とワールド隣接方向の30度ズレ修正
背景: チャンク内部は pointy-top レイアウト、world map は flat-top レイアウトで描画されており、
同じ方向インデックス（0=E〜5=SE）でもピクセル角度が60度（インデックス1つ分）ズレる。
実測: chunk(0,0)のhex(3,2)はget_edge_direction()でSE(5)と判定されるが、
world map上で実際に隣接するのはchunk(1,0)（= (5+1)%6 = E(0)方向）であり、(0,1)ではない。
修正方針: World._find_receiver()・World.get_receiver_hint_hexes() 内の
Hex.neighbor(chunk_hex, edge_dir) を Hex.neighbor(chunk_hex, (edge_dir + 1) % 6) に変更する。
Sender自身のローカル排出方向（set_connected_pieces の edge_dir 引数）は補正不要（pointy-topのローカル描画のまま正しいため）。

- [x] chunk(0,0)のhex(3,2)にSenderを置くと、chunk(1,0)のhex(-3,-2)に配線される（現状は誤ってchunk(0,1)に配線される）
- [x] 既存のチャンク間配線テスト群を、補正後の正しい隣接チャンク座標に合わせて修正する
- [x] 受信候補ハイライト（get_receiver_hint_hexes）も補正後の正しい隣接チャンクを対象にする

### 辺内の対応位置のズレ修正（単純な原点対称では逆側の端になる）
背景: 隣接チャンクは回転せず同じローカル座標系で描かれているため、単純な点対称(h→-h)では
辺（＝どのチャンクへ向かうか）は合っていても、辺内のどの位置か（＝どちら寄りの端か）が
逆側になってしまう。
実測: chunk(0,0)のhex(4,1,-5)は、単純な点対称だとchunk(1,0)の(-4,-1,5)になるが、
本来対応する位置は(-1,-4,5)（q,rを入れ替えた位置）。
修正方針: World._mirror_hex(hex, edge_dir) を新設。原点対称のあと、
edge_dir % 3 に応じて辺を定義する座標以外の2軸を入れ替える
（0: E/W→r,s入替 / 1: NE/SW→q,s入替 / 2: NW/SE→q,r入替）。

- [x] chunk(0,0)のhex(4,1,-5)にSenderを置くと、単純な点対称(-4,-1,5)ではなくchunk(1,0)の(-1,-4,5)に配線される

## ワールドマップUI整備（fix/world-map-ui）

**方針**: ワールドマップはチャンク選択専用の画面。ローカル編集用UI（HUD・ピースプレビュー）は非表示にする。
F2 デバッグオーバーレイはワールドマップでも効くようにし、チャンク座標を表示する。

- [x] ワールドマップモードで HUD が非表示になる
- [x] ローカルモードに戻ると HUD が再表示される
- [x] ワールドマップモードで PiecePlacer（手持ちプレビュー）が非表示になる
- [x] ローカルモードに戻ると PiecePlacer が再表示される
- [x] DebugOverlay.refresh_world_map で各チャンクの座標ラベルが生成される
- [x] F2 表示中にワールドマップへ切り替えるとチャンク座標ラベルに切り替わる
- [x] F2 表示中にローカルへ戻るとヘックス座標ラベルに戻る
- [x] ワールドマップ表示中に F2 を押してもチャンク座標ラベルになる（表示判断を _refresh_debug_overlay に一元化）
- [x] （目視）ワールドマップ画面の確認（2026-07-18）
- [ ] ワールドマップの表示位置が画面下寄りで一部見切れる（既存問題、位置調整は別途）

### 現在チャンク座標の表示
- [x] HUD.set_chunk_coordinate(hex) で左上ラベルにチャンク座標が表示される
- [x] チャンク切替でラベルが現在チャンクの座標に更新される
- [x] （目視）左上表示の確認（2026-07-18）

## クリエイティブモード（feature/creative-mode）

**方針**: `HubGoals` に `creative_mode: bool` を追加し、`is_reward_unlocked()` が creative_mode 時は常に true を返す。
F3 キーでトグル（F2 はデバッグオーバーレイで使用済み）。永続化なし・起動ごとにリセット。

- [x] `creative_mode = true` のとき、未取得の報酬でも `is_reward_unlocked()` が true を返す
- [x] `creative_mode = false` に戻すと `gained_rewards` に基づく判定に戻る
- [x] `toggle_creative_mode()` で `creative_mode` が反転する
- [x] `toggle_creative_mode()` で `unlocks_changed` シグナルが発火する
- [x] HUD が `unlocks_changed` 受信で全スロットボタンを有効化する
- [x] F3 キー押下で `HubGoals.toggle_creative_mode()` が呼ばれる（main 経由）
- [ ] 隣接するchunkにアイテムを送信する用のピースを追加する。

## Tierごとの生産速度差別化（feature/tier-speed）
- [x] `Crafter` に `@export var craft_time_multiplier: float = 1.0` を追加する
- [x] `_effective_craft_time()` が `craft_time_multiplier` を乗算する
- [x] `craft_time_multiplier > 1.0` のとき加工時間が長くなる（低速化）
- [x] 各 t1 シーンの Crafter ノードに `craft_time_multiplier = 2.0` を設定（暫定値・要バランス調整）

---

## 製造チェーン・ゲームループ
- [ ] 入力方向を限定していない現在の設計が適切かを検討する（出力と同じように、入力も固定方向からのみとするべき？）

---

## ピースtier対応（feature/piece-variants）

**方針**: 別シーン方式。`smelter_t1.tscn` / `smelter_t2.tscn` のように tier ごとにシーンを作成。
HUD スロットが `variants: Array[PackedScene]` を持ち、T キーで循環する。`PiecePlacer` は変更不要。

### HUD・入力
- [x] `_scenes` を `Array[Array[PackedScene]]` に変更し、スロットごとに複数バリアントを持てる
- [x] `get_scene_for_slot(index)` は現在のバリアントインデックスに対応するシーンを返す
- [x] バリアントが1つのスロットでは `cycle_variant()` を呼んでも変化しない
- [x] `cycle_variant()` でアクティブスロットのバリアントが循環する（最後→最初に戻る）
- [x] `cycle_variant()` 後に `slot_selected` が新しいシーンで再発火する
- [x] スロット切り替え時にバリアントインデックスが0にリセットされる
- [x] T キー入力で `cycle_variant()` が呼ばれる（main.gd）

### シーン作成（Smelter を最初のサンプルとして実装）
- [x] `smelter.tscn` を `smelter_t2.tscn` にリネームし、既存の形状・速度をそのまま引き継ぐ
- [x] `smelter_t1.tscn` を新規作成（1ヘックス、craft_time 遅め）
- [x] HUD の Smelter スロットに `variants: [smelter_t1, smelter_t2]` を設定

### 残りのピースへの展開
- [x] Miner t1 / t2 シーン作成
- [x] Assembler t1 / t2 シーン作成
- [x] Cutter t1 / t2 シーン作成
- [x] Mixer t1 / t2 シーン作成

---

## バリアント選択UI（feature/variant-selector）

**方針**: PieceInfoPanel 下部にバリアント選択行を追加。T キーで循環、クリックでも直接選択。バリアント1つなら非表示。

- [x] バリアントが2つ以上のスロット選択時、情報パネルにバリアントボタン行が表示される
- [x] バリアントが1つのスロット選択時、バリアントボタン行が非表示になる
- [x] 選択解除時、バリアントボタン行が非表示になる
- [x] バリアントボタン数がバリアント数と一致する
- [x] 現在選択中のバリアントボタンが強調（pressed）状態になる
- [x] バリアントボタンをクリックするとバリアントが切り替わり slot_selected が発火する
- [x] T キーで循環するとバリアントボタンの強調が更新される

---

## UI・ビジュアル
- [ ] **Toolbar の Hex 化**: 現在の四角形ボタンを hex 形状に移行
- [ ] **ピースパレットのカテゴリ化**: ピースをグループ化し、カテゴリごとに表示
- [ ] **マウスオーバー情報**: 設置済みピースにホバーで詳細ラベルを表示

---

## コンベア
- [ ] **つなぎ目の改善**（fix/belt-seam）: 調査済み（2026-07-14）。原因は各ピースがヘックス辺中点で描画を打ち切ることによるサブピクセルの隙間（背景が透ける）。
  対策: 接続がある側のパス端点を1〜2px外側へ延長して隣とオーバーラップさせる（`ConveyorVisuals.refresh_belt()` の修正）
- [ ] **搬出時の余剰deltaの持ち越し**: `TransferBuffer.advance()` で TRANSFER_TIME 超過分を捨てているため境界ごとに最大1フレーム停滞する。超過分を搬出先の初期 progress に渡す（微差・任意）
- [ ] **設置UXの改善**: shapez2 のようにパス収集＋自動向き決定方式を検討
- [ ] ~~**BeltPath 化**~~: 検討の結果不採用（2026-07-14）。shapez.io の belt_path.js は約1700行でパス分割/結合の複雑さが大きく、本作の規模ではパフォーマンス動機がない。切れ目は描画修正で解決可能。大規模化する場合に再検討
- [ ] コンベアの分岐において、アイテムが満たされたあと、片方の分岐のベルトコンベアのみを延長した際、延長していないコンベアの根元から、延長したコンベアへアイテムが瞬間移動したように見えるバグを修正する
- [ ] コンベアで180度逆方向の分岐を作った際のバグを修正する。

## 自然な分岐（feature/conveyor-natural-branching）
- [x] ConveyorVisuals は output_directions が複数のとき、各方向へ1本ずつベジェを描く
- [x] NeighborManager は接続更新後に ConveyorVisuals へ出力方向リストを渡す
- [x] コンベアBの入力方向がコンベアAを向くとき、AはBを出力先に自動追加する（自然な分岐）
- [x] BalancerLogic を廃止し ConveyorLogic に統合する
- [ ] balancer.tscn を廃止し conveyor.tscn のみで分岐を実現する（balancer は UI からも削除）

---

## 事前リファクタリング（refactor/pre-chunk-ports）

- [x] `Main._mode` を削除し、`is_local_mode()` が `world.visible` を返す（既存テストで担保）
- [x] `Chunk` の資源関連ロジック（`_resources` / `mark_resource_hex` / `get_hex_resource` / `generate_ore_deposits` / `_apply_mining_constraint`）を `ChunkResources` に分離する
	- [x] `ChunkResources.mark_resource_hex` / `get_resource` が資源を記録・取得できる
	- [x] `ChunkResources.apply_mining_constraint` が鉱床0のMINERのレシピをnullにする
	- [x] `ChunkResources.apply_mining_constraint` が鉱床数をoutput_multiplierに設定する
	- [x] `Chunk` の既存公開API（mark_resource_hex 等）は委譲として維持され、既存テストが通る

---

## リファクタリング（コードレビュー起票 2026-06-26）

### 責務分離
- [ ] **`Chunk` の責務分割**: `_apply_mining_constraint()` を `ResourceManager` 等の別クラスへ移動。現在 257 行・8 責務が混在
- [ ] **`Piece` のビジュアル分離**: `_output_arrow` 生成・HexTile 生成を `PieceVisuals` に切り出す
- [ ] **`Main` の入力処理分離**: 入力ハンドラ（マウス・キー）を `InputHandler` に切り出す

### グローバル依存の軽減
- [ ] **`Crafter` の `HubGoals` 依存緩和**: グローバルシングルトン参照を減らし、テスト容易性を高める

### 不整合・冗長
- [ ] **`Main._mode` の削除**: `world.visible` から推論できるため冗長。`is_local_mode()` を `return world.visible` に変更
- [ ] **`tick()` vs `_process()` の整理**: ロジック系は `tick()`（親が呼ぶ）、ビジュアル系は `_process()`（Godot 自走）の方針をコメントで明文化し、混在箇所を修正

### テスト充実
- [ ] **`NeighborManager` の接続更新フロー**: 結合テストが薄い。エンドツーエンドで接続更新が正しく伝播するかをテスト化
- [ ] **エッジケーステスト追加**: グリッド境界へのピース配置試行、リソース枯渇時の鉱山動作

---

- [ ] z_indexではなく、ツリー順で順番を制御したほうがクリーンかも。
- [ ] `_update_conveyor_input_direction` は単一入力方向しか確定できない。将来の合流実装に備え、複数入力元を扱える設計を検討する。
- [ ] `_is_physically_connected(source, source_hex, direction)` の `source_hex` 引数は多ヘックスピース向けの名残で、コンベア（1ヘックス）では常にベース座標と同値。整理して引数の意図を明確にする。
- [ ] `_is_physically_connected`（自然分岐）と `_update_conveyor_input_direction`（入力方向検出）の接続判定ロジックが非対称。前者はポート方向の比較、後者はポートの到達先ヘックスの座標計算で判断しており、多ヘックスコンベアを追加した際に後者が誤動作する可能性がある。

---

## デバッグオーバーレイ（feature/debug-overlay）
- [x] toggle() を呼ぶたびに visible が反転する
- [x] refresh(chunk) 後、chunk の全ヘックス分のラベルが生成される
- [x] ピース配置済みヘックスではピース名がラベルに含まれる

---

## チャンク間連携（将来）
- [ ] チャンク間アイテム移動: Chunk の辺にポート（入出力）を定義。ワールドマップ上でフロー表示
---


## 設計（将来）
- [ ] **ItemAcceptor 再導入**: 「特定方向のみ受け入れる」「特定アイテムのみ」のフィルタ設計への移行
  現状は全方向・全アイテムを受け入れる。shapez の ItemAcceptorComponent 相当

---

## 長期構想
- [ ] **各ピースのスプライト化**: miner/smelter 等に hex 用画像スプライトを用意
- [ ] **戦闘要素**: グリッド上をキャラクターが移動（chess 風）し敵と戦う（gloomhaven 風）
- [ ] **chunk の LOD 圧縮**: 定常状態の chunk を「入力レート→出力レート＋遅延」の集約モデルに圧縮
