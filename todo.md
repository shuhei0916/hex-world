# todo

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
