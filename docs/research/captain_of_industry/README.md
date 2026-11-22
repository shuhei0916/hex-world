# Captain of Industry 調査メモ

`generated/` に wiki のデータから作った一覧がある（git には入れない）。

```
python -I tools/research/captain_of_industry.py fetch recipes.json
python -I tools/research/captain_of_industry.py build recipes.json docs/research/captain_of_industry/generated
```

## 情報源

- ゲームが手元にないので、公式 wiki（https://wiki.coigame.com）の Cargo テーブル `RecipesImport` を使った。
  - ゲーム v0.8.1 のレシピ 640 件。
- **取れていないもの**
  - 研究ツリー。wiki の Research ページは stub で、ノードの一覧がない。
  - ゲームを入れれば、有志の抜き出し用 Mod（CLExporter）で取れる可能性がある。
  - 繰り返し研究（汚染減少・作物収量など）の式だけは Research ページにある。

## 一覧表（generated/）

| ファイル | 中身 |
|---|---|
| `items.md` | 素材 217 件を加工の段階ごとに |
| `recipes.md` | 建物 112 種のレシピ |
| `stats.md` | 段階・入力数・材料の使われ方・上位版の建物 |

## データから読み取れる構造

### 1. 5 本の中で一番深い

- 加工の段階は最大 22。段階 0〜8 は 13〜36 件ずつと厚く、9 段目から上はほぼ 1 件ずつの一本道になる。
- レシピ 640 件、建物 112 種と、規模も一番大きい。

### 2. 副産物と水が鎖をつなぐ

- 水は 180 のレシピで材料になり、2 位の鋼材（42）を大きく引き離している。
- 捨てる・燃やすだけの建物（排液・フレア・煙突・焼却など）に 47 件のレシピがある。
  - 副産物と汚染の処理が、生産と同じ重さで扱われている。

### 3. 同じ機能の建物に I〜V の上位版がある

- 組立機 I〜V、研究所 I〜IV、コンクリートミキサー I〜III など。
- 上位版で使えるレシピが増え、研究所は消費する「研究用具」も I〜IV と段が上がる（Factorio のサイエンスパックに近い）。
