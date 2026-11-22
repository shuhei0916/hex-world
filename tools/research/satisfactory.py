"""Satisfactory の公式データ（CommunityResources/Docs）から、アイテム・レシピ・研究を Markdown の一覧にまとめる。

使い方:
    python -I tools/research/satisfactory.py "<Satisfactory のインストール先>" <出力先>

Docs/en-US.json と Docs/ja.json（どちらも UTF-16 の JSON）を読む。
出力はゲームの内容そのものなので、公開リポジトリにはコミットしない（.gitignore 済み）。
"""

import json
import os
import re
import sys
from collections import defaultdict

ITEM_CLASSES = ("FGResourceDescriptor", "FGItemDescriptor", "FGItemDescriptorBiomass", "FGItemDescriptorNuclearFuel",
                "FGConsumableDescriptor", "FGPowerShardDescriptor", "FGItemDescriptorPowerBoosterFuel",
                "FGAmmoTypeProjectile", "FGAmmoTypeSpreadshot", "FGAmmoTypeInstantHit", "FGEquipmentDescriptor")
# レシピを作る機械（建築ガンや作業台は除く）
MACHINES = ("Build_SmelterMk1", "Build_ConstructorMk1", "Build_AssemblerMk1", "Build_FoundryMk1",
            "Build_ManufacturerMk1", "Build_OilRefinery", "Build_Packager", "Build_Blender", "Build_HadronCollider",
            "Build_Converter", "Build_QuantumEncoder")
SCHEMATIC_TYPES = {
    "EST_Tutorial": "HUB アップグレード（チュートリアル）",
    "EST_Milestone": "マイルストーン（HUB）",
    "EST_MAM": "MAM 研究",
    "EST_Alternate": "代替レシピ（ハードドライブ）",
    "EST_ResourceSink": "AWESOME ショップ（クーポン）",
}


def load(path):
    data = json.loads(open(path, "rb").read().decode("utf-16"))
    return {g["NativeClass"].split(".")[-1].rstrip("'"): g["Classes"] for g in data}


def refs(text, prefix=""):
    """'.../Desc_Foo.Desc_Foo_C' のような参照からクラス名だけを抜き出す。"""
    return re.findall(r"\.(" + prefix + r"[A-Za-z0-9_\-]+_C)'", text or "")


def amounts(text):
    return [(m.group(1), int(m.group(2))) for m in re.finditer(r"\.([A-Za-z0-9_\-]+_C)'\",Amount=(\d+)", text or "")]


def fmt_time(sec):
    if sec >= 60:
        m, s = divmod(round(sec), 60)
        return f"{m}m{s:02d}s"
    return f"{sec:g}s"


def cell(x):
    return str(x).replace("\r", " ").replace("\n", " ").replace("|", "/")


