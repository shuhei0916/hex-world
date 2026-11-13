---
name: godot-run
description: hex-world の Godot をヘッドレスで動かす手順。GUT テストの実行（全体・ファイル指定・テスト名指定）と、シーンを起動して入力（キー・マウス・メソッド呼び出し）を流したあとのシーンツリーをテキストで取得する動作確認に使う。テストを回すとき、実装後に実際のゲームで動くか確かめたいとき、ノード配置・表示状態・色を確認したいときに使う。
---

# godot-run

Godot はすべて **ヘッドレス** で実行する（ウィンドウを開かない）。スクリーンショットは撮らない。
スクリプトはどれも Bash で、プロジェクトルートを自動で解決するのでどこから実行してもよい。

## Godot の場所

`scripts/find_godot.sh` が以下の順で探す。環境ごとにパスが違うため、パスを直書きしないこと。

1. 環境変数 `GODOT`
2. PATH 上の `godot` / `godot4`
3. よくある設置場所（`C:\Tools\Godot*` など。Windows ではコンソール版 `*_console.exe` を優先）

見つからない場合は推測で探し回らず、ユーザーに `GODOT` の設定を依頼する。

## テスト実行

```bash
.claude/skills/godot-run/scripts/run_tests.sh                          # 全テスト
.claude/skills/godot-run/scripts/run_tests.sh -gselect=test_world.gd   # ファイル指定
.claude/skills/godot-run/scripts/run_tests.sh -gunit_test_name=ホバー   # テスト名の部分一致
```

- 事前に `--import` を実行するので、新規 `class_name` を追加した直後でも正しく解決される。
- 出力の末尾の `Run Summary`（Tests / Passing Tests）と `All tests passed!` を確認する。
  出力が長いので `| tail -20` で要約だけ見て、失敗時に `| grep -B2 -A10 "\[Failed\]"` で詳細を見るとよい。
- Red の確認では「失敗したこと」だけでなく **失敗理由のメッセージ** が意図どおりかを確認する。

## 動作確認（シーンツリーの取得）

TDD で検証しづらい「実際のゲームに組み込んだときの状態」を確認する。

```bash
.claude/skills/godot-run/scripts/dump_tree.sh [options]
```

| option | 意味 |
|---|---|
| `--scene=res://...` | 起動するシーン（既定: main_scene） |
| `--do=<steps>` | `;` 区切りの入力シナリオ（下表） |
| `--root=<NodePath>` | 出力するサブツリーの起点（シーンルートからの相対） |
| `--depth=<n>` | 出力する最大深さ |
| `--props=a,b` | 追加で出すプロパティ（持っているノードのみ表示） |
| `--frames=<n>` | シナリオ開始前に待つフレーム数（既定 2） |

| step | 動作 |
|---|---|
| `key:SPACE` | キーを押して離す（`F2`, `T`, `ESCAPE` など） |
| `action:rotate_piece` | InputMap のアクション |
| `move:400,300` / `click:400,300` / `rclick:400,300` | ビューポート座標でマウス操作 |
| `moveto:<NodePath>` / `clickon:<NodePath>` | ノードの画面位置へマウス移動 / 左クリック（カメラ変換込み） |
| `wait:10` | フレーム待機 |
| `call:World/get_active_hex` | メソッドを呼んで戻り値を表示（引数なしのみ） |
| `script:res://tools/scenarios/x.gd` | シナリオの `run(scene)` を実行（await 可）。ピース配置や複数フレームの観察など、ステップで書けない操作に使う |

各ノードは `名前 (class_name:組み込みクラス)` と、既定値から変わったものだけ
（`pos` / `rot` / `scale` / `rect` / `text` / `HIDDEN` / `modulate` / `z` / `color`）を表示する。

### 例

```bash
# まず全体の構成を浅く見る
dump_tree.sh --depth=2

# ワールドマップに切り替えてタイルをホバー → 状態を確認
dump_tree.sh "--do=key:SPACE;moveto:WorldMapView/@Node2D@371" \
  --root=WorldMapView --depth=1 --props=is_active,is_hovered,chunk_hex

# クリックでチャンク移動できるか
dump_tree.sh "--do=key:SPACE;clickon:WorldMapView/@Node2D@371;call:World/get_active_hex" --depth=1
```

### シナリオ
`tools/scenarios/` に `extends RefCounted` で `func run(scene: Node) -> void` を持つスクリプトを置く。
`scene` はメインシーン（`scene.world` などで子へアクセスできる）。観察結果は `print` で出力する。

- `conveyor_branch_flow.gd`: 分岐コンベアにアイテムを流し続け、分岐元のアイコン位置を毎フレーム追う（飛び移り・アイコン同士の重なりを検出）
- `conveyor_spacing.gd`: 分岐を含むラインを詰まらせ、レーンごとのアイテム間隔（ヘックス間距離=1.0）を出力する
- `planet_overview.gd`: planet のバイオーム分布を文字で描き、ワールドマップのホバー表示と未生成 chunk への入場（遅延生成・鉱床）を出力する
- `biome_production.gd`: 山岳・森林 chunk の鉱床に Miner を置いて新資源の採掘を確かめ、銅インゴット・鋼材が実際の tick で加工されるかを出力する（約9秒待つ）

```bash
dump_tree.sh "--do=script:res://tools/scenarios/conveyor_branch_flow.gd" --depth=0
```

### 注意

- 動的に生成したノードは `@Node2D@371` のような自動名になる。番号は構成が変わるとずれるので、
  一度 `--depth` 付きで出力して名前を確かめてから `moveto:` / `clickon:` に使う。
- ヘッドレスでは描画されない。`_draw()` の実際の見た目やピクセル単位の隙間は確認できない。
  そうした確認が必要な場合はユーザーに伝えて方法を相談する。
- ツール本体は `res://tools/dump_scene_tree.gd`。足りない機能はそちらに追加する。
