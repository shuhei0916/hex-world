# HexFRVR Unity → Godot 移植 TODO リスト

## Phase 1: コアデータ構造の移植
- [x] TetrahexShapes.gd - テトラヘックス形状定義システム ✅
  - [x] TetrahexType enum定義
  - [x] TetrahexDefinition構造体
  - [x] 7種類の形状データ（Bar, Worm, Pistol, Propeller, Arch, Bee, Wave）

## Phase 2: ゲームマネージャーシステム
- [ ] GridManager.gd - グリッド管理システム
  - [ ] グリッド範囲定義
  - [ ] 占有状態管理
  - [ ] 配置可能性判定
  - [ ] ピース配置/解除機能

- [ ] PieceSpawner.gd - ピース生成システム
  - [ ] ランダムピース生成
  - [ ] スポーン位置管理
  - [ ] 配置完了時の自動補充

## Phase 3: ゲームオブジェクト&UI
- [ ] Piece.gd - ピースオブジェクト
  - [ ] ドラッグ&ドロップ操作
  - [ ] グリッドスナップ機能
  - [ ] ゴースト表示システム
  - [ ] 配置検証ロジック

- [x] GridDisplay.gd - グリッド表示システム ✅
  - [x] Hexグリッドの視覚化
  - [x] GridManagerとの連携

## Phase 4: シーン構成&統合
- [ ] MainScene.tscn - メインゲームシーン
  - [ ] UI要素配置
  - [ ] カメラ設定
  - [ ] ゲームオブジェクト配置

- [ ] 最終調整&テスト
  - [ ] 動作確認
  - [ ] バグ修正
  - [ ] パフォーマンス調整