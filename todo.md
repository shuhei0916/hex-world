# todo

## 直近タスク
- [ ] WASDでカメラを動かせるようにする。

## リファクタリング

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

### chunk.gd の責務分離
- [ ] 世界生成ロジック(generate_ore_deposits / place_delivery_zone / mark_resource_hex)を
  WorldGenerator 等へ切り出し、Chunk をグリッド＋ピース管理のファサードに絞る（現状 ~255 行）
  - shapez が MapGenerator を分けているのと同じ方向

### piece.gd の描画分離（低優先）
- [ ] 基礎ヘックスタイル生成(_create_hex_tiles)と出力矢印(_refresh_output_arrow / make_output_arrow)を
  PieceBaseVisual 等へ切り出し、piece.gd(221行)をファサード/ロジックに絞る
  （ConveyorVisuals / ItemEjectorVisual と同じ「描画はビジュアル部品」方針の徹底）

### 命名・重複の整理（低優先）
- [ ] ConveyorLogic と SplitterLogic は ~80% 重複(TransferBuffer+委譲+tick)。ただし統合は非推奨
  （コンベアは将来 BeltPath 化で分岐見込み）。気になれば委譲ボイラープレートのみ基底化
- [ ] 語彙の混在整理: shapez系(ItemEjector/ItemAcceptor/EjectorRouter) と自前(ConveyorLogic/SplitterLogic/
  Crafter/ConveyorVisuals)。shapez 厳密には belt/balancer/ItemProcessor。Crafter は据え置き推奨
- [ ] `_key` / `hex_to_key` の薄いラッパー(PieceRegistry/HexGrid/GridRenderer ×3)を Hex.to_key 直呼びに統一（軽微）
- [ ] InputHandler クラスを抽出し main.gd の入力処理を委譲
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] _push_items() をキューベースに最適化（ItemEjector 側のロジック）
- [ ] OutputPort の複数ポート対応テストを追加する
- [ ] ポート回転ロジック(get_rotate_ports 等)を hex クラス等に共通化できないか検討

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

## ピース・UI（将来）
- [ ] 各ピース(miner/smelter等)に hex 用画像スプライトを用意し、設置描画＋プレビューをスプライト化
  （要アセット準備。仕組みはコンベアで確立済み）
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
- [ ] item_db を tres リソースファイルへ移行する
- [ ] Splitter/Merger を専用ピースでなく既存ラインからの分岐・合流操作で実現（shapez2 流）。
  大掛かりなので専用ピース方式が行き詰まったら再検討

## 将来構想（長期）

### chunk の階層化と LOD 圧縮
- [ ] chunk に6方向の input/output ポート（エッジ契約）を持たせ、隣接 chunk と接続できるようにする
  - chunk = 製造ラインを内包した「合成可能な部品」。chunk of chunks の多重構造で大工場を構築する構想
  - 設計の核はエッジ I/O 契約（各辺＝アイテム種別＋レート＋背圧 backpressure のストリーム）。これを先にきれいに作る
- [ ] 定常状態の chunk を「入力レート→出力レート＋遅延」の集約モデルに圧縮する（LOD / ブラックボックス化）
  - 圧縮トリガーは「定常 かつ 非観測（画面外/非編集）」。過渡状態はフル sim にフォールバック
  - 主効果は CPU とアイテム実体数の削減。注意: 背圧の chunk 境界越え伝播、パズル性との両立
  - 方針: まず単一 chunk のフル sim＋クリーン I/O 契約。圧縮はスケール問題に当たってから

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッド上をキャラクターが移動(chess風)し、敵と戦う要素(gloomhaven風)