class Data:
    def __init__(self, en, ja):
        self.en, self.ja = en, ja
        self.ja_name = {c["ClassName"]: c.get("mDisplayName", "") for cls in ja.values() for c in cls}
        self.items = {c["ClassName"]: c for k in ITEM_CLASSES for c in en.get(k, [])}
        self.fluid = {k for k, c in self.items.items() if c.get("mForm") in ("RF_LIQUID", "RF_GAS")}
        self.recipes = {r["ClassName"]: r for r in en["FGRecipe"]}
        self.machine_recipes = []
        for r in en["FGRecipe"]:
            ms = [m for m in re.findall(r"/([A-Za-z0-9_]+)\.\1_C", r["mProducedIn"]) if m in MACHINES]
            if ms:
                self.machine_recipes.append((ms[0], r))
        self.buildings = {c["ClassName"]: c for k, v in en.items() if k.startswith("FGBuildable") for c in v}
        self.producers = defaultdict(list)
        for _, r in self.machine_recipes:
            for it, _ in amounts(r["mProduct"]):
                self.producers[it].append(r)
        self.tiers = self._tiers()

    def amount(self, it, n):
        return n / 1000 if it in self.fluid else n  # 液体・気体は 1000 分の 1 m³ 単位で入っている

    def name(self, cls):
        c = self.items.get(cls) or self.recipes.get(cls) or self.buildings.get(cls) or {}
        e = c.get("mDisplayName") or cls
        j = self.ja_name.get(cls, "")
        return f"{e}（{j}）" if j and j != e else e

    def stack(self, text):
        return " + ".join(f"{self.amount(i, n):g}×{self.name(i)}" for i, n in amounts(text)) or "—"

    def _tiers(self):
        raw = {c["ClassName"] for c in self.en.get("FGResourceDescriptor", [])}
        tier = {i: 0 for i in self.items if i in raw or not self.producers.get(i)}
        changed = True
        while changed:
            changed = False
            for it in self.items:
                best = None
                for r in self.producers.get(it, []):
                    if "Alternate" in r["ClassName"] or "Build_Converter" in r["mProducedIn"]:
                        continue  # 段階は標準レシピで数える（鉱石どうしを変える Converter は除く）
                    ins = [tier.get(i) for i, _ in amounts(r["mIngredients"])]
                    if any(t is None for t in ins):
                        continue
                    t = 1 + max(ins, default=-1)
                    best = t if best is None else min(best, t)
                if best is not None and it not in raw and (it not in tier or best < tier[it]):
                    tier[it] = best
                    changed = True
        return tier


