# todo

## 複数チャンク対応（ワールドマップ実装）

### 事前推奨リファクタリング
- [ ] **InputHandler 抽出（multi-chunk 前推奨）**: main.gd の `_unhandled_input` を InputHandler クラスへ委譲。
  Phase 3（モード切り替え）で LocalInputHandler / WorldMapInputHandler を差し替えられる構造を作る。
  main.gd は現状 61 行でクリーンだが、モード切り替えロジックが入ると肥大化しやすい。

### 実装フェーズ
- [ ] **Phase 1: World クラス（データ層）**: `chunk_hex → Chunk` の辞書を持つ World を作成。
  main.gd の `$Chunk` を `$World.get_active_chunk()` に置き換え。
  → ここで WorldGenerator 抽出が自然に発生する（World.create_chunk() が鉱床生成を担うため）
- [ ] **Phase 2: WorldMapView（描画）**: 各 Chunk を1枚の ChunkTile（大きな hex）として描く Node2D。
  アイテム移動は将来。タイルの存在・選択状態・鉱床有無程度を簡略表示。
- [ ] **Phase 3: モード切り替え**: Space キーまたはスクロール閾値でローカルマップ ⇄ ワールドマップ切り替え。
  表示ツリーの切り替え + カメラ位置・ズームのリセット。
- [ ] **Phase 4: チャンク選択ナビゲーション**: ワールドマップ上の ChunkTile クリック → アクティブチャンク変更
  → ローカルマップへ遷移。Space または UI 「戻る」でワールドマップに戻る。
- [ ] **Phase 5（将来）: チャンク間アイテム移動**: Chunk の辺にポート（入出力）を定義。
  ワールドマップ上でフロー（矢印・アニメーション）を表示。

---

## リファクタリング

### 済み・判断済み
- [x] WASDでカメラを動かせるようにする。
- [x] 配送ロジックの三重化を解消（ConveyorLogic を EjectorRouter ベースに統一）
- [x] delivery → hub リネーム + balancer 命名統一
- [x] place_delivery_zone の死にコード除去（hub リネーム時に完了）
- [x] chunk サイズ: grid_radius=8（217タイル）に設定済み。菱形への変更は chunk of chunks 実装時に再検討。
- [ ] **WorldGenerator 抽出**: shapez の MapChunk も「自チャンクを自己生成」する同じ設計であり、
  今すぐ切り出す必然性は薄い。Phase 1（World クラス実装）時に World.create_chunk() の設計として
  自然に行う。それまでは chunk.gd に残して問題なし。
- [ ] **6.（長期）piece_type の enum int 依存を脱却**: PieceData.Type に削除済み CHEST=7 の穴が残る。
  .tscn が piece_type を生 int で持つため番号をずらせない脆さ。将来 StringName/リソース参照へ

### ItemAcceptor を本来の意味で再導入する（方向/アイテムフィルタ）← 将来
- 経緯: 旧 ItemAcceptor は「満杯でなければ受ける＋汎用 Inventory に保持」だけの空の転送層だったため解体済み。
  保持は用途別に分散: Crafter(機械入力=ItemProcessor相当) / ItemEjector(出力) / Delivery(納品計数=hub相当)。
  保管ピース(chest)は削除、汎用 Inventory / ItemAcceptor クラスも廃止済み。
  現状の受け入れ口は get_acceptor() のダックタイピング（Crafter / ConveyorLogic / Delivery）で、**全方向・全アイテムを受け入れる**。
- [ ] 将来「特定の方向からのみ受け入れる」「特定のアイテムのみ受け入れる」設計に変更する際、
  shapez の ItemAcceptorComponent を本来の意味で導入する
  - shapez の ItemAcceptor が持つ4要素: 辺ごとのスロット(pos+direction) / 方向フィルタ / アイテムフィルタ / 流入アニメ
  - 例: ミキサーの色入力スロットは色アイテムのみ、裏面からは入れない 等
  - 現状は NeighborManager が隣接から物理的に入力方向を解決しているだけ。ルールを持たせる時が導入の好機

### piece.gd の描画分離（低優先）
- [ ] 基礎ヘックスタイル生成(_create_hex_tiles)と出力矢印(_refresh_output_arrow / make_output_arrow)を
  PieceBaseVisual 等へ切り出し、piece.gd(221行)をファサード/ロジックに絞る
  （ConveyorVisuals / ItemEjectorVisual と同じ「描画はビジュアル部品」方針の徹底）

### 命名・重複の整理（低優先）
- [ ] `_key` / `hex_to_key` の薄いラッパー(PieceRegistry/HexGrid/GridRenderer ×3)を Hex.to_key 直呼びに統一（軽微）
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] _push_items() をキューベースに最適化（ItemEjector 側のロジック）
- [ ] OutputPort の複数ポート対応テストを追加する
- [ ] ポート回転ロジック(get_rotate_ports 等)を hex クラス等に共通化できないか検討

---

## コンベア（描画・搬送）

### 曲がりをマイター接合で滑らかにする（Phase 2・リトライ予定）
- [ ] 曲がり角の継ぎ目をマイター(角の二等分線カット)で綺麗に繋ぐ
  - 前回失敗: 鋭角(60°)でマイタースパイク→自己交差ポリゴンで描画消失
  - 対策案: マイター長クランプ(超過時ベベル切替)／または hex 専用 left/right カーブ素材(60/120°×14コマ)を生成AIで用意
  - 根本: forward は直線矢印テクスチャなので幾何接合だけでは曲がりの「折れ」は消えない

### コンベア上のアイテム間隔の調整（BeltPath 化）
- [ ] 1ヘックス=最大1アイテムを緩和。参考: shapez itemSpacingOnBelts=0.63。複数アイテムを載せるなら
  TransportLine / BeltPath 方式で再設計（ConveyorLogic はこの時点で大きく変わる）

### コンベア設置UXの改善
- [ ] Factorio(直線制約) / shapez2(パス収集＋自動向き) を参考に検討

---

## ピース・UI（将来）
- [ ] 各ピース(miner/smelter等)に hex 用画像スプライトを用意し、設置描画＋プレビューをスプライト化
  （要アセット準備。仕組みはコンベアで確立済み）
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
- [ ] item_db を tres リソースファイルへ移行する
- [ ] Splitter/Merger を専用ピースでなく既存ラインからの分岐・合流操作で実現（shapez2 流）。
  大掛かりなので専用ピース方式が行き詰まったら再検討

---

## 将来構想（長期）

### chunk の LOD 圧縮
- [ ] 定常状態の chunk を「入力レート→出力レート＋遅延」の集約モデルに圧縮する（LOD / ブラックボックス化）
  - 圧縮トリガーは「定常 かつ 非観測（画面外/非編集）」。過渡状態はフル sim にフォールバック
  - 主効果は CPU とアイテム実体数の削減。注意: 背圧の chunk 境界越え伝播、パズル性との両立
  - 方針: まず単一 chunk のフル sim＋クリーン I/O 契約。圧縮はスケール問題に当たってから

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッド上をキャラクターが移動(chess風)し、敵と戦う要素(gloomhaven風)
