# todo
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
- [ ] `smelter.tscn` を `smelter_t2.tscn` にリネームし、既存の形状・速度をそのまま引き継ぐ
- [ ] `smelter_t1.tscn` を新規作成（1ヘックス、craft_time 遅め）
- [ ] HUD の Smelter スロットに `variants: [smelter_t1, smelter_t2]` を設定

### 残りのピースへの展開
- [ ] Miner t1 / t2 シーン作成
- [ ] Assembler t1 / t2 シーン作成
- [ ] Cutter t1 / t2 シーン作成
- [ ] Mixer t1 / t2 シーン作成

---

## UI・ビジュアル
- [ ] **Toolbar の Hex 化**: 現在の四角形ボタンを hex 形状に移行
- [ ] **ピースパレットのカテゴリ化**: ピースをグループ化し、カテゴリごとに表示
- [ ] **マウスオーバー情報**: 設置済みピースにホバーで詳細ラベルを表示

---

## コンベア
- [ ] **つなぎ目の改善**: draw_polyline の端点で隣接ベルトとの微細な隙間が発生する問題。
  対策候補: 端点円キャップ / ヘックス境界を越えてパスを延長
- [ ] **設置UXの改善**: shapez2 のようにパス収集＋自動向き決定方式を検討
- [ ] **BeltPath 化**: 1ヘックス=最大1アイテムの制約を緩和し、複数アイテムを載せる再設計
- [ ] コンベアの分岐において、アイテムが満たされたあと、片方の分岐のベルトコンベアのみを延長した際、延長していないコンベアの根元から、延長したコンベアへアイテムが瞬間移動したように見えるバグを修正する
- [ ] コンベアで180度逆方向の分岐を作った際のバグを修正する。

## 自然な分岐（feature/conveyor-natural-branching）
- [x] ConveyorVisuals は output_directions が複数のとき、各方向へ1本ずつベジェを描く
- [x] NeighborManager は接続更新後に ConveyorVisuals へ出力方向リストを渡す
- [x] コンベアBの入力方向がコンベアAを向くとき、AはBを出力先に自動追加する（自然な分岐）
- [x] BalancerLogic を廃止し ConveyorLogic に統合する
- [ ] balancer.tscn を廃止し conveyor.tscn のみで分岐を実現する（balancer は UI からも削除）

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
