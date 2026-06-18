# todo

## 複数チャンク対応

### 残タスク
- [ ] **Phase 5（将来）: チャンク間アイテム移動**: Chunk の辺にポート（入出力）を定義。
  ワールドマップ上でフロー（矢印・アニメーション）を表示。

---

## リファクタリング

- [ ] **WorldGenerator 抽出**: World.create_chunk() に鉱床生成ロジックを移す形で整理する
- [ ] **6.（長期）piece_type の enum int 依存を脱却**: PieceData.Type に削除済み CHEST=7 の穴が残る。
  .tscn が piece_type を生 int で持つため番号をずらせない脆さ。将来 StringName/リソース参照へ

### ItemAcceptor を本来の意味で再導入する（方向/アイテムフィルタ）← 将来
- 経緯: 旧 ItemAcceptor は「満杯でなければ受ける＋汎用 Inventory に保持」だけの空の転送層だったため解体済み。
  現状の受け入れ口は get_acceptor() のダックタイピング（Crafter / ConveyorLogic / Delivery）で、**全方向・全アイテムを受け入れる**。
- [ ] 将来「特定の方向からのみ受け入れる」「特定のアイテムのみ受け入れる」設計に変更する際、
  shapez の ItemAcceptorComponent を本来の意味で導入する
  - shapez の ItemAcceptor が持つ4要素: 辺ごとのスロット(pos+direction) / 方向フィルタ / アイテムフィルタ / 流入アニメ
  - 現状は NeighborManager が隣接から物理的に入力方向を解決しているだけ。ルールを持たせる時が導入の好機

### piece.gd の描画分離（低優先）
- [ ] 基礎ヘックスタイル生成(_create_hex_tiles)と出力矢印(_refresh_output_arrow / make_output_arrow)を
  PieceBaseVisual 等へ切り出し、piece.gd をファサード/ロジックに絞る
  （ConveyorVisuals / ItemEjectorVisual と同じ「描画はビジュアル部品」方針の徹底）

### 命名・重複の整理（低優先）
- [ ] `_key` / `hex_to_key` の薄いラッパー(PieceRegistry/HexGrid/GridRenderer ×3)を Hex.to_key 直呼びに統一
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] OutputPort の複数ポート対応テストを追加する
- [ ] ポート回転ロジック(get_rotate_ports 等)を hex クラス等に共通化できないか検討

---

## コンベア（描画・搬送）

### アセット
- [ ] **60° 曲がりコンベア画像**（0-13 フレーム × 左右）の生成・実装
- [ ] **120° 曲がりコンベア画像**（0-13 フレーム × 左右）の生成・実装

### 曲がりをマイター接合で滑らかにする（アセット化の代替案）
- [ ] 曲がり角の継ぎ目をマイター(角の二等分線カット)で綺麗に繋ぐ
  - 前回失敗: 鋭角(60°)でマイタースパイク→自己交差ポリゴンで描画消失
  - 対策案: マイター長クランプ(超過時ベベル切替)

### コンベア上のアイテム間隔の調整（BeltPath 化）
- [ ] 1ヘックス=最大1アイテムを緩和。複数アイテムを載せるなら
  TransportLine / BeltPath 方式で再設計

### コンベア設置UXの改善
- [ ] Factorio(直線制約) / shapez2(パス収集＋自動向き) を参考に検討

---

## ピース・UI（将来）
- [ ] 各ピース(miner/smelter等)に hex 用画像スプライトを用意し、設置描画＋プレビューをスプライト化
- [ ] CUTTER・MIXER・PAINTER のシーン作成（製造チェーン完成）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
- [ ] item_db を tres リソースファイルへ移行する

---

## 将来構想（長期）

### chunk の LOD 圧縮
- [ ] 定常状態の chunk を「入力レート→出力レート＋遅延」の集約モデルに圧縮する（LOD / ブラックボックス化）

### ゲームの別路線の開拓（戦闘要素）
- [ ] グリッド上をキャラクターが移動(chess風)し、敵と戦う要素(gloomhaven風)
