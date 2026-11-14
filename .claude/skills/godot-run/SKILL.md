---
name: godot-run
description: hex-world の Godot をヘッドレスで動かす手順。GUT テストの実行（全体・ファイル指定・テスト名指定）と、シーンを起動して入力（キー・マウス・メソッド呼び出し）を流したあとのシーンツリーをテキストで取得する動作確認に使う。テストを回すとき、実装後に実際のゲームで動くか確かめたいとき、ノード配置・表示状態・色を確認したいときに使う。
---

# godot-run

Godot は原則 **ヘッドレス** で実行する（ウィンドウを開かない）。描画の見た目（重なり順・色・はみ出し）の確認が必要なときだけ、後述の `screenshot.sh` で描画ありで起動して撮影する。
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
| `mdrag:400,300,500,250` | 中ボタンを押したまま 1点目→2点目へドラッグ（カメラのパン確認など） |
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
- `conveyor_merge.gd`: ドラッグで本線の途中へ合流させ、合流先のベルトの入力方向（主入力＋合流）と接続を出力する
- `planet_overview.gd`: planet のバイオーム分布を文字で描き、ワールドマップのホバー表示と未生成 chunk への入場（遅延生成・鉱床）を出力する
- `biome_production.gd`: 山岳・森林 chunk の鉱床に Miner を置いて新資源の採掘を確かめ、銅インゴット・鋼材が実際の tick で加工されるかを出力する（約9秒待つ）

- `build_cost.gd`: 在庫不足で置けない → ハブに納品 → 設置で在庫が減る → 撤去で全額戻る、の流れを出力する
- `research_flow.gd`: ハブに納品してレベルを上げ、研究でピースを解放し、コンベア高速化が実際の速さに効くかを出力する
- `chunk_chest.gd`: 離れた搬入チェストから搬出チェストへ、コンベア無しでアイテムが渡ってハブに届くかを出力する（搬出側はクリック→選択パネルで選ぶ）
- `planet_chest.gd`: 離れた山岳の chunk の planet 搬入チェストから、原点の chunk の搬出チェスト経由でハブに届くかを出力する
- `biome_chest.gd`: バイオームチェストが同じ地域の chunk からは届き、別の地域の chunk からは届かないことを出力する
- `neighbor_view.gd`: 原点 chunk の辺の Sender と隣の chunk の Receiver の画面位置が隣り合うか、隣の施設のホバー情報、隣の chunk に置けないことを出力する
- `visual_layout.gd`: 見た目確認用の配置（Smelter に流し込むコンベアと出ていくコンベア、境界の Sender と隣の Receiver）。カメラを引いて隣の chunk も映す
- `visual_zoom_smelter.gd`: visual_layout の配置で Smelter の周りを拡大する
- `hover_info.gd`: Miner・Smelter・コンベア・ハブにホバーしたときの情報パネルの内容を出力する
- `save_load.gd`: 工場を組んでセーブし、別の Main を起動して同じ状態に戻るかを出力する

動作確認ツールは専用のセーブファイル（`user://tool_session_save.json`）を毎回消してから起動するので、
本物のセーブデータの影響を受けず、常に新しいゲームの状態から始まる。

```bash
dump_tree.sh "--do=script:res://tools/scenarios/conveyor_branch_flow.gd" --depth=0
```

### スクリーンショット（描画の確認）

```bash
.claude/skills/godot-run/scripts/screenshot.sh   "--do=script:res://tools/scenarios/visual_zoom_smelter.gd;shot:<scratchpad の絶対パス>/a.png" --depth=0
```

- 引数は dump_tree.sh と同じで、`shot:<絶対パス.png>` ステップで画面を保存する（Read で画像を見られる）。
- ウィンドウが一瞬開く。解像度は環境変数 `RESOLUTION`（既定 1280x720）。
- 本物のセーブには触れない（dump_tree.sh と同じく、ツール用のセーブを使う）。

### 注意

- 動的に生成したノードは `@Node2D@371` のような自動名になる。番号は構成が変わるとずれるので、
  一度 `--depth` 付きで出力して名前を確かめてから `moveto:` / `clickon:` に使う。
- ヘッドレスでは描画されない。`_draw()` の実際の見た目やピクセル単位の隙間は screenshot.sh で確認する。
- ツール本体は `res://tools/dump_scene_tree.gd`。足りない機能はそちらに追加する。
