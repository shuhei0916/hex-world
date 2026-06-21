# todo

## 製造チェーン・ゲームループ
- [ ] **CUTTER・MIXER・PAINTER のシーン作成**: 製造チェーン（iron_rod / screw）を完成させる
- [ ] **段階的アンロック**: Hub への納品でレベルアップし、新ピースが解放される仕組み
  ### HubGoals（オートロード）
  - [x] レベル1の目標は iron_ore × 10 で、報酬は "unlock_smelter"
  - [x] is_reward_unlocked() は未取得の報酬に false を返す
  - [x] is_reward_unlocked() は取得済みの報酬に true を返す
  - [x] advance_level() で gained_rewards に報酬が記録される
  - [x] advance_level() で level が1増える
  - [x] advance_level() で level_up シグナルが発火する
  - [x] advance_level() を最終レベル超えて呼んでもクラッシュしない（freeplay）
  ### Hub との連携
  - [ ] 目標達成時に add_received() が HubGoals.advance_level() を呼ぶ
  ### PieceData アンロック判定
  - [ ] MINER / CONVEYOR / BALANCER は常にアンロック済み
  - [ ] SMELTER は unlock_smelter 未取得のときロックされる
  - [ ] SMELTER は unlock_smelter 取得済みのときアンロックされる

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

---

## リファクタリング
- [ ] z_indexではなく、ツリー順で順番を制御したほうがクリーンかも。

---

## チャンク間連携（将来）
- [ ] **Phase 5: チャンク間アイテム移動**: Chunk の辺にポート（入出力）を定義。ワールドマップ上でフロー表示
---


## 設計（将来）
- [ ] **ItemAcceptor 再導入**: 「特定方向のみ受け入れる」「特定アイテムのみ」のフィルタ設計への移行
  現状は全方向・全アイテムを受け入れる。shapez の ItemAcceptorComponent 相当

---

## 長期構想
- [ ] **各ピースのスプライト化**: miner/smelter 等に hex 用画像スプライトを用意
- [ ] **戦闘要素**: グリッド上をキャラクターが移動（chess 風）し敵と戦う（gloomhaven 風）
- [ ] **chunk の LOD 圧縮**: 定常状態の chunk を「入力レート→出力レート＋遅延」の集約モデルに圧縮
