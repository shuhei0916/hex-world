---
name: godot-run
description: hex-world の Godot をヘッドレスで動かす手順。GUT テストの実行（全体・ファイル指定・テスト名指定）と、シーンを起動して入力（キー・マウス・メソッド呼び出し）を流したあとのシーンツリーをテキストで取得する動作確認に使う。テストを回すとき、実装後に実際のゲームで動くか確かめたいとき、ノード配置・表示状態・色を確認したいときに使う。
---

# godot-run

Godot は原則 **ヘッドレス** で実行する（ウィンドウを開かない）。描画の見た目（重なり順・色・はみ出し）の確認が必要なときだけ、後述の `screenshot.sh` で撮影する。
スクリーンショットは必ず `screenshot.sh` でとること。ゲームを普通に起動して撮ってはならない（ウィンドウが前面に出て、ユーザーの作業の邪魔になる）。
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
- `conveyor_from_smelter.gd`: Smelter の排出口からドラッグで斜めに曲がるコンベアを引き、ベルトの入力方向と、排出口のないマスの隣のコンベアに Smelter がつながらないことを出力する
- `conveyor_branch_from_side.gd`: Miner の排出口の前のベルト（NE から受けて SE へ流す）から東へドラッグで分岐を引き、分岐元の状態を出力する。screenshot.sh で撮ると分岐元を拡大して映す（環境変数 `BRANCH_ZOOM` で倍率）。隣の辺へ折り返す分岐の角が尖って突き出ないかの確認用
- `conveyor_from_miner.gd`: 別のラインが真後ろを通る場所で Miner の排出口からコンベアを引き、先頭のベルトの入力方向と、通りすがりのラインが分岐してこないことを出力する
- `conveyor_auto_orient.gd`: shapez 風の向きの自動調整をクリック操作で確かめる（Miner の排出口の前に置くと曲がる・行き止まりのベルトが横の新しいベルトへ曲がる・入力のないベルトが横の相手から受ける）
- `planet_overview.gd`: planet のバイオーム分布を文字で描き、ワールドマップのホバー表示と未生成 chunk への入場（遅延生成・鉱床）を出力する
- `limestone_kiln.gd`: 窯のスロットが Lv7 の報酬で開くこと、石灰岩の台地の chunk で石灰石が掘れること、窯で生石灰・混合機でコンクリートが実際の tick で作られることを出力する（約9秒待つ）
- `biome_production.gd`: 山岳・森林 chunk の鉱床に Miner を置いて新資源の採掘を確かめ、銅インゴット・鋼材が実際の tick で加工されるかを出力する（約9秒待つ）

