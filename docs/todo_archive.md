# 完了済みタスクの記録

2026-11-11 に todo.md から移動した、完了済みセクションの記録（設計方針・背景の参照用）。
`[→]` は未完了のまま todo.md へ移した項目。

## World配線ロジックの整理（refactor/world-wiring）

**背景**: `_rewire_all_senders` / `get_receiver_hint_hexes` / `get_connected_chunk_pairs` の3箇所が
「全チャンク×全ピースを走査してSENDERを絞り込み、edge_dir==-1を除外する」処理を重複して持っている。
また pointy-top/flat-top の30°ズレ補正（`_to_world_direction`）と辺内対応位置の軸入替（`_mirror_hex`）が
World に直接書かれており、座標系の知識が配線ロジックと混在している。
既存のWorld関連テスト（27件）を安全網として、振る舞いを変えずに整理する（Refactorフェーズのため新規テスト無し、既存テストの全通過で担保）。

- [x] 座標系の知識（`_to_world_direction` / `_mirror_hex`）を `ChunkTopology`（新規 utils）へ切り出す
- [x] `_rewire_all_senders` / `get_receiver_hint_hexes` / `get_connected_chunk_pairs` に共通する
	  「全チャンクからedge_dir有効なSenderを列挙する」処理を `_iter_senders()` に一元化する
- [x] 上記整理後も既存435テストが全通過する

## world mapホバーハイライト（feature/world-map-hover-highlight）

**方針**: ChunkTile に is_hovered を追加し、is_active と同様に色を変える（ホバー色はアクティブ色と別系統）。
WorldMapView.set_hovered_chunk(chunk_hex) で対象タイルをホバー状態にし、前回分は解除する。
main.gd の _handle_mouse_motion で world map モード時にマウス位置→hex変換してset_hovered_chunkを呼ぶ。

- [x] WorldMapView.set_hovered_chunk(chunk_hex)でそのタイルがホバー状態になる
- [x] set_hovered_chunk切り替えで前のタイルのホバーが解除される
- [x] set_hovered_chunk(null)でホバーが解除される
- [x] アクティブなタイルはホバーされても色が変わらない（アクティブ表示を優先）
- [x] main: world mapモードでのマウス移動でホバー先タイルが更新される
- [x] （目視）ホバーハイライトの見た目確認（2026-08-05、xvfb+xdotool+scrotでワールドマップ上のマウス移動を再現し、アクティブ色(緑)とホバー色(青)が別系統で表示されることを確認）

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
- [x] Sender/Receiver の接続状態可視化（矢印・色）→ 下記「接続状態可視化（3段階）」で完了

### 接続状態可視化（3段階で実装）
1. 接続成立時の色変化: Sender/Receiverが接続中は緑系、未接続はデフォルトの色になる
2. 矢印表示: Senderの辺の外側に、接続先チャンクへ向かう矢印アイコンを表示する
3. ワールドマップでの接続辺表示: Sender/Receiverが実際に繋がっているチャンク間の辺を線・矢印で表示する

#### 1. 接続時の色変化
- [x] Piece.has_connected_piece()は接続先ピースがあるときtrueを返す（is_connectedはObject既存メソッドと衝突するため改名）
- [x] Sender/Receiverは接続時にmodulateが変わる
- [x] 接続解除でmodulateが元に戻る
- [x] （目視）色変化の見た目確認（2026-08-03、Piece.modulateだと矢印も緑に染まるためHexTile個別に着色するよう修正）

#### 2. 矢印表示
- [x] Senderが接続中のとき、辺の外側（接続先チャンクへ向かう方向）に矢印が表示される
- [x] 接続解除で矢印が消える
- [x] 未接続のSenderには矢印が表示されない
- [x] （目視）矢印の見た目確認（2026-08-03、通常起動+スクリーンショットでデバッグ。z_index不足と緑同士の重なりが原因と判明し修正）
- [→] 矢印の向き・描画位置の微調整（現状は動作確認レベル。位置バランスや大きさを見た目で調整する）（todo.md へ移動）

#### 3. ワールドマップでの接続辺表示
- [x] World.get_connected_chunk_pairs()は接続済みSenderがあるチャンクペア(sender側hex, receiver側hex)の一覧を返す
- [x] Sender/Receiverが未接続なら、そのペアは含まれない
- [x] Sender撤去済み・Receiver不在なら、そのペアは含まれない
- [x] WorldMapView.refresh_connections(pairs)で、線ではなくチャンクの境目に矢印が表示される（2026-08-04、線表示から矢印表示に変更。get_connection_line_count→get_connection_arrow_countにリネーム）
- [x] 接続がないペアには矢印が表示されない
- [x] 再表示のたびに前回分の矢印がクリアされる
- [x] World: ワールドマップ表示に入るたびに最新の接続チャンクペアの矢印が表示される（main._enter_world_map_mode）
- [x] （目視）ワールドマップでの接続矢印の見た目・向きを確認（2026-08-04、通常起動+スクリーンショットで境目に正しい向きで表示されることを確認）
- [→] ワールドマップの接続矢印の内部に、搬送中のアイテムのアイコンを表示する（現状はただの矢印のみ）（todo.md へ移動）

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
- [→] ワールドマップの表示位置が画面下寄りで一部見切れる（既存問題、位置調整は別途）（todo.md へ移動）

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
- [x] 隣接するchunkにアイテムを送信する用のピースを追加する。→ feature/chunk-transporter（Sender/Receiver）で完了

