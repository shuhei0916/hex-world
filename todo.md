# HexFRVR Unity → Godot 移植 TODO リスト

## Phase 1: コアデータ構造の移植
- [x] TetrahexShapes.gd - テトラヘックス形状定義システム ✅
  - [x] TetrahexType enum定義
  - [x] TetrahexDefinition構造体
  - [x] 7種類の形状データ（Bar, Worm, Pistol, Propeller, Arch, Bee, Wave）

## Phase 2: ゲームマネージャーシステム
- [x] GridManager.gd - グリッド管理システム ✅
  - [x] グリッド範囲定義
  - [x] 占有状態管理
  - [x] 配置可能性判定
  - [x] ピース配置/解除機能

- [x] PieceSpawner.gd - ピース生成システム ✅
  - [x] ランダムピース生成
  - [x] スポーン位置管理
  - [x] 配置完了時の自動補充

## Phase 3: ゲームオブジェクト&UI
- [x] Piece.gd - ピースオブジェクト ✅
  - [x] ドラッグ&ドロップ操作
  - [x] グリッドスナップ機能
  - [x] ゴースト表示システム
  - [x] 配置検証ロジック

- [x] GridDisplay.gd - グリッド表示システム ✅
  - [x] Hexグリッドの視覚化
  - [x] GridManagerとの連携

## Phase 4: シーン構成&統合
- [x] MainScene.tscn - メインゲームシーン ✅
  - [x] UI要素配置
  - [x] カメラ設定
  - [x] ゲームオブジェクト配置

## 移植完了 🎉
- [x] 全70テストが成功
- [x] TDD ワークフローによる開発完了
- [x] Unity HexFRVR → Godot 移植成功