# todo

## ゲームプレイ・コンテンツ


## リファクタリング
### piece, test_piece関連
- [ ] pieceクラスにおいて、機能部分とview部分が混在しているので、これを修正するべきか検討する
- [ ] チェスト(Storage)などのピースタイプに応じて、ItemContainerコンポーネントの生成構成を最適化する（Input/Outputで実体を共有するなど）
- [ ] crafter.gdにある、0.001等のマジックナンバーは不吉な臭いなので、これを修正する
- [ ] piece.gd: destinationよりもconnected_pieceの方が分かりやすいか、命名変更を検討する。
- [ ] PIECE_SCENEを使っているところを削除し、Piece.new()で代用する（純粋な単体テスト化）
- [ ] ピースの配置が下記のようにシンプルにならないか検討する（test_piece.gdなど）
	```
	var a = Piece.new()
	var b = Piece.new()
	a.hex_coordinates = [Hex.new(0,0)]
	b.hex_coordinates = [Hex.new(1,0)]
	assert_true(a.can_push_to(b))
	```
### それ以外
- [ ] grid_managerのテストコードに内部クラスを追加して構造化する
- [ ] test_main: 内部クラスに整理し、命名を日本語に統一する
- [ ] paletteとpalette_uiの責務分離が分かりづらい。統合したほうが良いか検討する。

## 将来的なタスク・メモなど（AIはこれを編集・削除しないでください）
- [ ] マウスホイールでツールバーに割り当てられたピースの選択ができるようにする
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] 詳細表示モード時に、インプットとアウトプットの表示が重なる問題を修正する（レイアウト調整）。
- [ ] pallette uiをhexfrvrによせる。
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
