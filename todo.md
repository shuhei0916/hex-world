# todo

## 直近タスク
- [ ] WASDでカメラを動かせるようにする。

## リファクタリング

### ★次セッション着手予定（クリーン化 + chunk/hub）
推奨順: 1 → 4(+3) → 5 → 2。理由: これから触る chunk 周りを先に整理(1)、命名を固め(4,3)、
サイズを入れ(5)、独立改善の配送統合(2)を最後に。

- [ ] **1. WorldGenerator 抽出（最優先）**: chunk.gd(255行)が ①グリッドのファサード ②ピース管理
  ③ワールド生成 の3責務を抱える。③(generate_ore_deposits / place_delivery_zone / mark_resource_hex /
  _apply_mining_constraint / get_inner/outer_hexes / RESOURCE_COLORS)を WorldGenerator へ切り出し、
  Chunk をグリッド＋ピース管理のファサードに絞る。shapez の MapGenerator 分離と同方向。
  → chunk サイズ・hub 配置・鉱床をこれから触るので、先に着地点を綺麗にする
- [ ] **2. 配送ロジックの三重化を解消**: 「1個保持→受け入れ可能な接続先へ押し出す」が3実装ある
  （ConveyorLogic._try_deliver の手書きループ / SplitterLogic→EjectorRouter / ItemEjector→EjectorRouter）。
  ConveyorLogic._try_deliver は EjectorRouter の再発明なので、ConveyorLogic を EjectorRouter ベースに統一。
  ※「将来 BeltPath 化で分岐」は投機的・長期。今は EjectorRouter 重複の解消にとどめ、BeltPath 実現時に分ける
- [ ] **3. place_delivery_zone の死にコード除去**: chunk.gd の GoalLabel.text 設定は Stage3 で
  Delivery.setup()→_update_label() が担うようになったため重複。除去（hub リネームのついでに）
- [ ] **4. delivery → hub リネーム + balancer 命名統一**: class Delivery→Hub / ファイル/ノード名 /
  place_delivery_zone / PieceData.Type.DELIVERY / テスト。併せて splitter は shapez では balancer
  （アイコンは balancer.png、HUDは「スプリッター」表記で混在）。どちらかに統一
- [ ] **5. chunk サイズを shapez 16×16(256) 相当に**: 六角形なら半径9=271タイル（256に最も近い。
	半径8=217も可）。現状 grid_radius=4(61)。定数化して world gen に反映
  - 形状判断は保留可（単一チャンクの今は六角形で十分。chunk of chunks 実装時に菱形=256 を再検討）
	- 菱形は axial を n×n 埋めた60°傾きの平行四辺形。平面を隙間なく敷き詰められchunk合成向き
  - hub 移動可否も未定（shapez は固定。現状 delivery も削除不可で実質固定）
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
