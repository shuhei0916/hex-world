# todo

## Refactor: Rebuild Grid Display
- [x] GridDisplay: GridManagerへの直接依存を削除する
	- [x] GridDisplay: グリッド生成時に `grid_updated` シグナルを発行する
	- [x] GridDisplay: `register_grid_with_manager` メソッドを削除する（責任範囲外）
- [x] GameLevel (New MainScene): グリッド表示を統合する
	- [x] GameLevel: シーンインスタンス化時にGridDisplayが含まれている（スクリプト内で生成）
	- [x] GameLevel: GridDisplayの `grid_updated` シグナルを受け取り、GridManagerに登録する

## 工場設計システム (Legacy Context)
- [ ] 工場施設配置システムを実装する
	- [ ] プレイヤーインベントリ（パレット）を作成する（マインクラフトのようなUIを想定）
		- [x] Palette: シーンロード時に9スロットが初期化されている
		- [x] Palette: アクティブスロットはデフォルトでインデックス0に設定されている
		- [x] Palette: 数字キー入力（1-9）で対応スロットがアクティブになる
		- [x] Palette: 無効なキー入力ではアクティブスロットが変わらない
		- [x] Palette: アクティブスロットのハイライト状態が変更に追随する
		- [x] Palette: 各スロットに対応するピース種が割り当てられている（1=BAR, 2=WORM, 3=PISTOL, 4=PROPELLER, 5=ARCH, 6=BEE, 7=WAVE）
		- [x] Palette: 割り当てピースの取得APIを提供する
	- [ ] ピース配置システム
		- [x] MainScene: 左クリックでアクティブピースをグリッドに配置する
		- [x] MainScene: 配置済みタイルが占有済みの場合は配置できない
		- [x] MainScene: 選択ピースを切り替えると配置される形状が変わる
		- [x] MainScene: アクティブピースのプレビューがカーソルに追随する
		- [x] MainScene: 右クリックでプレビュー位置にピースを確定配置する
	- [ ] パレットUIを実装する
		- [x] PaletteUI: シーン生成時に9つのスロットノードが作成される
		- [x] PaletteUI: アクティブスロット変更シグナルでハイライトが更新される
		- [x] PaletteUI: メインシーンの画面下部に配置される
		- [ ] PaletteUI: ツリー未接続でもパレットデータ取得が安全に行える
	- [ ] 1から9の数字キー入力で該当のピースを「持つ」ことが出来る
	- [ ] マウスホイールで１から９のピースを指定できる
	- [ ] 指定された、あるいは「持つ」状態のピースはハイライトされる（これもマイクラと同じ）
	- [ ] 配置プレビュー機能を実装（詳しくはUnityで実装したバージョンを参考に）
	- [ ] 施設の配置を実装する
	- [ ] 施設の削除、移動機能を実装する。