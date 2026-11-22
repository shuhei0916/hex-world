"""Mindustry のコンテンツ（MindustryDump.java の出力）から、アイテム・レシピ・ブロック・研究ツリーを Markdown にまとめる。

使い方:
    javac -cp "<Mindustry>/jre/desktop.jar" -d <classes> tools/research/MindustryDump.java
    java -cp "<Mindustry>/jre/desktop.jar;<classes>" MindustryDump mindustry.json
    python -I tools/research/mindustry.py mindustry.json "<Mindustry>/jre/desktop.jar" <出力先>

日本語名は desktop.jar の bundles/bundle_ja.properties から読む。
出力はゲームの内容そのものなので、公開リポジトリにはコミットしない（.gitignore 済み）。
"""

import json
import os
import re
import sys
import zipfile
from collections import defaultdict

PLANET_JA = {"serpulo": "セルプロ", "erekir": "エレキル"}
TYPE_PREFIX = {"block": "block", "item": "item", "liquid": "liquid", "unit": "unit", "sector": "sector"}


def load_bundle(jar, name):
    out = {}
    text = zipfile.ZipFile(jar).read(f"bundles/{name}").decode("utf-8")
    for line in text.splitlines():
        if "=" in line and not line.lstrip().startswith("#"):
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip()
    return out


def cell(x):
    return str(x).replace("\n", " ").replace("|", "/")


class Data:
    def __init__(self, dump, en, ja):
        self.d, self.en, self.ja = dump, en, ja
        self.blocks = {b["name"]: b for b in dump["blocks"]}
        self.crafters = [b for b in dump["blocks"] if "craftTime" in b and (b["outItems"] or b["outLiquids"])]
        self.producers = defaultdict(list)
        for b in self.crafters:
            for n, _ in b["outItems"] + b["outLiquids"]:
                self.producers[n].append(b)
        self.tiers = self._tiers()

    def name(self, key, kind=None):
        kinds = [kind] if kind else ["item", "liquid", "block", "unit", "sector"]
        for k in kinds:
            e = self.en.get(f"{k}.{key}.name")
            if e:
                j = self.ja.get(f"{k}.{key}.name", "")
                return f"{e}（{j}）" if j and j != e else e
        return key

    def short(self, key, kind=None):
        n = self.name(key, kind)
        return n.split("（")[-1].rstrip("）") if "（" in n else n

    def stack(self, lst):
        return " + ".join(f"{a:g}×{self.short(n)}" for n, a in lst) or "—"

    def _tiers(self):
        names = [i["name"] for i in self.d["items"]] + [l["name"] for l in self.d["liquids"]]
        raw = set(self.d.get("raw", []))
        tier = {n: 0 for n in names if n in raw or not self.producers.get(n)}
        changed = True
        while changed:
            changed = False
            for n in names:
                if n in raw:
                    continue
                best = None
                for b in self.producers.get(n, []):
                    ins = [tier.get(x) for x, _ in b["inItems"] + b["inLiquids"]]
                    if any(t is None for t in ins):
                        continue
                    t = 1 + max(ins, default=-1)
                    best = t if best is None else min(best, t)
                if best is not None and (n not in tier or best < tier[n]):
                    tier[n] = best
                    changed = True
        return tier


