"""hex-world のデータを、他の自動化ゲームと同じ形で集計する。

1. ゲームのデータを JSON に書き出す（ヘッドレスの Godot）
    EXPORT_PATH=<絶対パス>/hex_world.json \\
      .claude/skills/godot-run/scripts/dump_tree.sh \\
      "--do=script:res://tools/scenarios/export_game_data.gd" --depth=0
2. 集計する
    python -I tools/research/hex_world.py <hex_world.json> docs/research/hex_world/generated
"""

import json
import sys
from collections import Counter
from pathlib import Path

MINER = "miner"
USE_KINDS = ("材料", "設置", "研究", "目標")


class Game:
    def __init__(self, data):
        self.data = data
        self.names = {i["id"]: i["name"] for i in data["items"]}
        self.biome_of_resource = {b["resource"]: b["name"] for b in data["biomes"]}
        self.biome_order = [b["name"] for b in data["biomes"]]
        self.crafts = [r for r in data["recipes"] if r["machine"] != MINER]
        self.research = {r["id"]: r for r in data["research"]}
        self.tiers = self._tiers()

    def _tiers(self):
        """原料 = 0。加工品は「材料の段階の最大 + 1」の、いちばん浅いレシピの値。"""
        tiers = {res: 0 for res in self.biome_of_resource}
        changed = True
        while changed:
            changed = False
            for r in self.crafts:
                if not all(i in tiers for i in r["inputs"]):
                    continue
                t = max(tiers[i] for i in r["inputs"]) + 1
                for out in r["outputs"]:
                    if t < tiers.get(out, 1 << 30):
                        tiers[out] = t
                        changed = True
        return tiers

    def recipe_of(self, item):
        return next((r for r in self.crafts if item in r["outputs"]), None)

    def raw_of(self, item, seen=None):
        seen = seen or set()
        if item in self.biome_of_resource:
            return {item}
        r = self.recipe_of(item)
        if r is None or item in seen:
            return set()
        out = set()
        for i in r["inputs"]:
            out |= self.raw_of(i, seen | {item})
        return out

    def biomes_of(self, item):
        names = {self.biome_of_resource[r] for r in self.raw_of(item)}
        return [b for b in self.biome_order if b in names]

    def uses(self, item):
        c = Counter()
        for r in self.crafts:
            if item in r["inputs"]:
                c["材料"] += 1
        for b in self.data["build_costs"]:
            if item in b["cost"]:
                c["設置"] += 1
        for r in self.data["research"]:
            if item in r["cost"]:
                c["研究"] += 1
        for lv in self.data["levels"]:
            if lv["goal_item"] == item:
                c["目標"] += 1
        return dict(c)

    def research_depth(self, rid):
        req = self.research[rid]["requires"]
        return 1 + max((self.research_depth(r) for r in req), default=0)

    def input_count_distribution(self):
        return dict(Counter(len(r["inputs"]) for r in self.crafts))

    def name(self, item):
        return self.names.get(item, item)

    def amounts(self, d):
        return "、".join(f"{self.name(k)} {v:g}" for k, v in d.items()) or "—"


def table(header, rows):
    lines = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    lines += ["| " + " | ".join(str(c) for c in row) + " |" for row in rows]
    return "\n".join(lines)


def uses_text(uses):
    return "、".join(f"{k} {uses[k]}" for k in USE_KINDS if k in uses) or "**なし**"


def write_items(g, out):
    rows = []
    for item in sorted(g.names, key=lambda i: (g.tiers.get(i, 99), list(g.names).index(i))):
        r = g.recipe_of(item)
        rows.append(
            [
                g.tiers.get(item, "?"),
                g.name(item),
                r["machine"] if r else "採掘",
                "・".join(g.biomes_of(item)),
                uses_text(g.uses(item)),
            ]
        )
    text = "# アイテム\n\n段階は原料 = 0 からの加工の深さ。使い道の数字は、その用途で使われる件数。\n\n"
    text += table(["段階", "アイテム", "作る機械", "要るバイオーム", "使い道"], rows)
    (out / "items.md").write_text(text + "\n", encoding="utf-8")


