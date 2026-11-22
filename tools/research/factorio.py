"""Factorio のプロトタイプ（data.raw）から、アイテム・レシピ・研究を Markdown の一覧にまとめる。

使い方:
    "<Factorio>/bin/x64/factorio.exe" --dump-data      # %APPDATA%/Factorio/script-output/data-raw-dump.json を作る
    python -I tools/research/factorio.py <data-raw-dump.json> "<Factorio のインストール先>" <出力先>

日本語名は data/base/locale/ja/base.cfg から読む。
出力はゲームの内容そのものなので、公開リポジトリにはコミットしない（.gitignore 済み）。
"""

import json
import os
import re
import sys
from collections import defaultdict

ITEM_TYPES = ("item", "ammo", "capsule", "module", "armor", "gun", "repair-tool", "item-with-entity-data",
              "rail-planner", "spidertron-remote", "fluid")
MACHINE_TYPES = ("assembling-machine", "furnace", "rocket-silo")


def load_cfg(path):
    out, sec = {}, ""
    for line in open(path, encoding="utf-8-sig"):
        line = line.rstrip("\n")
        if line.startswith("["):
            sec = line.strip("[]")
        elif "=" in line and not line.startswith(";"):
            k, v = line.split("=", 1)
            out[f"{sec}.{k}"] = v
    return out


def cell(x):
    return str(x).replace("\n", " ").replace("|", "/")


def fmt_time(sec):
    if sec >= 60:
        m, s = divmod(round(sec), 60)
        return f"{m}m{s:02d}s"
    return f"{sec:g}s"


class Data:
    def __init__(self, raw, en, ja):
        self.raw, self.en, self.ja = raw, en, ja
        self.items = {}
        for t in ITEM_TYPES:
            for k, v in raw.get(t, {}).items():
                self.items.setdefault(k, v)
        self.recipes = raw["recipe"]
        self.machines = {k: v for t in MACHINE_TYPES for k, v in raw.get(t, {}).items()}
        self.cat_machines = defaultdict(list)
        for k, m in self.machines.items():
            for c in m.get("crafting_categories", []):
                self.cat_machines[c].append(k)
        self.cat_machines["crafting"].insert(0, "(手作業)")
        self.producers = defaultdict(list)
        for r in self.recipes.values():
            for o in self.results(r):
                self.producers[o["name"]].append(r)
        self.tiers = self._tiers()

    def ings(self, r):
        return r.get("ingredients", [])

    def results(self, r):
        return r.get("results", [])

    def name(self, key, kinds=("item-name", "fluid-name", "entity-name", "equipment-name", "recipe-name",
                               "technology-name")):
        for loc in (self.ja, self.en):
            for k in kinds:
                v = loc.get(f"{k}.{key}")
                if v:
                    break
            else:
                v = None
            if loc is self.ja:
                j = v
            else:
                e = v
        e = e or key
        return f"{e}（{j}）" if j and j != e else e

    def tech_name(self, key):
        base = re.sub(r"-\d+$", "", key)
        n = self.name(key, ("technology-name",))
        if n == key and base != key:  # 段階付きの研究は番号なしの名前を共有する
            n = self.name(base, ("technology-name",)) + " " + key.rsplit("-", 1)[1]
        return n

    def stack(self, lst):
        return " + ".join(f"{x.get('amount', x.get('amount_max', 1)):g}×{self.name(x['name'])}" for x in lst) or "—"

    def _tiers(self):
        raw = {"water"}  # 汲み上げポンプで取る
        for res in self.raw.get("resource", {}).values():
            m = res.get("minable", {})
            raw.add(m.get("result", ""))
            raw.update(x["name"] for x in m.get("results", []))
        tier = {i: 0 for i in self.items if i in raw or not self.producers.get(i)}
        changed = True
        while changed:
            changed = False
            for it in self.items:
                if it in raw:
                    continue
                best = None
                for r in self.producers.get(it, []):
                    if r.get("category") in ("recycling", "parameters") or r.get("parameter") \
                            or r["name"].endswith("-barrel"):  # ドラム缶の充填・排出は循環するので除く
                        continue
                    ins = [tier.get(x["name"]) for x in self.ings(r)]
                    if any(t is None for t in ins):
                        continue
                    t = 1 + max(ins, default=-1)
                    best = t if best is None else min(best, t)
                if best is not None and (it not in tier or best < tier[it]):
                    tier[it] = best
                    changed = True
        return tier

    def real_recipes(self):
        return [r for r in self.recipes.values()
                if not r.get("parameter") and r.get("category") not in ("parameters",) and self.results(r)]


