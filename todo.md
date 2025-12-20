# todo

- [ ] ピースの実体化（Pieceノードの導入）
    - [x] Pieceクラスは初期化データを受け取り、タイプと座標を保持できる
    - [x] place_piece()が呼ばれると、Pieceノードが生成されシーンに追加される
    - [x] place_piece()で生成されたPieceノードは、正しい座標に配置される
    - [x] remove_piece_at()が呼ばれると、対象のPieceノードがqueue_freeされる
    - [x] remove_piece_at()が呼ばれると、GridManagerの内部管理マップからPieceが削除される

## 将来的なタスク
- [ ] PaletteUI を Toolbar にリネームする
- [ ] Pieceの機能拡張
    - [ ] Pieceはインベントリを持ち、アイテムを追加・取得できる
    - [ ] Piece上にインベントリ数を表示するUIが表示される
    - [ ] Pieceは時間経過(tick)で状態を更新できる