def write_recipes(g, out):
    text = "# レシピ\n\n"
    machines = []
    for r in g.crafts:
        if r["machine"] not in machines:
            machines.append(r["machine"])
    for m in machines:
        rows = []
        for r in g.crafts:
            if r["machine"] != m:
                continue
            per_min = 60 / r["time"] * sum(r["outputs"].values())
            rows.append([g.amounts(r["inputs"]), g.amounts(r["outputs"]), f"{r['time']:g}", f"{per_min:g}"])
        text += f"## {m}\n\n" + table(["材料", "出力", "秒", "出力/分"], rows) + "\n\n"
    (out / "recipes.md").write_text(text, encoding="utf-8")


def write_progression(g, out):
    rows = []
    for lv in g.data["levels"]:
        item = lv["goal_item"]
        research = [r["name"] for r in g.data["research"] if r["level"] == lv["level"]]
        rows.append(
            [
                lv["level"],
                f"{g.name(item)} {lv['required']}",
                g.tiers.get(item, "?"),
                len(g.biomes_of(item)),
                lv["reward"] or "—",
                "、".join(research) or "—",
            ]
        )
    text = "# 進行（ハブの目標と、そのレベルで開く研究）\n\n"
    text += table(["Lv", "納品", "段階", "バイオーム数", "報酬", "このレベルで開く研究"], rows) + "\n\n"
    rows = []
    for r in g.data["research"]:
        rows.append(
            [
                r["name"],
                r["level"],
                g.research_depth(r["id"]),
                "、".join(g.research[q]["name"] for q in r["requires"]) or "—",
                g.amounts(r["cost"]),
                ", ".join(f"{k}: {v}" for k, v in r["effect"].items()),
            ]
        )
    text += "## 研究\n\n" + table(["研究", "Lv", "深さ", "前提", "値段", "効果"], rows) + "\n\n"
    rows = [[b["piece"], g.amounts(b["cost"])] for b in g.data["build_costs"]]
    text += "## 設置コスト\n\n" + table(["ピース", "値段"], rows) + "\n"
    (out / "progression.md").write_text(text, encoding="utf-8")


def write_stats(g, out):
    tier_counts = Counter(t for i, t in g.tiers.items() if i in g.names)
    inputs = g.input_count_distribution()
    n = len(g.crafts)
    three_plus = sum(v for k, v in inputs.items() if k >= 3)
    depths = [g.research_depth(r) for r in g.research]
    unused = [g.name(i) for i in g.names if not g.uses(i)]
    raw = len(g.biome_of_resource)

    text = "# 統計\n\n## 他のゲームと同じ物差し（docs/research/README.md の表）\n\n"
    text += table(
        ["", "hex-world"],
        [
            ["素材（原料 + 加工品）", f"{len(g.names)}（{raw} + {len(g.names) - raw}）"],
            ["レシピ（加工）", n],
            ["加工の段階の最大", max(tier_counts)],
            ["入力 3 種以上のレシピ", f"{three_plus * 100 // n}%"],
            ["研究の件数", len(g.research)],
            ["研究の深さ", max(depths, default=0)],
            ["ハブの目標", f"{len(g.data['levels'])} 段"],
        ],
    )
    text += "\n\n## 段階ごとのアイテム数\n\n"
    text += table(["段階", "数"], sorted(tier_counts.items())) + "\n\n"
    text += "## レシピの入力の種類数\n\n" + table(["入力", "レシピ数"], sorted(inputs.items())) + "\n\n"
    biome_counts = Counter(len(g.biomes_of(i)) for i in g.names)
    text += "## 要るバイオームの数\n\n" + table(["バイオーム数", "アイテム数"], sorted(biome_counts.items()))
    text += "\n\n## 材料に使われる回数（上位）\n\n"
    usage = Counter()
    for r in g.crafts:
        usage.update(r["inputs"].keys())
    text += table(["アイテム", "レシピ数"], [[g.name(i), c] for i, c in usage.most_common(8)])
    text += "\n\n## 使い道のないアイテム\n\n"
    text += ("、".join(unused) if unused else "なし") + "\n"
    (out / "stats.md").write_text(text, encoding="utf-8")


def main():
    data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    g = Game(data)
    write_items(g, out)
    write_recipes(g, out)
    write_progression(g, out)
    write_stats(g, out)
    print(f"items {len(g.names)}, recipes {len(g.crafts)}, research {len(g.research)}")


if __name__ == "__main__":
    main()