def write_recipes(d, out):
    lines = ["# Mindustry 加工ブロックのレシピ", "",
             "時間は秒（ゲーム内の tick / 60）。液体の量は 1 tick あたり。毎分 = 60 / 時間 × 最初の出力の量。", "",
             "| ブロック | サイズ | 入力 | 入力の液体 | 電力/秒 | 出力 | 出力の液体 | 時間 | 出力/分 |",
             "|---|---|---|---|---|---|---|---|---|"]
    for b in sorted(d.crafters, key=lambda b: (d.tiers.get((b["outItems"] or b["outLiquids"])[0][0], 99), b["name"])):
        t = b["craftTime"] / 60
        per_min = 60 / t * b["outItems"][0][1] if b["outItems"] and t else 0
        cells = [d.name(b["name"], "block"), b["size"], d.stack(b["inItems"]), d.stack(b["inLiquids"]),
                 round(b["power"] * 60, 2), d.stack(b["outItems"]), d.stack(b["outLiquids"]), f"{t:g}s",
                 f"{per_min:.2f}"]
        lines.append("| " + " | ".join(cell(x) for x in cells) + " |")
    open(os.path.join(out, "recipes.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def write_items(d, out):
    lines = ["# Mindustry アイテム・液体", "", "段階 = 原料（採掘・汲み上げ）を 0 とした加工の深さ。", "",
             "| 段階 | 名前 | 種類 | 硬さ | 作るブロック |", "|---|---|---|---|---|"]
    rows = [(i["name"], "アイテム", i["hardness"]) for i in d.d["items"]] + \
           [(l["name"], "気体" if l["gas"] else "液体", "") for l in d.d["liquids"]]
    for n, kind, hard in sorted(rows, key=lambda r: (d.tiers.get(r[0], 99), r[0])):
        where = "・".join(d.short(b["name"], "block") for b in d.producers.get(n, []))
        lines.append("| " + " | ".join(cell(x) for x in [d.tiers.get(n, "?"), d.name(n), kind, hard, where or "—"]) + " |")
    open(os.path.join(out, "items.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def write_buildings(d, out):
    by_cat = defaultdict(list)
    for b in d.d["blocks"]:
        if b["visible"]:
            by_cat[b["category"]].append(b)
    lines = ["# Mindustry ブロック（建設メニューのカテゴリごと）", "",
             "env は動く環境（1 = 地上、Serpulo。Erekir 専用のブロックは別の値）。", ""]
    for cat in sorted(by_cat):
        lines += [f"## {cat}（{len(by_cat[cat])} 件）", "", "| 名前 | サイズ | 建設コスト | 電力/秒 | env |", "|---|---|---|---|---|"]
        for b in by_cat[cat]:
            lines.append("| " + " | ".join(cell(x) for x in [d.name(b["name"], "block"), b["size"], d.stack(b["requirements"]),
                                                             round(b["power"] * 60, 2) or "", b["env"]]) + " |")
        lines.append("")
    open(os.path.join(out, "buildings.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_research(d, out):
    lines = ["# Mindustry 研究ツリー", "",
             "ゲーム内の TechTree から書き出したもの。研究コストはコアに貯めた資源で払う。"
             "条件 = 前提の研究以外に必要なこと（セクターの攻略・アイテムの生産など）。", ""]
    stats = []
    for tree in d.d["tech"]:
        nodes = tree["nodes"]
        parent = {n["name"]: n["parent"] for n in nodes}
        depth = {}

        def depth_of(k):
            if k not in depth:
                p = parent.get(k)
                depth[k] = 0 if p is None else 1 + depth_of(p)
            return depth[k]

        kinds = defaultdict(int)
        for n in nodes:
            kinds[n["type"]] += 1
        stats.append((tree["root"], len(nodes), max(depth_of(n["name"]) for n in nodes), dict(kinds)))
        lines += [f"## {PLANET_JA.get(tree['root'], tree['root'])}（{len(nodes)} ノード）", "",
                  "| 深さ | 種類 | 研究 | 親 | コスト | 条件 |", "|---|---|---|---|---|---|"]
        for n in nodes:  # 木を深さ優先でたどった順のまま
            conds = []
            for o in n["objectives"]:
                kind, _, rest = o.partition(":")
                target = rest.split(": ", 1)[-1].strip()
                if kind == "Research":
                    if target == n["parent"] or target == d.short(n["parent"] or ""):
                        continue
                    conds.append("研究: " + d.short(target))
                elif kind == "SectorComplete":
                    conds.append("攻略: " + d.short(target, "sector"))
                elif kind == "OnSector":
                    conds.append("到達: " + d.short(target, "sector"))
                elif kind == "Produce":
                    conds.append("生産: " + d.short(target))
                else:
                    conds.append(rest)
            cells = [depth_of(n["name"]), n["type"], d.name(n["name"], TYPE_PREFIX.get(n["type"])),
                     d.short(n["parent"]) if n["parent"] else "—", d.stack(n["req"]), "・".join(conds)]
            lines.append("| " + " | ".join(cell(x) for x in cells) + " |")
        lines.append("")
    open(os.path.join(out, "research.md"), "w", encoding="utf-8").write("\n".join(lines))
    return stats


def write_stats(d, out, tree_stats):
    tier_count = defaultdict(int)
    for n, t in d.tiers.items():
        tier_count[t] += 1
    n_in, fan_in = defaultdict(int), defaultdict(int)
    for b in d.crafters:
        ins = b["inItems"] + b["inLiquids"]
        n_in[len(ins)] += 1
        for x, _ in ins:
            fan_in[x] += 1
    cost_use = defaultdict(int)  # 建設コストに使われる回数
    for b in d.d["blocks"]:
        for n, _ in b["requirements"]:
            cost_use[n] += 1
    lines = ["# Mindustry 数字で見る構造", "",
             f"- アイテム {len(d.d['items'])}・液体 {len(d.d['liquids'])}・加工ブロック {len(d.crafters)}・ブロック {len(d.d['blocks'])}", "",
             "## 研究ツリー", "", "| 惑星 | ノード数 | 最大の深さ | 内訳 |", "|---|---|---|---|"]
    lines += [f"| {PLANET_JA.get(r, r)} | {n} | {dep} | {k} |" for r, n, dep, k in tree_stats]
    lines += ["", "## 段階ごとの件数（アイテム・液体）", "", "| 段階 | 件数 |", "|---|---|"]
    lines += [f"| {t} | {tier_count[t]} |" for t in sorted(tier_count)]
    lines += ["", "## 加工ブロックの入力の種類数", "", "| 入力の種類 | ブロック数 |", "|---|---|"]
    lines += [f"| {k} | {n_in[k]} |" for k in sorted(n_in)]
    lines += ["", "## 建設コストに使われる回数（アイテムの主な使い道）", "", "| アイテム | 段階 | 加工の材料 | 建設コスト |", "|---|---|---|---|"]
    lines += [f"| {d.name(n)} | {d.tiers.get(n, '?')} | {fan_in[n]} | {c} |"
              for n, c in sorted(cost_use.items(), key=lambda x: -x[1])]
    open(os.path.join(out, "stats.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def main(dump, jar, out):
    d = Data(json.load(open(dump, encoding="utf-8")), load_bundle(jar, "bundle.properties"),
             load_bundle(jar, "bundle_ja.properties"))
    os.makedirs(out, exist_ok=True)
    write_items(d, out)
    write_recipes(d, out)
    write_buildings(d, out)
    stats = write_research(d, out)
    write_stats(d, out, stats)
    print("wrote", sorted(os.listdir(out)))


if __name__ == "__main__":
    main(*sys.argv[1:4])
