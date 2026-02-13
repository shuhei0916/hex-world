# todo

## PieceDBとPieceDataの統合リファクタリング
- [ ] `PieceData` を独立したトップレベルクラスとして定義する (`scenes/utils/piece_data.gd`)
- [ ] 旧 `PieceDB.PieceType` を `PieceData.Type` として移行する
- [ ] 旧 `PieceDB.DATA` を `PieceData` の静的メンバとして移行する
- [ ] `Piece.setup` の引数を `PieceData` インスタンスに変更する
- [ ] 既存のテストコードを新しい `PieceData` に対応させる
- [ ] `PieceDB.gd` を削除する

## ゲームプレイ・コンテンツ
### 自動化要素の強化
- [ ] 裁断機やプレス機など、ほかのroleも追加する
- [ ] 鉄パイプ、強化鉄板のレシピを追加する
- [ ] グリッドのランダムなヘックスに納品所を設置する実装を行う

### ゲームの別路線の探索（戦闘要素）
- [ ] 新しいシーンを作成し、グリッドを作成する
- [ ] グリッドの上をキャラクターが移動したり（chessのような感じ）、敵と戦ったりできる要素（gloomhavenなど）

## リファクタリング
### piece, test_piece関連
- [ ] piece.setupからdata_overrideを削除し、下記のようにクリーンにできないか検討する
```
setup側：
setup(piecedata: PieceDB.PieceData, rotation: int = 0)

呼び出し側（オリジナルのテスト用ピースを定義する場合）：
var out_data = PieceDB.PieceData.new([Hex.new(0, 0)], [{"hex": Hex.new(0, 0), "direction": 0}], "test")
piece.setup(out_data)

呼び出し側（既存のピースを使う場合）：
piece.setup(PieceDB.PieceType.CHEST)
```
- [ ] pieceクラスにおいて、機能部分とview部分が混在しているので, これを修正するべきか検討する
- [ ] チェスト(Storage)などのピースタイプに応じて、ItemContainerコンポーネントの生成構成を最適化する（Input/Outputで実体を共有するなど）
- [ ] crafter.gdにある、0.001等のマジックナンバーは不吉な臭いなので、これを修正する
- [ ] piece.gd: destinationよりもconnected_pieceの方が分かりやすいか、命名変更を検討する。
- [ ] PIECE_SCENEを使っているところを削除し、Piece.new()で代用する（純粋な単体テスト化）

### それ以外
- [ ] grid_managerのテストコードに内部クラスを追加して構造化する
- [ ] grid_managerの責務が膨大となっているので、これを分離する
- [ ] test_main: 内部クラスに整理し、命名を日本語に統一する
- [ ] paletteとpalette_uiの責務分離が分かりづらい。統合したほうが良いか検討する。
- [ ] item_dbをtresファイルを使ったリソースファイルへ移行する


## 検討中のタスク・メモなど（AIはこれを編集・削除しないでください）
- [ ] マウスホイールでツールバーに割り当てられたピースの選択ができるようにする
- [ ] ポート回転ロジック(get_rotate_portsなど)は、hexクラス等に共通化できるかも。検討する
- [ ] 詳細表示モード時に、インプットとアウトプットの表示が重なる問題を修正する（レイアウト調整）。
- [ ] pallette uiをhexfrvrによせる。
- [ ] ピースの種類を増やす（テトラへクス以外にも色々）
- [ ] ピースをグループ化し、パレットでカテゴリごとに表示する。
- [ ] マウスオーバーで設置済みピースの詳細情報ラベルが表示される
