"""Nova Lands のアイテム・レシピ・建物・進行要素を Markdown の一覧にまとめる。

使い方:
    python -I tools/research/nova_lands.py <gamedata.json> "<Nova Lands のインストール先>" <出力先>

- gamedata.json: NovaCalc (https://github.com/frostmx/novacalc) の data/gamedata.json。
  ゲームファイルから抜き出したアイテム・レシピ・建物の数値。
- インストール先: StreamingAssets/Localization/messages_{en,ja}.bytes から英語名・日本語名を読む。
  研究・チャレンジ・島などの名前もここから取る（コストや前提関係は入っていない）。

出力はゲームの内容そのものなので、公開リポジトリにはコミットしない（.gitignore 済み）。
"""

import json
import os
import re
import sys
from collections import defaultdict

# 一覧に出さない建物の種類（飾り・NPC・家具など、工場の設計と関係が薄いもの）
SKIP_BUILDING_CLASSES = {
    "HouseDecorationBuilding",
    "BaseNPC",
    "PlayerBedBuilding",
    "MuseumDioramaHiddenBuilding",
    "SpaceWalkCollectableResource",
    "InteriorsAreaPassage",
    "InteriorsAreaElevator",
    "EventTriggerBuilding",
    "LeverBuilding",
    "TargetBuilding",
}
# 市場で売るための梱包アイテムは数が多く、生産の構造とは別物なので分けて数えるだけにする
PACKAGE_CLASS = "PackageResourceScriptableObject"


def load_loc(path):
    text = open(path, encoding="utf-8-sig").read()
    return json.loads(re.sub(r",\s*}\s*$", "}", text))  # 末尾のカンマを許す


def fmt_time(sec):
    if sec >= 60:
        m, s = divmod(round(sec), 60)
        return f"{m}m{s:02d}s"
    return f"{sec:g}s"


class Data:
    def __init__(self, gamedata, en, ja):
        self.g, self.en, self.ja = gamedata, en, ja
        self.items = {i["id"]: i for i in gamedata["items"]}
        self.recipes = {r["id"]: r for r in gamedata["recipes"]}
        self.made_in = defaultdict(list)  # recipe id -> building
        for b in gamedata["buildings"]:
            for rid in b.get("recipes", []):
                self.made_in[rid].append(b)
        for c in gamedata.get("creatures", []):
            for rid in c.get("recipes", []):
                self.made_in[rid].append({"nameKey": c["nameKey"], "key": c["key"], "creature": True})
        self.producers = defaultdict(list)  # item id -> recipes
        for r in gamedata["recipes"]:
            for o in r["outputs"]:
                self.producers[o["item"]].append(r)
        self.tiers = self._tiers()

    def name(self, key):
        return self.en.get(key, key), self.ja.get(key, "")

    def item_name(self, iid):
        it = self.items.get(iid)
        if not it:
            return f"?{iid}"
        if "packageOf" in it:  # 梱包アイテムは名前キーを持たない
            return f"梱包:{self.item_name(it['packageOf'])}"
        e, j = self.name(it["nameKey"])
        return f"{e}（{j}）" if j and j != e else e

    def stack(self, lst):
        return " + ".join(f"{x['amount']}×{self.item_name(x['item'])}" for x in lst) or "—"

    def _tiers(self):
        """原料（作るレシピがない）を 0 とし、作れるレシピのうち一番浅いものの「入力の最大段階 + 1」を段階とする。"""
        tier = {iid: 0 for iid in self.items if not self.producers.get(iid)}
        changed = True
        while changed:
            changed = False
            for iid in self.items:
                best = None
                for r in self.producers.get(iid, []):
                    ins = [tier.get(x["item"]) for x in r["inputs"]]
                    if any(t is None for t in ins):
                        continue
                    t = 1 + max(ins, default=-1)
                    best = t if best is None else min(best, t)
                if best is not None and tier.get(iid) != best and (iid not in tier or best < tier[iid]):
                    tier[iid] = best
                    changed = True
        return tier


