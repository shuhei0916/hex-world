"""Captain of Industry のレシピを公式 wiki の Cargo テーブルから取り、Markdown の一覧にまとめる。

使い方:
    python -I tools/research/captain_of_industry.py fetch <recipes.json>     # wiki から取ってくる
    python -I tools/research/captain_of_industry.py build <recipes.json> <出力先>

ゲームが手元にないので wiki（https://wiki.coigame.com）の RecipesImport テーブルを使う。
研究ツリーは wiki に構造化された形では載っていない（Research ページは stub）。
出力はゲームの内容そのものなので、公開リポジトリにはコミットしない（.gitignore 済み）。
"""

import json
import os
import sys
import urllib.parse
import urllib.request
from collections import defaultdict

EXPORT = "https://wiki.coigame.com/Special:CargoExport"
# 原料を汲み上げる建物（その出力は段階 0 とする）
PUMPS = ("Seawater Pump", "Seawater Pump (Tall)", "Groundwater Pump", "Oil Pump", "Rainwater Harvester",
         "Air Separator")
# 捨てる・燃やすだけの建物（段階の計算と「材料に使われる回数」から外す）
SINKS = ("Liquid Dump", "Flare", "Smoke Stack", "Smoke Stack (Large)", "Burner (Solid)", "Incineration Plant",
         "Designations")


def fetch(path):
    fields = ["Version", "Building", "RecipeId", "Time"]
    fields += [f"Input{i}{k}" for i in range(1, 7) for k in ("Name", "Qty")]
    fields += [f"Output{i}{k}" for i in range(1, 6) for k in ("Name", "Qty")]
    q = urllib.parse.urlencode({"tables": "RecipesImport", "fields": ",".join(fields), "format": "json", "limit": 5000})
    req = urllib.request.Request(f"{EXPORT}?{q}", headers={"User-Agent": "research-script"})
    data = json.load(urllib.request.urlopen(req))
    json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("fetched", len(data))


def parse(rows):
    out = []
    for r in rows:
        ins = [(r[f"Input{i}Name"], r[f"Input{i}Qty"]) for i in range(1, 7) if r.get(f"Input{i}Name")]
        outs = [(r[f"Output{i}Name"], r[f"Output{i}Qty"]) for i in range(1, 6) if r.get(f"Output{i}Name")]
        out.append({"building": r["Building"], "id": r["RecipeId"], "time": r["Time"] or 0, "in": ins, "out": outs,
                    "version": r["Version"]})
    return out


def cell(x):
    return str(x).replace("\n", " ").replace("|", "/")


def stack(lst):
    return " + ".join(f"{q:g}×{n}" for n, q in lst) or "—"


def tiers(recipes):
    producers = defaultdict(list)
    names = set()
    for r in recipes:
        if r["building"] in SINKS:
            continue
        for n, _ in r["in"] + r["out"]:
            names.add(n)
        for n, _ in r["out"]:
            producers[n].append(r)
    raw = {n for r in recipes if r["building"] in PUMPS for n, _ in r["out"]}
    tier = {n: 0 for n in names if n in raw or not producers.get(n)}
    changed = True
    while changed:
        changed = False
        for n in names:
            if n in raw:
                continue
            best = None
            for r in producers.get(n, []):
                ins = [tier.get(x) for x, _ in r["in"]]
                if any(t is None for t in ins):
                    continue
                t = 1 + max(ins, default=-1)
                best = t if best is None else min(best, t)
            if best is not None and (n not in tier or best < tier[n]):
                tier[n] = best
                changed = True
    return tier, producers


