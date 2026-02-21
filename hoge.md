 Piece (Node2D) [piece.gd]
 │
 │
 │
 ├── Input (Node2D): 接続元からピースを受け入れたりする
 │   └── Icon (Sprite2D): 現在入力にあるアイテムのアイコンを表示
 │       └── CountLabel (Label): 現在入力にあるアイテムの個数を表示
 │
 ├── Crafter (Node) [crafter.gd]: 入力にあるアイテムを消費し、レシピに従ってアイテムを生成、出力に追加する
 │   └── ProgressBar: 0から100までで生産状態を示すプログレスバー
 │
 ├── Output (Node2D) : 接続済みの別ピースがあり、受け入れ可能ならそこへアイテムを送る。なければ20個までアイテムをスタックしておく
 │   └── Icon (Sprite2D)
 │       └── CountLabel (Label)
