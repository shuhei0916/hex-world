# 引き継ぎメモ（2026-07-10時点）

ブランチ: `refactor/pre-chunk-ports`

## 今回のセッションの目的
1. 新機能（チャンク間アイテム送信ピース）を実装する前に、リファクタリングすべき箇所を洗い出して対応する
2. その後、隣接チャンクへアイテムを送信するピースを実装する

## フェーズ0: 事前リファクタリング（完了・未コミット）

以下2件を実施済み。全364テスト（91スクリプト）通過を確認済みだが、**まだコミットしていない**（ユーザーの明示的な許可待ち）。

1. **`Main._mode` の削除**
   - `scenes/main/main.gd`
   - `enum Mode` と `_mode` 変数を削除し、`is_local_mode()` は `world.visible` を返すように変更
   - `_toggle_mode()` / `_handle_mouse_click()` もこれに合わせて修正
   - 既存の `tests/unit/main/test_main.gd` で担保済み

2. **`Chunk` の資源ロジック分離**
   - 新規ファイル `scenes/components/chunk/chunk_resources.gd`（`extends RefCounted`）を作成
   - `Chunk`（`scenes/components/chunk/chunk.gd`）が持っていた `_resources` 辞書・`mark_resource_hex()` / `get_hex_resource()` / `generate_ore_deposits()` / `_apply_mining_constraint()` の実処理を移動
   - `Chunk` 側は委譲のみの薄い層として残し、公開APIは変更なし（`tests/unit/components/chunk/test_chunk.gd` で担保）
   - `generate_ore_deposits()` は `ChunkResources` 側でクラスター（`Array[Hex]`）を返すよう変更し、`Chunk` 側でそのクラスターだけタイルに色を塗る形にした（元は全 inner_hexes を舐めていた非効率な実装を一度書いたが、クラスターを返す形に直した）

### todo.md への反映
`todo.md` の「事前リファクタリング（refactor/pre-chunk-ports）」セクションにチェック済み。

### 未着手のリファクタ候補（今回は対象外、todo.md に別途起票済み）
- `Piece` のビジュアル分離（`_output_arrow` 生成・HexTile 生成 → `PieceVisuals`）
- `Main` の入力処理分離（`InputHandler` への切り出し）
- `Crafter` の `HubGoals` 依存緩和
- `NeighborManager` の接続更新フローの結合テスト充実

## フェーズ1: 隣接チャンクへの送信ピース（未着手）

新規ブランチ `feature/chunk-sender` で実施予定。

### 設計方針（ユーザー未確定、提案段階）
- **Sender（送信ピース）**: チャンク外周ヘックス（`Chunk.get_outer_hexes()` が既存）にのみ配置可能な1ヘックスピース。アイテムを受け入れ（acceptor）、配置位置の辺方向から隣接チャンクを判定して送る。
- **チャンク間の橋渡し**: `Sender` がシグナル（例: `item_sent(item_name, chunk_direction)`）を発火し、`World`（`scenes/components/world/world.gd`）が隣接チャンクへ届ける。非アクティブチャンク（`visible=false`）も tick は動いているため受信可能。
- **Receiver（受信ピース）**: 対辺の外周に置く。届いたアイテムをバッファし、通常の Output/ejector として下流へ流す。

### 未確定の論点（次セッションでユーザーに確認すること）
1. Sender/Receiver を別ピースにするか、1ピースで送受信を兼ねるか → 現在は「別ピース」で提案中
2. 受信側ピース未設置時の挙動 → 「保留（送信側が詰まる）」で提案中
3. 外周ヘックスの「どの辺（6方向のうちどれ）に属するか」の判定ルール
   - `get_outer_hexes()` は `max(|q|,|r|,|s|)==radius` で判定しているが、方向までは出していない
   - 角のヘックスは2辺にまたがるため、一意化のルール（例: 時計回り優先）が必要

### テストリスト（概要、着手時に todo.md へ詳細化してから1件ずつRed→Green）
- 外周ヘックスの辺方向判定（→隣接チャンク座標の算出）
- Sender は外周以外のヘックスには配置できない
- Sender がアイテムを受け入れると `World` 経由で隣接チャンクに届く
- 隣接チャンクに Receiver があればそのバッファに入る／なければ送信保留
- Receiver から下流コンベアへ排出される
- HUD に Sender/Receiver スロットを追加

## 次にやること
1. （ユーザー許可を得てから）フェーズ0の変更をコミット
2. 上記「未確定の論点」をユーザーに確認
3. todo.md にフェーズ1のテストリストを具体化
4. TDDサイクル（Red→Green→Refactor、1サイクル1コミット）でSender実装に着手