def write_recipes(d, out):
    by_cat = defaultdict(list)
    for r in d.real_recipes():
        by_cat[r.get("category", "crafting")].append(r)
    lines = ["# Factorio レシピ一覧（作る機械の種類ごと）", "",
             "時間は機械の速度 1 のときの秒数。毎分 = 60 / 時間 × 最初の出力の量。", ""]
    for cat in sorted(by_cat):
        ms = "・".join(d.name(m) if m != "(手作業)" else m for m in d.cat_machines.get(cat, []))
        lines += [f"## {cat}（{len(by_cat[cat])} 件）", "", f"作れる機械: {ms or '—'}", "",
                  "| レシピ | 入力 | 出力 | 時間 | 出力/分 | 最初から |", "|---|---|---|---|---|---|"]
        for r in sorted(by_cat[cat], key=lambda r: r.get("energy_required", 0.5)):
            t = r.get("energy_required", 0.5)
            res = d.results(r)
            per_min = 60 / t * res[0].get("amount", res[0].get("amount_max", 1)) if res else 0
            lines.append(f"| {cell(d.name(r['name']))} | {cell(d.stack(d.ings(r)))} | {cell(d.stack(res))} | "
                         f"{fmt_time(t)} | {per_min:.2f} | {'' if r.get('enabled') is False else '○'} |")
        lines.append("")
    open(os.path.join(out, "recipes.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_items(d, out):
    rows = defaultdict(list)
    for k, v in d.items.items():
        if v.get("hidden") or v.get("parameter") or k.startswith("parameter-"):
            continue
        used = any(x["name"] == k for r in d.real_recipes() for x in d.ings(r))
        if not d.producers.get(k) and not used:
            continue
        rows[d.tiers.get(k, "?")].append((d.name(k), v["type"], v.get("stack_size", ""), v.get("subgroup", "")))
    lines = ["# Factorio アイテム一覧", "", "段階 = 原料を 0 とした加工の深さ（一番浅い作り方で数える）。", ""]
    for t in sorted(rows, key=lambda x: (isinstance(x, str), x)):
        lines += [f"## 段階 {t}（{len(rows[t])} 件）", "", "| 名前 | 種類 | スタック | グループ |", "|---|---|---|---|"]
        lines += ["| " + " | ".join(cell(x) for x in r) + " |" for r in sorted(rows[t])]
        lines.append("")
    open(os.path.join(out, "items.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_buildings(d, out):
    lines = ["# Factorio 生産の機械", "",
             "| 名前 | 種類 | 速度 | 電力 | モジュール枠 | 作れるレシピの種類 |", "|---|---|---|---|---|---|"]
    for t in MACHINE_TYPES + ("mining-drill", "lab"):
        for k, m in d.raw.get(t, {}).items():
            if m.get("hidden"):
                continue
            speed = m.get("crafting_speed", m.get("mining_speed", m.get("researching_speed", "")))
            cells = [d.name(k), t, speed, m.get("energy_usage", ""), m.get("module_slots", ""),
                     "・".join(m.get("crafting_categories", m.get("resource_categories", [])))]
            lines.append("| " + " | ".join(cell(x) for x in cells) + " |")
    open(os.path.join(out, "buildings.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def write_research(d, out):
    techs = {k: v for k, v in d.raw["technology"].items() if not v.get("hidden")}
    depth = {}

    def depth_of(k):
        if k not in depth:
            depth[k] = 0
            depth[k] = 1 + max((depth_of(p) for p in techs[k].get("prerequisites", []) if p in techs), default=-1)
        return depth[k]

    def cost(t):
        if "research_trigger" in t:
            tr = t["research_trigger"]
            what = tr.get("item") or tr.get("entity") or tr.get("fluid") or ""
            if isinstance(what, dict):
                what = what.get("name", "")
            return f"きっかけ: {tr['type']} {d.name(what) if what else ''} {tr.get('count', '')}".strip()
        u = t.get("unit", {})
        n = u.get("count", u.get("count_formula", "?"))
        packs = "・".join(d.name(p[0] if isinstance(p, list) else p["name"]).split("（")[-1].rstrip("）")
                          for p in u.get("ingredients", []))
        return f"{n} × [{packs}] × {u.get('time', '?')}s"

    def effects(t):
        rec, other = [], []
        for e in t.get("effects", []):
            if e["type"] == "unlock-recipe":
                rec.append(d.name(e["recipe"]).split("（")[-1].rstrip("）"))
            else:
                other.append(e["type"] + (f" {e['modifier']:+g}" if isinstance(e.get("modifier"), (int, float)) else ""))
        return "・".join(rec), " / ".join(dict.fromkeys(other))

    lines = ["# Factorio 研究ツリー", "",
             f"{len(techs)} 件。深さ = 前提をたどった段数。コストは「回数 × [使うサイエンスパック] × 1回の秒数」。"
             "最初の数件は研究所ではなく、特定の作業をすると解放される（きっかけ）。", ""]
    by_pack = defaultdict(int)
    for t in techs.values():
        by_pack[len(t.get("unit", {}).get("ingredients", []))] += 1
    lines += ["| 使うサイエンスパックの種類数 | 研究数 |", "|---|---|"]
    lines += [f"| {k} | {by_pack[k]} |" for k in sorted(by_pack)]
    lines += ["", "| 深さ | 研究 | 前提 | コスト | 解放するレシピ | その他の効果 |", "|---|---|---|---|---|---|"]
    for k in sorted(techs, key=lambda k: (depth_of(k), k)):
        t = techs[k]
        rec, other = effects(t)
        cells = [depth_of(k), d.tech_name(k), "・".join(d.tech_name(p) for p in t.get("prerequisites", [])) or "—",
                 cost(t), rec, other]
        lines.append("| " + " | ".join(cell(x) for x in cells) + " |")
    open(os.path.join(out, "research.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
    return techs, depth


def write_stats(d, out, techs, depth):
    rs = [r for r in d.real_recipes() if r.get("category") != "recycling"]
    tier_count = defaultdict(int)
    for it, t in d.tiers.items():
        if d.producers.get(it):
            tier_count[t] += 1
    n_in, fan_in = defaultdict(int), defaultdict(int)
    for r in rs:
        n_in[len(d.ings(r))] += 1
        for x in d.ings(r):
            fan_in[x["name"]] += 1
    lines = ["# Factorio 数字で見る構造", "",
             f"- レシピ {len(rs)} 件、研究 {len(techs)} 件（最大の深さ {max(depth.values())}）", "",
             "## 段階ごとのアイテム数（作れるもの）", "", "| 段階 | 件数 |", "|---|---|"]
    lines += [f"| {t} | {tier_count[t]} |" for t in sorted(tier_count)]
    lines += ["", "## レシピの入力の種類数", "", "| 入力の種類 | レシピ数 |", "|---|---|"]
    lines += [f"| {k} | {n_in[k]} |" for k in sorted(n_in)]
    lines += ["", "## よく材料に使われるアイテム（上位20）", "", "| アイテム | 段階 | 使われるレシピ数 |", "|---|---|---|"]
    lines += [f"| {d.name(i)} | {d.tiers.get(i, '?')} | {n} |" for i, n in sorted(fan_in.items(), key=lambda x: -x[1])[:20]]
    lines += ["", "## 研究の深さごとの件数", "", "| 深さ | 件数 |", "|---|---|"]
    per = defaultdict(int)
    for v in depth.values():
        per[v] += 1
    lines += [f"| {k} | {per[k]} |" for k in sorted(per)]
    open(os.path.join(out, "stats.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def main(dump, game_dir, out):
    loc = os.path.join(game_dir, "data", "base", "locale")
    d = Data(json.load(open(dump, encoding="utf-8")), load_cfg(os.path.join(loc, "en", "base.cfg")),
             load_cfg(os.path.join(loc, "ja", "base.cfg")))
    os.makedirs(out, exist_ok=True)
    write_items(d, out)
    write_recipes(d, out)
    write_buildings(d, out)
    techs, depth = write_research(d, out)
    write_stats(d, out, techs, depth)
    print("wrote", sorted(os.listdir(out)))


if __name__ == "__main__":
    main(*sys.argv[1:4])
