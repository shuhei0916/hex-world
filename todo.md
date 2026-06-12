# todo

## 効果音の導入（feature/sfx）

assets/sounds/sfx の素材（shapez由来）を使用する。

### Chunkシグナル
- [ ] place_piece すると piece_placed シグナルが発火する
- [ ] remove_piece_at が成功すると piece_removed シグナルが発火する
- [ ] remove_piece_at が失敗したときは piece_removed は発火しない

### SfxPlayer
- [ ] ピース設置で place_building.wav が再生される
- [ ] コンベア設置では place_belt.wav が再生される
- [ ] ピース削除で destroy_building.wav が再生される
- [ ] ツールバーでピースを選択すると ui_click.wav が再生される
- [ ] ツールバー選択解除（null）では音が鳴らない

### 統合
- [ ] main シーンでピースを設置すると音が鳴る（配線確認）
- [ ] 起動時の DELIVERY ZONE 自動配置では音が鳴らない（接続順で担保）

## コンベア専用化・1アイテム保持モデル（feature/conveyor-single-item）

shapez1 のベルト設計を参考に、コンベアを「容量1・位置ベース搬送」に変更する。
インベントリ(カウント式バッファ)はコンベアから廃止する。

### 保持モデル
- [x] conveyor.tscn のルートは Conveyor 型である（piece is Conveyor が true）
- [x] 空のコンベアは can_accept_item が true を返す（既存挙動で充足・保持中テストの対で担保）
- [x] add_item したアイテムは get_item_count で数えられる
- [x] アイテム保持中のコンベアは can_accept_item が false を返す（容量1）

### 搬送
- [x] tick 0.4秒ではアイテムは接続先に渡らない
- [x] tick 0.5秒でアイテムが接続先ピースに渡る（既存テスト「Outputから接続先ピースへアイテムが搬出される」で担保）
- [x] 転送後、コンベアは空になる（get_item_count が 0）
- [x] 転送後、コンベアは再び受け入れ可能になる（can_accept_item が true）
- [x] 接続先が受け入れ不可の間、アイテムは保持されたまま消えない
- [x] 接続先が受け入れ可能になったら、その後の tick で転送される
- [x] 接続先が存在しない場合、アイテムは保持されたまま

### 接続（Chunk/NeighborManager 経由）
- [x] Chunk に配置したコンベアに接続先が設定され、隣のピースへアイテムが流れる（既存テストで担保）
- [x] 機械の Output からコンベアへアイテムが push される
- [x] コンベア→コンベアのチェーンでアイテムが1個ずつ流れる

### シーン構造
- [x] conveyor は Input ノードを持たない
- [x] conveyor は Output ノードを持たない
- [x] splitter も同モデルに移行する（splitter.tscn は ConveyorLogic を共有しているため。2出力のラウンドロビン分配は維持）

### 表示
- [x] アイテム保持中はアイコンが表示される
- [x] アイテム非保持時はアイコンが非表示
- [x] 進行度に応じてアイコンがコンベアライン上を移動する（進行度0で入力エッジ位置）

### リファクタリング候補（テスト不要・挙動維持）
- [x] piece.gd のコンベア専用コード（_conveyor_line / _input_direction / set_input_direction / _refresh_conveyor_line）を conveyor.gd へ移管
- [x] NeighborManager の piece.piece_type == CONVEYOR 判定を piece is Conveyor に変更

## ゲームプレイ・コンテンツ
### 自動化要素の強化
- [ ] 強化鉄板のレシピを追加する（複数入力対応後）
- [ ] mixerでscrewを生産するなど、直感的でないレシピを調整する。


### 納品所（Delivery Zone）実装
- [ ] 地面のタイルを多様化させる（kenney assetsを使うのもありかも）

### ゲームの別路線の開拓（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッドの上をキャラクターが移動したり（chessのような感じ）、敵と戦ったりできる要素（gloomhavenなど）

## リファクタリング

### piece, test_piece関連
- [ ] いまはoutputとinputを同じへクスに表示しているが、これを別々のへクスに表示したい。
  - [x] smelter に input_hex 設定済み・回転追従実装済み
  - [ ] assembler, cutter, mixer, painter に input_hex を設定する
  - [ ] output アイコンも回転追従させるか検討（port_hex を利用）
  - [ ] 1ヘックスピース（conveyor, chest）は現状のまま（変更不要か確認）

#### 将来検討
- [ ] 命名を shapez に揃えるリネーム検討（piece → building 等）
  - 背景: 本プロジェクトは六角形版 shapez を軸としており、アイコン・音素材も shapez 語彙（belt, balancer, place_building 等）のため、コードとアセットで用語がずれている
  - 影響範囲: gd ファイル25個・約630箇所（Piece/PieceData/PiecePlacer/piece_registry/get_piece_at_hex 等）+ ディレクトリ名・シーンパス・テスト名
  - 留意点: パズル要素（piece_shape, PiecePlacer）は piece の方が自然な箇所もあるため、一括置換ではなく対訳表を作ってから実施する
- [x] Conveyor extends Piece 継承に切り出す（feature/conveyor-single-item で実施済み）
- [ ] InputHandler クラスを抽出し main.gd の入力処理を委譲
- [ ] crafter.gd に enum CraftingState を導入し状態遷移を明示化
- [ ] output.gd の _push_items() をキューベースに最適化
- [ ] piece.gd / input.gd の `add_item` / `consume_item` インターフェースを整理
- [ ] input.gd / output.gd の共通 InventoryContainer 基底クラスを抽出する
- [ ] OutputPort の複数ポート対応テストを追加する
- [ ] コンベア設置UXの改善（Factorio: 直線制約、shapez2: パス収集＋自動向き、を参考に検討）
- [ ] Splitter/Mergerを専用ピースではなく、既存コンベアラインからの分岐・合流操作で実現する（shapez2ではsplitter/merger自体が廃止されている）。UXとして親切だが大掛かりな変更になるため、専用ピース方式が立ち行かなくなった場合に再検討する
- [ ] コンベアアイテム搬送アニメーション（TransportLine方式）
  - 設計方針: シミュレーション+描画分離。アイテムを progress 付き配列で管理し _physics_process で前進、描画は Sprite2D プール or MultiMeshInstance2D
  - ベルト表面は UV スクロールシェーダー
  - 難易度: 高（描画位置の座標系、詰まり・分岐ロジック、既存アーキテクチャとの統合が複雑）

### それ以外
- [ ] item_dbをtresファイルを使ったリソースファイルへ移行する

## 検討中のタスク・メモなど（AIはこれを編集・削除しないでください）
- [ ] マウスホイールでツールバーに割り当てられたピースの選択ができるようにする
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
