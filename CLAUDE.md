# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

このGodotゲームプロジェクトは、Unity から Godot への移植準備のため最近クリアされました。以前は六角形タイルベースのhex-worldプロジェクトでしたが、より完成されたUnityゲームをインポートするために全ファイルが削除されています。

## 開発環境

**エンジン**: Godot 4.x
**プラットフォーム**: クロスプラットフォームゲーム開発

## 開発ワークフロー

### TDD（テスト駆動開発）に従った開発

t-wada と Kent Beck の TDD ワークフローを採用します：

1. **Red**: 失敗するテストを最初に書く
2. **Green**: テストが通る最小限のコードを書く  
3. **Refactor**: コードを改善しながらテストは通し続ける

### GDScriptでのテスト

Godotでのテストは以下のアプローチを使用：
- `gut` (Godot Unit Test) フレームワークを使用
- テストファイルは `test/` ディレクトリに配置
- テスト実行: `godot --headless --script addons/gut/gut_cmdln.gd`

## Git構成

- `.gitignore`はGodot 4+用に設定（`.godot/`, `/android/`, `/data/`を除外）
- `.gitattributes`により改行コードをLFに統一

## プロジェクトの現状

リポジトリは現在空で、Unityプロジェクト資産の移行準備完了。作業時の注意：

1. **新規プロジェクト設定**: Unity資産インポート時に新しい`project.godot`ファイルの作成が必要
2. **資産移行**: Unity資産をGodot互換形式（.tscn, .gd, .tres）に変換が必要
3. **六角形ゲームシステム**: Gitリストからこのプロジェクトは六角形タイルベースのゲームプレイ機構に重点

## 移行後の想定構造

Unityプロジェクトインポート後の典型的なGodotプロジェクト構造：
```
project.godot          # メインプロジェクト設定
scenes/               # シーンファイル（.tscn）
scripts/              # ゲームロジック（.gd）
resources/            # タイルセット、マテリアル等（.tres）
assets/               # テクスチャ、音声等のメディア
test/                 # テストファイル
```

## コミュニケーション

**重要**: 全ての回答とコミュニケーションは日本語で行うこと。