def write_recipes(d, out):
    by_machine = defaultdict(list)
    for m, r in d.machine_recipes:
        by_machine[m].append(r)
    lines = ["# Satisfactory レシピ一覧（機械ごと）", "",
             "液体・気体の量は m³。毎分 = 60 / 時間 × 最初の出力の量。★ = 代替レシピ。", ""]
    for m in MACHINES:
        rs = sorted(by_machine.get(m, []), key=lambda r: float(r["mManufactoringDuration"]))
        if not rs:
            continue
        lines += [f"## {d.name(m + '_C')}（{len(rs)} 件）", "",
                  "| レシピ | 入力 | 出力 | 時間 | 出力/分 |", "|---|---|---|---|---|"]
        for r in rs:
            t = float(r["mManufactoringDuration"])
            outs = amounts(r["mProduct"])
            per_min = 60 / t * d.amount(*outs[0]) if t and outs else 0
            star = "★" if "Alternate" in r["ClassName"] else ""
            lines.append(f"| {star}{cell(d.name(r['ClassName']))} | {cell(d.stack(r['mIngredients']))} | "
                         f"{cell(d.stack(r['mProduct']))} | {fmt_time(t)} | {per_min:.2f} |")
        lines.append("")
    open(os.path.join(out, "recipes.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_items(d, out):
    rows = defaultdict(list)
    for k, c in d.items.items():
        if not d.producers.get(k) and not any(k in r["mIngredients"] for _, r in d.machine_recipes) \
                and k not in d.tiers:
            continue
        where = sorted({d.name(m + "_C").split("（")[0] for m, r in d.machine_recipes
                        if k in dict(amounts(r["mProduct"])) and "Alternate" not in r["ClassName"]})
        rows[d.tiers.get(k, "?")].append((c.get("mDisplayName", k), d.ja_name.get(k, ""), c.get("mForm", ""),
                                          c.get("mResourceSinkPoints", ""), " / ".join(where) or "—",
                                          c.get("mDescription", "")[:120]))
    lines = ["# Satisfactory アイテム一覧", "",
             "段階 = 原料を 0 とした加工の深さ（標準レシピのうち一番浅い作り方で数える）。シンク = AWESOME シンクのポイント。", ""]
    for t in sorted(rows, key=lambda x: (isinstance(x, str), x)):
        lines += [f"## 段階 {t}（{len(rows[t])} 件）", "",
                  "| 英語名 | 日本語名 | 形態 | シンク | 作る機械 | 説明 |", "|---|---|---|---|---|---|"]
        lines += ["| " + " | ".join(cell(x) for x in r) + " |" for r in sorted(rows[t])]
        lines.append("")
    open(os.path.join(out, "items.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_buildings(d, out):
    build_cost = {}
    for r in d.en["FGRecipe"]:
        if "BP_BuildGun" in r["mProducedIn"]:
            for it, _ in amounts(r["mProduct"]):
                build_cost[it.replace("Desc_", "Build_")] = r["mIngredients"]
    lines = ["# Satisfactory 生産・発電・採掘の建物", "",
             "| 英語名 | 日本語名 | 種類 | 建設コスト | 電力(MW) | 速度 | 説明 |", "|---|---|---|---|---|---|---|"]
    keep = ("Manufacturer", "Factory", "Generator", "ResourceExtractor", "Fracking", "WaterPump", "SpaceElevator",
            "ResourceSink", "RadarTower", "PowerStorage", "Storage", "ConveyorBelt", "ConveyorLift", "Pipeline",
            "TrainPlatform", "DroneStation", "DockingStation", "PowerBooster", "Portal")
    for k, v in d.en.items():
        if not k.startswith("FGBuildable") or not any(s in k for s in keep) or "Lightweight" in k:
            continue
        for c in v:
            cells = [c.get("mDisplayName", c["ClassName"]), d.ja_name.get(c["ClassName"], ""), k.replace("FGBuildable", ""),
                     d.stack(build_cost.get(c["ClassName"], "")), c.get("mPowerConsumption", c.get("mPowerProduction", "")),
                     c.get("mManufacturingSpeed", c.get("mExtractCycleTime", "")), c.get("mDescription", "")[:100]]
            lines.append("| " + " | ".join(cell(x) for x in cells) + " |")
    open(os.path.join(out, "buildings.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def mam_tree(s):
    """Research_Caterium_4_2_C → Caterium（MAM の系統名）"""
    m = re.match(r"Research_(Alien|AO|[A-Za-z]+)", s["ClassName"])
    return m.group(1) if m else s["ClassName"]


def write_research(d, out):
    schems = d.en["FGSchematic"]
    by_cls = {s["ClassName"]: s for s in schems}

    def unlocks(s):
        rec, other = [], []
        for u in s.get("mUnlocks", []):
            if u["Class"] == "BP_UnlockRecipe_C":
                rec += [d.name(r) for r in refs(u.get("mRecipes", ""))]
            elif u["Class"] == "BP_UnlockInventorySlot_C":
                other.append("インベントリ拡張")
            elif u["Class"] == "BP_UnlockArmEquipmentSlot_C":
                other.append("手の装備枠拡張")
            elif u["Class"] == "BP_UnlockScannableResource_C":
                other.append("スキャン: " + "・".join(d.name(x) for x in refs(u.get("mResourcePairsToAddToScanner", ""))))
            elif u["Class"] not in ("BP_UnlockInfoOnly_C", "BP_UnlockSchematic_C", "BP_UnlockGiveItem_C"):
                other.append(u["Class"].replace("BP_Unlock", "").replace("_C", ""))
        return rec, other

    lines = ["# Satisfactory 研究・解放", "",
             "Docs.json の FGSchematic から作ったもの。MAM の木構造（どのノードがどれの先か）は Docs.json に入っていない。", "",
             "| 種類 | 件数 |", "|---|---|"]
    count = defaultdict(int)
    for s in schems:
        count[s["mType"]] += 1
    lines += [f"| {SCHEMATIC_TYPES.get(t, t)} | {n} |" for t, n in sorted(count.items(), key=lambda x: -x[1])]
    lines.append("")
    for t in ("EST_Tutorial", "EST_Milestone", "EST_MAM", "EST_Alternate"):
        rs = [s for s in schems if s["mType"] == t]
        key = (lambda s: (int(s["mTechTier"] or 0), s["ClassName"])) if t != "EST_MAM" else \
            (lambda s: (mam_tree(s), int(s["mTechTier"] or 0), s["ClassName"]))
        rs.sort(key=key)
        lines += [f"## {SCHEMATIC_TYPES[t]}（{len(rs)} 件）", "",
                  "| Tier | 名前 | 前提 | コスト | 時間 | 解放するレシピ | その他 |", "|---|---|---|---|---|---|---|"]
        for s in rs:
            deps = [d.name(x) if x not in by_cls else (by_cls[x]["mDisplayName"] or x)
                    for dep in s.get("mSchematicDependencies", []) for x in refs(dep.get("mSchematics", ""))]
            rec, other = unlocks(s)
            name = s["mDisplayName"]
            if t == "EST_MAM":
                name = mam_tree(s) + " / " + name
            cells = [s["mTechTier"], name, "・".join(deps) or "—", d.stack(s["mCost"]),
                     fmt_time(float(s["mTimeToComplete"] or 0)), "・".join(rec), " / ".join(other)]
            lines.append("| " + " | ".join(cell(x) for x in cells) + " |")
        lines.append("")
    open(os.path.join(out, "research.md"), "w", encoding="utf-8").write("\n".join(lines))


def write_stats(d, out):
    std = [(m, r) for m, r in d.machine_recipes if "Alternate" not in r["ClassName"]]
    tier_count = defaultdict(int)
    for it, t in d.tiers.items():
        if d.producers.get(it) or any(it in r["mIngredients"] for _, r in std):
            tier_count[t] += 1
    n_in = defaultdict(int)
    fan_in = defaultdict(int)
    for _, r in std:
        ins = amounts(r["mIngredients"])
        n_in[len(ins)] += 1
        for i, _ in ins:
            fan_in[i] += 1
    alt = len(d.machine_recipes) - len(std)
    lines = ["# Satisfactory 数字で見る構造", "",
             f"- 機械のレシピ {len(d.machine_recipes)} 件（標準 {len(std)}・代替 {alt}）",
             f"- マイルストーン {sum(1 for s in d.en['FGSchematic'] if s['mType'] == 'EST_Milestone')} 件、"
             f"MAM {sum(1 for s in d.en['FGSchematic'] if s['mType'] == 'EST_MAM')} 件", "",
             "## 段階ごとのアイテム数（標準レシピ）", "", "| 段階 | 件数 |", "|---|---|"]
    lines += [f"| {t} | {tier_count[t]} |" for t in sorted(tier_count)]
    lines += ["", "## レシピの入力の種類数（標準レシピ）", "", "| 入力の種類 | レシピ数 |", "|---|---|"]
    lines += [f"| {k} | {n_in[k]} |" for k in sorted(n_in)]
    lines += ["", "## よく材料に使われるアイテム（標準レシピ、上位20）", "", "| アイテム | 段階 | 使われるレシピ数 |", "|---|---|---|"]
    lines += [f"| {d.name(i)} | {d.tiers.get(i, '?')} | {n} |" for i, n in sorted(fan_in.items(), key=lambda x: -x[1])[:20]]
    lines += ["", "## マイルストーンの Tier ごとの件数とコスト合計（個数）", "", "| Tier | 件数 | コスト合計 |", "|---|---|---|"]
    per_tier = defaultdict(lambda: [0, 0])
    for s in d.en["FGSchematic"]:
        if s["mType"] == "EST_Milestone":
            per_tier[int(s["mTechTier"])][0] += 1
            per_tier[int(s["mTechTier"])][1] += sum(n for _, n in amounts(s["mCost"]))
    lines += [f"| {t} | {a} | {b} |" for t, (a, b) in sorted(per_tier.items())]
    open(os.path.join(out, "stats.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")


def main(game_dir, out):
    docs = os.path.join(game_dir, "CommunityResources", "Docs")
    d = Data(load(os.path.join(docs, "en-US.json")), load(os.path.join(docs, "ja.json")))
    os.makedirs(out, exist_ok=True)
    write_items(d, out)
    write_recipes(d, out)
    write_buildings(d, out)
    write_research(d, out)
    write_stats(d, out)
    print("wrote", sorted(os.listdir(out)))


if __name__ == "__main__":
    main(*sys.argv[1:3])