## Tierごとの生産速度差別化（feature/tier-speed）
- [x] `Crafter` に `@export var craft_time_multiplier: float = 1.0` を追加する
- [x] `_effective_craft_time()` が `craft_time_multiplier` を乗算する
- [x] `craft_time_multiplier > 1.0` のとき加工時間が長くなる（低速化）
- [x] 各 t1 シーンの Crafter ノードに `craft_time_multiplier = 2.0` を設定（暫定値・要バランス調整）

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

## バリアント選択UI（feature/variant-selector）

**方針**: PieceInfoPanel 下部にバリアント選択行を追加。T キーで循環、クリックでも直接選択。バリアント1つなら非表示。

- [x] バリアントが2つ以上のスロット選択時、情報パネルにバリアントボタン行が表示される
- [x] バリアントが1つのスロット選択時、バリアントボタン行が非表示になる
- [x] 選択解除時、バリアントボタン行が非表示になる
- [x] バリアントボタン数がバリアント数と一致する
- [x] 現在選択中のバリアントボタンが強調（pressed）状態になる
- [x] バリアントボタンをクリックするとバリアントが切り替わり slot_selected が発火する
- [x] T キーで循環するとバリアントボタンの強調が更新される

## 分岐の上書きバグ修正（fix/conveyor-branch-overwrite）

**再現**: 本線 (0,-2)→(-1,-1)→(-2,0)→(-3,1)（SW向き）を設置 → (-2,0)→(-2,1)→(-3,2) とドラッグして分岐①
→ (-2,0)→(-3,0)→(-4,0) とドラッグして分岐② を引くと、(-2,0)→(-2,1) の接続が切れる。
**原因**: ドラッグ始点の既存コンベア（分岐元）が置き直され出力ポートが分岐②に奪われる。分岐①の先頭は曲がっているため自然な分岐の条件（直進）を満たさない。

- [x] 分岐を2本引いたあとも、1本目の分岐（先頭で曲がる分岐）が分岐元とつながっている
- [x] 分岐を2本引いたあとも、分岐元は本線の下流とつながっている
- [x] 分岐を2本引いたあと、2本目の分岐も分岐元とつながっている
- [x] 分岐を2本引いたあと、1本目の分岐の先頭のベルトは分岐元の方向から曲がって描かれる（入力方向が分岐元を向く）
- [x] 先頭で曲がる分岐の先頭コンベアを始点にさらに分岐を引いても、その先頭コンベアは分岐元とつながったままになる（始点の置き直しで入力方向が失われない）

## 自然な分岐（feature/conveyor-natural-branching）
- [x] ConveyorVisuals は output_directions が複数のとき、各方向へ1本ずつベジェを描く
- [x] NeighborManager は接続更新後に ConveyorVisuals へ出力方向リストを渡す
- [x] コンベアBの入力方向がコンベアAを向くとき、AはBを出力先に自動追加する（自然な分岐）
- [x] BalancerLogic を廃止し ConveyorLogic に統合する
- [x] balancer.tscn を廃止し conveyor.tscn のみで分岐を実現する（2026-11-11 確認時点で balancer.tscn は削除済み）

## 事前リファクタリング（refactor/pre-chunk-ports）

- [x] `Main._mode` を削除し、`is_local_mode()` が `world.visible` を返す（既存テストで担保）
- [x] `Chunk` の資源関連ロジック（`_resources` / `mark_resource_hex` / `get_hex_resource` / `generate_ore_deposits` / `_apply_mining_constraint`）を `ChunkResources` に分離する
	- [x] `ChunkResources.mark_resource_hex` / `get_resource` が資源を記録・取得できる
	- [x] `ChunkResources.apply_mining_constraint` が鉱床0のMINERのレシピをnullにする
	- [x] `ChunkResources.apply_mining_constraint` が鉱床数をoutput_multiplierに設定する
	- [x] `Chunk` の既存公開API（mark_resource_hex 等）は委譲として維持され、既存テストが通る

## デバッグオーバーレイ（feature/debug-overlay）
- [x] toggle() を呼ぶたびに visible が反転する
- [x] refresh(chunk) 後、chunk の全ヘックス分のラベルが生成される
- [x] ピース配置済みヘックスではピース名がラベルに含まれる

## チャンク間連携（将来）
- [x] チャンク間アイテム移動: Chunk の辺にポート（入出力）を定義。ワールドマップ上でフロー表示 → feature/chunk-transporter で完了（Sender/Receiver・ワールドマップの接続矢印）
