# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Hexグリッドの自動化ゲーム×パズルゲームをGodotで実装します。

## 開発環境

**エンジン**: Godot 4.x
**プラットフォーム**: クロスプラットフォームゲーム開発

## 開発ワークフロー

### TDD（テスト駆動開発）に従った開発

**重要**t-wada と Kent Beck の TDD ワークフローを採用します：

1. 網羅したいテストシナリオのリスト（todo.md）を書く
2. テストリストの中から「ひとつだけ」選び出し、実際に、具体的で、実行可能なテストコードに翻訳し、テストが失敗することを確認する
3. プロダクトコードを変更し、いま書いたテスト（と、それまでに書いたすべてのテスト）を成功させる（その過程で気づいたことはテストリストに追加する）
4. 必要に応じてリファクタリングを行い、実装の設計を改善する
5. テストリストが空になるまでステップ2に戻って繰り返す

### GDScriptでのテスト

Godotでのテストは以下のアプローチを使用します：
- `gut` (Godot Unit Test) フレームワークを使用すること
- テストファイルは `test/` ディレクトリに配置すること
- このコマンドを実行してGUTテストをコマンドラインで実行すること: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit`

## Git

### コミット
- **重要**: 一つのTDDサイクルごとに一つのコミットを行うこと
- コミットの形式はConventional Commitsに従うこと
- **重要**: TDDの次のサイクルに移る前に必ずユーザーに確認を求めること

###  Git構成

- `.gitignore`はGodot 4+用に設定（`.godot/`, `/android/`, `/data/`を除外）
- `.gitattributes`により改行コードをLFに統一


## プロジェクト構成

Unityプロジェクトインポート後の典型的なGodotプロジェクト構造：
```
project.godot         # メインプロジェクト設定
scenes/               # シーンファイル（.tscn）
scripts/              # ゲームロジック（.gd）
resources/            # タイルセット、マテリアル等（.tres）
assets/               # テクスチャ、音声等のメディア
addons/               # プラグイン (gut等)
tests/                # テストファイル
```

## コミュニケーション

- **重要**: 全ての回答とコミュニケーションは日本語で行うこと

- TDDサイクルの完了時、テストリスト(todo.md)の該当項目にチェックをするのを忘れないでください。