def write_items(d, out):
    rows = defaultdict(list)
    packages = 0
    for it in d.g["items"]:
        if it["class"] == PACKAGE_CLASS:
            packages += 1
            continue
        e, j = d.name(it["nameKey"])
        de, dj = d.name(it["descKey"])
        where = sorted({d.name(b["nameKey"])[1] or d.name(b["nameKey"])[0]
                        for r in d.producers.get(it["id"], []) for b in d.made_in.get(r["id"], [])})
        rows[d.tiers.get(it["id"], "?")].append((e, j, it["class"].replace("ScriptableObject", ""),
                                                 it["stack"], " / ".join(where) or "—", dj or de))
    lines = ["# Nova Lands アイテム一覧", "",
             f"梱包アイテム（市場向け）{packages} 件は除外。段階 = 原料を 0 とした加工の深さ（一番浅い作り方で数える）。", ""]
    for t in sorted(rows, key=lambda x: (isinstance(x, str), x)):
        label = t if t != "?" else "?（原料から一方向にたどれないもの。捕獲カプセルなど）"
        lines += [f"## 段階 {label}（{len(rows[t])} 件）", "",
                  "| 英語名 | 日本語名 | 種類 | スタック | 作る場所 | 説明 |", "|---|---|---|---|---|---|"]
        for r in sorted(rows[t]):
            lines.append("| " + " | ".join(str(x).replace("\n", " ").replace("|", "/") for x in r) + " |")
        lines.append("")
    open(os.path.join(out, "items.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_recipes(d, out):
    by_place = defaultdict(list)
    for r in d.g["recipes"]:
        places = d.made_in.get(r["id"]) or [{"nameKey": "(どの建物にも属さない)", "key": "-"}]
        for b in places:
            by_place[d.item_name_or_building(b)].append((b, r))
    lines = ["# Nova Lands レシピ一覧（建物ごと）", "",
             "時間は建物の速度補正前のレシピ時間。毎分 = 60 / 時間 × 出力数（建物速度 1 として）。", ""]
    for place in sorted(by_place):
        b0 = by_place[place][0][0]
        sp = b0.get("productionSpeed")
        head = f"## {place}" + (f"（速度 {sp:g}）" if sp else "")
        lines += [head, "", "| 入力 | 出力 | 時間 | 出力/分 | 最初から解放 |", "|---|---|---|---|---|"]
        for _, r in sorted(by_place[place], key=lambda x: x[1]["time"]):
            per_min = 60 / r["time"] * r["outputs"][0]["amount"] if r["time"] and r["outputs"] else 0
            lines.append(f"| {d.stack(r['inputs'])} | {d.stack(r['outputs'])} | {fmt_time(r['time'])} | "
                         f"{per_min:.2f} | {'○' if r['startUnlocked'] else ''} |")
        lines.append("")
    open(os.path.join(out, "recipes.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_buildings(d, out):
    lines = ["# Nova Lands 建物一覧", "",
             "飾り・NPC・家具などは除外。電力は負なら消費、producedEnergy は発電量。", "",
             "| 英語名 | 日本語名 | 種類 | 建設コスト | 電力 | 発電 | 速度 | レシピ数 | 説明 |",
             "|---|---|---|---|---|---|---|---|---|"]
    for b in d.g["buildings"]:
        if b["class"] in SKIP_BUILDING_CLASSES:
            continue
        e, j = d.name(b["nameKey"])
        de, dj = d.name(b["descKey"])
        cells = [e, j, b["class"].replace("Building", ""), d.stack(b["cost"]), b["energy"] or "",
                 b.get("producedEnergy", ""), b.get("productionSpeed", ""), len(b.get("recipes", [])) or "",
                 dj or de]
        lines.append("| " + " | ".join(str(x).replace("\n", " ").replace("|", "/") for x in cells) + " |")
    open(os.path.join(out, "buildings.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def write_progression(d, out):
    en, ja = d.en, d.ja
    npc_like = re.compile(r"(NPC|WORKER|FIGHTER|LOGISTICS|DOUGLAS|^ED|UNKONW|WITCH|EDWARD|SASHA|ENGINEER|MUSEUM_KEEPER|"
                          r"SHIELD_ARMOR|WOLLIAM|PET_DOG|ARMANDO|BIRD|SPSTMANAGER)")
    sections = {
        "研究（Research Processor の技術ツリー）": lambda k, b: re.fullmatch(r"[A-Z0-9_]+", b) and not npc_like.search(b),
        "宇宙遊泳・市場・家の強化（研究扱いの進行要素）": lambda k, b: b.startswith(("MarketMembership", "Spacewalk", "HouseUpgrade")),
        "島（バイオーム）": lambda k, b: "Biome" in b,
        "チャレンジ（生産目標）": lambda k, b: "Challenge" in b,
        "実績": lambda k, b: b.endswith("Ach"),
        "ボス・生き物": lambda k, b: "Creature" in b or "Boss" in b,
        "レリック": lambda k, b: "Relic" in b,
    }
    lines = ["# Nova Lands 進行要素", "",
             "ゲーム内テキストから取った名前と説明。研究のコスト・前提・解放内容は含まない"
             "（ゲームのアセットにしか入っておらず、まだ抜き出していない）。並びはテキストファイル内の順で、"
             "おおむね追加された順。", ""]
    for title, pred in sections.items():
        rows = []
        for k in en:
            if not k.endswith("_NAME") or k.endswith(("_BUILDING_NAME", "_RESOURCE_NAME", "_SKIN_NAME",
                                                      "_ACTION_NAME", "_PARAMETER_NAME", "_EQUIP_NAME")):
                continue
            base = k[:-5]
            if pred(k, base):
                rows.append((en[k], ja.get(k, ""), ja.get(base + "_DESC") or en.get(base + "_DESC", "")))
        lines += [f"## {title}（{len(rows)} 件）", "", "| 英語名 | 日本語名 | 説明 |", "|---|---|---|"]
        lines += ["| " + " | ".join(str(x).replace("\n", " ").replace("|", "/") for x in r) + " |" for r in rows]
        lines.append("")
    open(os.path.join(out, "progression.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_stats(d, out):
    items = [i for i in d.g["items"] if i["class"] != PACKAGE_CLASS]
    tier_count = defaultdict(int)
    for i in items:
        tier_count[d.tiers.get(i["id"], "?")] += 1
    def is_packaging(r):
        return any(d.items.get(x["item"], {}).get("class") == PACKAGE_CLASS for x in r["inputs"] + r["outputs"])

    recipes = [r for r in d.g["recipes"] if not is_packaging(r)]
    fan_in = defaultdict(int)  # どれだけ多くのレシピの入力に使われるか
    for r in recipes:
        for x in r["inputs"]:
            fan_in[x["item"]] += 1
    top = sorted(fan_in.items(), key=lambda x: -x[1])[:20]
    n_in = defaultdict(int)
    for r in recipes:
        n_in[len(r["inputs"])] += 1
    lines = ["# Nova Lands 数字で見る構造", "",
             f"- アイテム {len(items)} 件（梱包を除く）、レシピ {len(recipes)} 件（梱包・開封の "
             f"{len(d.g['recipes']) - len(recipes)} 件を除く）、"
             f"レシピを持つ建物 {sum(1 for b in d.g['buildings'] if b.get('recipes'))} 種", "",
             "## 段階ごとのアイテム数", "", "| 段階 | 件数 |", "|---|---|"]
    lines += [f"| {t} | {tier_count[t]} |" for t in sorted(tier_count, key=lambda x: (isinstance(x, str), x))]
    lines += ["", "## レシピの入力の種類数", "", "| 入力の種類 | レシピ数 |", "|---|---|"]
    lines += [f"| {k} | {n_in[k]} |" for k in sorted(n_in)]
    lines += ["", "## よく材料に使われるアイテム（上位20）", "", "| アイテム | 段階 | 使われるレシピ数 |", "|---|---|---|"]
    lines += [f"| {d.item_name(i)} | {d.tiers.get(i, '?')} | {n} |" for i, n in top]
    open(os.path.join(out, "stats.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def _place_name(self, b):
    if b.get("key") == "-":
        return b["nameKey"]
    e, j = self.name(b["nameKey"])
    label = f"{e}（{j}）" if j and j != e else e
    return ("生き物: " + label) if b.get("creature") else label


Data.item_name_or_building = _place_name


def main(gamedata_path, game_dir, out):
    loc = os.path.join(game_dir, "Nova Lands_Data", "StreamingAssets", "Localization")
    d = Data(json.load(open(gamedata_path, encoding="utf-8")),
             load_loc(os.path.join(loc, "messages_en.bytes")),
             load_loc(os.path.join(loc, "messages_ja.bytes")))
    os.makedirs(out, exist_ok=True)
    write_items(d, out)
    write_recipes(d, out)
    write_buildings(d, out)
    write_progression(d, out)
    write_stats(d, out)
    print("wrote", sorted(os.listdir(out)))


if __name__ == "__main__":
    main(*sys.argv[1:4])
