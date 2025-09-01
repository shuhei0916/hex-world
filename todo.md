- [x] マウスポインタのhex座標を取得し、表示する
- [x] デバッグモードを実装する（F2キー押下でトグル）
    - [x] hexにaxial座標をオーバーレイで表示する。
- [x] playerを作成（画像はassets/icon.svgを使用）
    - [ ] playerの動きを作成：クリックした座標に向かう
        - [x] Player基盤修正（CharacterBody2D対応）
        - [x] クリック検出システム実装
        - [x] Player移動システム実装
        - [x] 移動実行処理実装
        - [ ] 移動完了処理実装
            - [ ] redblobgamesを参考に、pathfindingのコードを実装する。
                - [x] HexGraphクラスを作成（hex座標系のGraph実装）
                - [x] PriorityQueueクラスをGDScriptで実装
                - [x] A*アルゴリズム基本実装（AStarPathfinderクラス）
                - [x] Hex座標用ヒューリスティック関数実装
                - [x] パス復元機能実装
                - [x] Player.calculate_movement_path()をA*に置換
                - [ ] 障害物対応（GridManagerとの連携）
                - [ ] 統合テストとパフォーマンス確認
        - [ ] playerがhexの中央に位置するようにする
        - [ ] 移動する際、道のりをハイライトするようにする。
    - [ ] playerのインベントリを作成
- [ ] playerのインベントリから建造物（tetrahexユニット）を配置できるようにする。

## リファクタリング
- [ ] 本来はevent.positionを変換して使うべき実装を正す。
- [ ] playerがgridの外に移動できてしまう問題を解決する。
  