# todo
- [ ] プロジェクトの構造をgodotのベストプラクティスに準拠させる。
- [ ] grid displayの命名変更
- [ ] GridManagerシングルトンを廃止し、シーンに配置するGridManagerノードに統合する
	- [ ] project.godotからGridManagerのAutoload設定を削除する
	- [ ] scripts/grid_manager.gdをNode2Dを継承するクラスにリファクタリングし、GridDisplayの描画ロジックを統合する
	- [ ] scripts/grid_display.gdを削除する
	- [ ] GameLevelで新しいGridManagerノードを参照し、GridDisplayの動的生成を削除する
	- [ ] 他のクラス（PieceSpawner, MainSceneなど）から新しいGridManagerノード経由でアクセスするように修正する
	- [ ] test_grid_manager.gdを新しいGridManagerノードをインスタンス化するテストに書き換える
	- [ ] test_grid_display.gdを削除する
	- [ ] test_game_level.gdが新しいGridManagerノードを正しく参照しているか検証する

## その他
- [ ] マウスホイールで１から９のピースを指定できる
- [ ] 指定された、あるいは「持つ」状態のピースはハイライトされる（これもマイクラと同じ）
- [ ] 配置プレビュー機能を実装（詳しくはUnityで実装したバージョンを参考に）
- [ ] 施設の配置を実装する
- [ ] 施設の削除、移動機能を実装する。
