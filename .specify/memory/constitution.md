<!-- Sync Impact Report
Version change: 1.0.0 -> 1.1.0
Modified principles: Renamed/Clarified V (Japanese Language First) to reflect GEMINI.md specifics.
Added sections: TDD Workflow Details (within Core Principles)
Removed sections: None
Templates requiring updates: None
Follow-up TODOs: None
-->

# hex-world Constitution

## Core Principles

### I. Godot Engine & GDScript Native (GodotエンジンとGDScriptのネイティブ活用)
プロジェクトはGodot 4.xエンジンを基盤とし、主要なロジックはGDScriptで記述する。エンジンのノードシステム、シグナル、シーン構造を最大限に活用し、Godotの流儀（The Godot Way）に従うこと。外部ライブラリよりもエンジンの標準機能を優先する。

### II. Strict Test-Driven Development (厳格なテスト駆動開発)
本プロジェクトでは **必ずTDD（テスト駆動開発）** に従って開発を行う。AIエージェントは各ステップを順番に実行し、省略・飛ばしをしてはならない。
1. **テストリストを作成する**: `todo.md` に網羅的にリストアップ。
2. **🔴 Red**: ひとつだけテストを書き、失敗を確認する（1テスト1アサーション原則）。
3. **🟢 Green**: プロダクトコードを修正し、テストを成功させる。
4. **🔵 Refactor**: 実装の設計を改善する。
5. **繰り返す**: テストリストが空になるまで繰り返す。

### III. Automation & Puzzle Mechanics (自動化とパズルメカニクス)
「shapez2の六角形版」として、リソースの採掘、加工、輸送の自動化をパズル要素として提供する。システムはモジュール化され、拡張可能でなければならない。

### IV. Japanese Language First (日本語第一主義)
回答は思考も含め、すべて日本語で行う。プロジェクトのドキュメント、コードコメント、およびAIエージェントとの対話は原則として日本語で行う。

## Technical Constraints (技術的制約)

- **Engine**: Godot 4.x (Stable)
- **Language**: GDScript 2.0
- **Platform**: Cross-platform (Windows/Mac/Linux/Web)
- **Version Control**: Git
- **Testing**: GUT (Godot Unit Test) framework
  - テストファイルは `tests/` ディレクトリに配置。
  - 実行コマンド: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit`

## Development Workflow (開発ワークフロー)

1. **Task Definition**: `todo.md` でタスクとテストリストを定義。
2. **TDD Cycle**: Red -> Green -> Refactor を1サイクルとし、**必ず1サイクルごとにユーザーの確認を受けてからコミットし、次へ進む**。
3. **Atomic Commit**: 1サイクルにつき1コミットを原則とする。

## Governance

本憲法はプロジェクトの最高規則であり、他のすべての慣習に優先する。
変更には明確な理由とドキュメント化が必要である。
すべてのAIエージェントは本憲法に従い、日本語で応答し、TDDを遵守しなければならない。

**Version**: 1.1.0 | **Ratified**: 2025-12-05 | **Last Amended**: 2025-12-05