def build(path, out):
    recipes = parse(json.load(open(path, encoding="utf-8")))
    tier, producers = tiers(recipes)
    os.makedirs(out, exist_ok=True)
    version = recipes[0]["version"] if recipes else "?"

    by_b = defaultdict(list)
    for r in recipes:
        by_b[r["building"]].append(r)
    lines = [f"# Captain of Industry レシピ一覧（建物ごと、wiki のデータ v{version}）", "",
             "時間は秒。毎分 = 60 / 時間 × 最初の出力の量。", ""]
    for b in sorted(by_b, key=lambda b: (min(tier.get(o[0], 99) for r in by_b[b] for o in r["out"] or [("", 0)]), b)):
        lines += [f"## {b}（{len(by_b[b])} 件）", "", "| 入力 | 出力 | 時間 | 出力/分 |", "|---|---|---|---|"]
        for r in by_b[b]:
            pm = 60 / r["time"] * r["out"][0][1] if r["time"] and r["out"] else 0
            lines.append(f"| {cell(stack(r['in']))} | {cell(stack(r['out']))} | {r['time']:g}s | {pm:.2f} |")
        lines.append("")
    open(os.path.join(out, "recipes.md"), "w", encoding="utf-8").write("\n".join(lines))

    rows = defaultdict(list)
    for n, t in tier.items():
        rows[t].append((n, "・".join(sorted({r["building"] for r in producers.get(n, [])})) or "— (採掘・汲み上げなど)"))
    lines = ["# Captain of Industry 素材一覧", "", "段階 = 採掘・汲み上げを 0 とした加工の深さ（一番浅い作り方で数える）。", ""]
    for t in sorted(rows):
        lines += [f"## 段階 {t}（{len(rows[t])} 件）", "", "| 名前 | 作る建物 |", "|---|---|"]
        lines += [f"| {cell(n)} | {cell(w)} |" for n, w in sorted(rows[t])]
        lines.append("")
    unreached = sorted(n for r in recipes for n, _ in r["out"] if n not in tier and r["building"] not in SINKS)
    if unreached:
        lines += ["## 段階 ?（循環の中にしかないもの）", "", "・".join(dict.fromkeys(unreached)), ""]
    open(os.path.join(out, "items.md"), "w", encoding="utf-8").write("\n".join(lines))

    real = [r for r in recipes if r["building"] not in SINKS]
    n_in, fan_in = defaultdict(int), defaultdict(int)
    for r in real:
        n_in[len(r["in"])] += 1
        for n, _ in r["in"]:
            fan_in[n] += 1
    tc = defaultdict(int)
    for t in tier.values():
        tc[t] += 1
    lines = ["# Captain of Industry 数字で見る構造", "",
             f"- レシピ {len(recipes)} 件（捨てる・燃やすだけのものを除くと {len(real)} 件）、建物 {len(by_b)} 種、素材 {len(tier)} 件", "",
             "## 段階ごとの件数", "", "| 段階 | 件数 |", "|---|---|"]
    lines += [f"| {t} | {tc[t]} |" for t in sorted(tc)]
    lines += ["", "## レシピの入力の種類数", "", "| 入力の種類 | レシピ数 |", "|---|---|"]
    lines += [f"| {k} | {n_in[k]} |" for k in sorted(n_in)]
    lines += ["", "## よく材料に使われる素材（上位20）", "", "| 素材 | 段階 | 使われるレシピ数 |", "|---|---|---|"]
    lines += [f"| {n} | {tier.get(n, '?')} | {c} |" for n, c in sorted(fan_in.items(), key=lambda x: -x[1])[:20]]
    lines += ["", "## 同じ機能の上位版（名前に II〜V が付く建物）", ""]
    fam = defaultdict(list)
    for b in by_b:
        base = b.rsplit(" ", 1)[0] if b.rsplit(" ", 1)[-1] in ("II", "III", "IV", "V", "I") else None
        if base:
            fam[base].append(b)
    lines += [f"- {base}: " + "・".join(sorted(v)) for base, v in sorted(fam.items())]
    open(os.path.join(out, "stats.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("wrote", sorted(os.listdir(out)))


if __name__ == "__main__":
    if sys.argv[1] == "fetch":
        fetch(sys.argv[2])
    else:
        build(sys.argv[2], sys.argv[3])