- `build_cost.gd`: 在庫不足で置けない → ハブに納品 → 設置で在庫が減る → 撤去で全額戻る、の流れを出力する
- `research_flow.gd`: ハブに納品してレベルを上げ、研究ツリーでコンベア高速化を選んで研究し、実際の速さに効くかを出力する
- `visual_research_tree.gd`: 見た目確認用。研究済み・研究できる・在庫不足・未解放が混ざった状態で研究ツリーの画面を開いて映す
- `chunk_chest.gd`: 離れた搬入チェストから搬出チェストへ、コンベア無しでアイテムが渡ってハブに届くかを出力する（搬出側はクリック→選択パネルで選ぶ）
- `planet_chest.gd`: 離れた山岳の chunk の planet 搬入チェストから、原点の chunk の搬出チェスト経由でハブに届くかを出力する
- `biome_chest.gd`: バイオームチェストが同じ地域の chunk からは届き、別の地域の chunk からは届かないことを出力する
- `neighbor_view.gd`: 原点 chunk の辺に橋、隣の chunk の向かいのマスにコンベアを置き、画面上の距離・接続・溝の上の帯・アイテムが渡るか・ホバー情報を出力する
- `visual_layout.gd`: 見た目確認用の配置（Smelter に流し込むコンベアと出ていくコンベア、境界の橋と隣の受け取りコンベア）。カメラを引いて隣の chunk も映す
- `visual_zoom_smelter.gd`: visual_layout の配置で Smelter の周りを拡大する
- `visual_deposit.gd`: 鉱床のマスに Miner を置いて拡大し、地面の種類（鉱床：薄い色とアイコン）と設置物の本体（shapez 風の縁取りした本体）が見分けられるかを映す
- `visual_gap.gd`: 溝の幅の見比べ用。環境変数 `GAP_STEPS`（1〜3）で World.gap_steps を変えて引いて映す
- `visual_belt_seam.gd`: コンベアのつなぎ目（直線どうし・直線と曲がり）を拡大して映す。環境変数 `SEAM_ZOOM` で倍率（既定 5）
- `visual_bridge.gd`: 受け取り先のある橋（アイテムを流し続ける）と無い橋を並べて拡大する
- `visual_map_transfer.gd`: 原点と東隣の間に橋を往復で架けて流し、ワールドマップの輸送のカード（矢印・品目・毎分の個数）を映す。環境変数 `MAP_ZOOM` でカメラの倍率
- `camera_navigation.gd`: 東へ少しずつパンしても今いる chunk が切り替わらない様子と、ホイールで引いてワールドマップへ、寄せてキャラクターのいる chunk のローカル画面へ戻る様子を出力する
- `player_walk.gd`: 実際のキー入力で WASD（斜めも）を押し続け、キャラクターがマスに縛られず自由に動く・chunk の端やハブでふさがれる・カメラが追う、を出力する
- `visual_zoom_transition.gd`: 環境変数 `ZOOM` の倍率まで引いて撮る。Main.LOCAL_TO_MAP_ZOOM の上下で撮ってローカル画面とワールドマップの切り替わりを見比べる
- `placement_feedback.gd`: 実際のマウス入力で、キャラクターの足元に Smelter を置くと施設の端まで押し出されて置け、カメラが追うこと、置いたマスをもう一度クリックするとカーソルの近くに理由が出てエラー音が鳴りゴーストが赤くなることを出力する
- `visual_placement_denied.gd`: 見た目確認用。placement_feedback と同じ操作のあと、カーソルの近くの理由と赤いゴーストを映す
- `toolbar_pointer.gd`: 実際のマウス入力で、ピースを選んだままツールバーへマウスを移すとゴーストが消えること、選んでいるボタンの再クリック・ツールバー上の右クリックで解除され切替パネルも消えることを出力する。ヘッドレスの画面は小さくツールバーが画面外に出るので、**screenshot.sh で動かす**（GUT のテストでマウスで HUD を触るときも、`get_window().size` を一時的に広げる）
- `hover_info.gd`: Miner・Smelter・コンベア・ハブにホバーしたときの情報パネルの内容を出力する
- `chunk_battle.gd`: ワールドマップの霧と、実際の入力で「地図のクリックでは戦わない → 東の辺で渡るキーを押すとその chunk の上で、入ってきたマスから戦闘が始まる → スキルで移動 → 勝ってそのまま建築（キャラクターは戦い終えたマスに立つ）→ 次に渡ろうとして撤退すると元の建築の画面に戻る」の流れを出力する
- `battle_camera.gd`: 戦闘中に実際の入力で中ボタンドラッグ・ホイールを流し、カメラが動くこと・動かしたあともクリックした位置のマスに歩くこと・引いても地図に切り替わらないこと・撤退で戦闘前の建築の画面の見え方に戻ることを出力する
- `visual_chunk_battle.gd`: 見た目確認用。環境変数 `BATTLE_VIEW`（map / battle / intent / result / built）で、霧のある地図・chunk の上の戦闘・敵の予定・勝利の結果・勝ったあとの建築画面を映す
- `visual_player_edge.gd`: 見た目確認用。キャラクターを所有していない隣に面した辺に立たせ、渡るキーの案内を出す
- `visual_reach.gd`: 見た目確認用。Miner を選び、キャラクターから届く範囲の表示と、届かないマスに合わせた赤いゴーストを映す（環境変数 `REACH_VIEW=near` で届くマス）
- `camera_frames.gd`: カメラのかくつき調査用。起動直後・戦闘に勝ったあと・撤退したあとの各フレームで、カメラの位置・倍率・実際に映している中心とキャラクターの位置を出力する（`--frames=0` で起動直後から）
- `save_load.gd`: 工場を組んでセーブし、別の Main を起動して同じ状態に戻るかを出力する
- `export_game_data.gd`: アイテム・レシピ・研究・目標・設置コストを環境変数 `EXPORT_PATH` の JSON に書き出す（集計は `tools/research/hex_world.sh` でまとめて行う）

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
- Windows では見えない別のデスクトップで起動する（`scripts/run_hidden.ps1`）ので、ウィンドウは画面に出ず、フォーカスも奪わない。
- 配色は環境変数 `COLOR_THEME=light` でライト（紙のボードゲーム風）、指定なしでダーク。本物の設定（`user://settings.cfg`）は読まない。
- 解像度は環境変数 `RESOLUTION`（既定 1280x720）。環境変数 `TIMEOUT`（秒、既定 120）を過ぎたら強制終了する。
- 出力（シーンツリーや `print`）はゲームの終了後にまとめて表示される。
- 本物のセーブには触れない（dump_tree.sh と同じく、ツール用のセーブを使う）。

### 注意

- 動的に生成したノードは `@Node2D@371` のような自動名になる。番号は構成が変わるとずれるので、
  一度 `--depth` 付きで出力して名前を確かめてから `moveto:` / `clickon:` に使う。
- ヘッドレスでは描画されない。`_draw()` の実際の見た目やピクセル単位の隙間は screenshot.sh で確認する。
- ツール本体は `res://tools/dump_scene_tree.gd`。足りない機能はそちらに追加する。
