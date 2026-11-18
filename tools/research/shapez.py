"""shapez.io のソース（GitHub のリポジトリ）から、レベル・アップグレード・建物を一覧にする。

JS は実行せず、定義の書かれたファイルを正規表現で読む。日本語名は translations/base-ja.yaml。

使い方:
    git clone --depth 1 https://github.com/tobspr-games/shapez.io.git <repo>
    python -I tools/research/shapez.py <repo> docs/research/shapez/generated

PyYAML が必要（pip install pyyaml）。
"""

import math
import re
import sys
from collections import Counter
from pathlib import Path

import yaml

SUB_SHAPES = {"C": "円", "R": "四角", "S": "星", "W": "風車"}
COLORS = {
    "u": "無色",
    "r": "赤",
    "g": "緑",
    "b": "青",
    "y": "黄",
    "p": "紫",
    "c": "水色",
    "w": "白",
}
PRIMARY = set("rgb")
# 2 色を混ぜて作る色と 3 色を混ぜて作る白
MIXED = {"y": 1, "p": 1, "c": 1, "w": 2}

# 切断機で作れる半分（右半分・左半分）。ほかの欠け方は回転か 4 分割が要る
HALVES = [{0, 1}, {2, 3}]

# 標準版（Steam 版）の難易度
DIFFICULTY = 1
TIER_GROWTH = 2.5
FIXED_IMPROVEMENTS = [0.5, 0.5, 1, 1, 2, 1, 1]
UPGRADE_TIERS_SHOWN = 7

# globalConfig（src/js/core/config.js）の値。ベルト 1 本 = 2 個/秒
BELT_SPEED = 2


# ---- 形のキーを読む -----------------------------------------------------------


def parse_shape(key):
    """"CuCuCuCu:Sr------" → [[("C","u"),...], [...]]。空き象限は None。"""
    layers = []
    for layer in key.split(":"):
        quads = []
        for i in range(4):
            part = layer[i * 2 : i * 2 + 2]
            quads.append(None if part == "--" else (part[0], part[1]))
        layers.append(quads)
    return layers


def describe_shape(key):
    """人が読める説明。下の層から順に「円・無色×4 / 星・赤×1」。"""
    out = []
    for quads in parse_shape(key):
        counts = Counter(q for q in quads if q)
        parts = [f"{SUB_SHAPES[s]}・{COLORS[c]}×{n}" for (s, c), n in counts.items()]
        out.append("＋".join(parts))
    return " / ".join(out)


def operations(key):
    """その形を作るのに要る工程（建物）。採掘はいつも要るので数えない。

    厳密な最短手順ではなく、形の特徴から見積もる:
    - 欠けがある・1 層に違う部品が混ざる → 切断
    - 切断で作れない欠け方（右半分・左半分以外） → 回転
    - 色がある → 着色。混色なら混色機（白は 2 回）
    - 2 層以上、または 1 層に違う部品が混ざる → 積み重ね
    """
    ops = Counter()
    layers = parse_shape(key)
    for quads in layers:
        groups = {}
        for i, q in enumerate(quads):
            if q:
                groups.setdefault(q, set()).add(i)
        if len(groups) > 1 or any(len(g) < 4 for g in groups.values()):
            ops["切断"] = 1
        if any(len(g) < 4 and g not in HALVES for g in groups.values()):
            ops["回転"] = 1
        if len(groups) > 1:
            ops["積み重ね"] = 1
        colors = {c for (_, c) in groups}
        if colors - {"u"}:
            ops["着色"] = 1
        mix = max((MIXED.get(c, 0) for c in colors), default=0)
        ops["混色"] = max(ops["混色"], mix)
    if len(layers) > 1:
        ops["積み重ね"] = 1
    return {k: v for k, v in ops.items() if v}


def depth(key):
    """加工の段階の見積もり。採掘 = 0 として、工程を 1 段ずつ重ねた数。

    混色は 1 回ごとに 1 段（白は 2 段）、層を重ねるのは層数 − 1 段と数える。
    """
    ops = operations(key)
    layers = len(parse_shape(key))
    d = sum(1 for k in ("切断", "回転", "着色") if k in ops)
    d += ops.get("混色", 0)
    d += max(layers - 1, 1 if "積み重ね" in ops else 0)
    return d


# ---- JS の定義を読む ----------------------------------------------------------


def js_strings(text):
    """const finalGameShape = "..." のような文字列定数を集める。"""
    return dict(re.findall(r'const (\w+) = "([^"]+)"', text))


def resolve_shape(expr, consts):
    """形の式を 1 つの文字列に。chinaShapes ? A : B は B（中国版以外）を取る。"""
    expr = expr.strip()
    m = re.match(r'chinaShapes\s*\?\s*"[^"]+"\s*:\s*"([^"]+)"', expr)
    if m:
        return m.group(1)
    m = re.match(r'"([^"]+)"', expr)
    if m:
        return m.group(1)
    return consts[expr]


def read_levels(repo):
    text = (repo / "src/js/game/modes/levels.js").read_text(encoding="utf-8")
    consts = js_strings(text)
    body = text.split("const STANDALONE_LEVELS")[1].split("export function")[0]
    levels = []
    for block in re.findall(r"\{(.*?)\}", body, re.S):
        shape = re.search(r"shape:\s*(.+?),\s*(?://.*)?\n", block)
        required = re.search(r"required:\s*(\d+)", block)
        reward = re.search(r"enumHubGoalRewards\.(\w+)", block)
        levels.append(
            {
                "shape": resolve_shape(shape.group(1), consts),
                "required": int(required.group(1)),
                "reward": reward.group(1),
                "throughput": "throughputOnly: true" in block,
            }
        )
    return levels, consts


def find_nice_value(num):
    """src/js/core/utils.js の findNiceValue と同じ丸め。"""
    if num > 1e8:
        return num
    if num < 0.00001:
        return 0
    for limit, amount in (
        (50000, 10000),
        (20000, 5000),
        (5000, 1000),
        (2000, 500),
        (1000, 100),
        (100, 20),
        (20, 5),
    ):
        if num > limit:
            step = amount
            break
    else:
        step = 1
    nice = math.floor(num / step) * step
    if num >= 10:
        return round(nice)
    if num >= 1:
        return round(nice * 10) / 10
    return round(nice * 100) / 100


def read_upgrades(repo, consts):
    """regular.js の generateUpgrades を、表に出す段まで同じ手順でなぞる。"""
    text = (repo / "src/js/game/modes/regular.js").read_text(encoding="utf-8")
    consts = {**consts, **js_strings(text)}
    body = text.split("const upgrades = {")[1].split("// Automatically generate")[0]
    upgrades = {}
    for name, tiers_text in re.findall(r"(\w+): \[(.*?)\.\.\.generateInfiniteUnlocks", body, re.S):
        tiers = []
        for tier in re.findall(r"required: \[(.*?)\],\s*(excludePrevious: true,)?", tiers_text, re.S):
            reqs = []
            for shape_expr, amount in re.findall(
                r"shape:\s*((?:chinaShapes[^,]*?:\s*)?\"[^\"]+\"|\w+),\s*amount:\s*(\d+)",
                tier[0],
                re.S,
            ):
                reqs.append([resolve_shape(shape_expr, consts), int(amount)])
            tiers.append({"required": reqs, "exclude": bool(tier[1])})
        upgrades[name] = tiers[:UPGRADE_TIERS_SHOWN]

    # 前の段の納品物も、2.5 倍にして次の段の値段に足す
    for tiers in upgrades.values():
        carried = []
        for i, tier in enumerate(tiers):
            tier["improvement"] = FIXED_IMPROVEMENTS[i]
            for req in tier["required"]:
                req[1] = round(req[1] * DIFFICULTY)
            original = [list(r) for r in tier["required"]]
            if not tier["exclude"]:
                tier["required"] = [list(r) for r in carried] + tier["required"]
            carried += original
            for r in carried:
                r[1] = math.ceil(find_nice_value(r[1] * TIER_GROWTH))
    return upgrades


def read_reward_buildings(repo):
    """報酬 → 解放する建物（とその種類）。"""
    text = (repo / "src/js/game/tutorial_goals_mappings.js").read_text(encoding="utf-8")
    out = {}
    for reward, items in re.findall(
        r"\[enumHubGoalRewards\.(\w+)\]:\s*(typed\(\[.*?\]\)|null)", text, re.S
    ):
        out[reward] = re.findall(r"\[Meta(\w+)Building,\s*(?:\w+\.)?(\w+)\]", items)
    return out


def read_speeds(repo):
    text = (repo / "src/js/core/config.js").read_text(encoding="utf-8")
    body = text.split("buildingSpeeds: {")[1].split("}")[0]
    speeds = {}
    for name, a, b in re.findall(r"(\w+):\s*(\d+)\s*/\s*(\d+)", body):
        speeds[name] = int(a) / int(b)
    return speeds


# ---- 表を書く -----------------------------------------------------------------


def snake(name):
    return re.sub(r"(?<!^)([A-Z])", r"_\1", name).lower()


class Shapez:
    def __init__(self, repo):
        self.repo = repo
        self.ja = yaml.safe_load(
            (repo / "translations/base-ja.yaml").read_text(encoding="utf-8")
        )
        self.levels, consts = read_levels(repo)
        self.upgrades = read_upgrades(repo, consts)
        self.reward_buildings = read_reward_buildings(repo)
        self.speeds = read_speeds(repo)

    def reward_name(self, reward):
        story = self.ja.get("storyRewards", {}).get(reward)
        return story["title"] if story else reward

    def building_name(self, meta, variant):
        b = self.ja["buildings"].get(snake(meta), {})
        v = b.get(variant) or b.get("default") or {}
        return v.get("name", f"{meta}/{variant}")

    def unlocks_of(self, reward):
        return [self.building_name(m, v) for m, v in self.reward_buildings.get(reward, [])]


def table(header, rows):
    lines = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    lines += ["| " + " | ".join(str(c) for c in row) + " |" for row in rows]
    return "\n".join(lines)


def ops_text(key):
    ops = operations(key)
    parts = []
    for k in ("切断", "回転", "着色", "混色", "積み重ね"):
        if k in ops:
            parts.append(k if ops[k] == 1 else f"{k}×{ops[k]}")
    return "・".join(parts) or "採掘のみ"


def write_levels(sz, out):
    rows = []
    for i, lv in enumerate(sz.levels, 1):
        amount = f"{lv['required']} 個/秒" if lv["throughput"] else f"{lv['required']:,}"
        reward = sz.reward_name(lv["reward"])
        unlocks = "、".join(u for u in sz.unlocks_of(lv["reward"]) if u != reward)
        rows.append(
            [
                i,
                f"`{lv['shape']}`",
                describe_shape(lv["shape"]),
                ops_text(lv["shape"]),
                depth(lv["shape"]),
                amount,
                reward + (f"（{unlocks}）" if unlocks else ""),
            ]
        )
    text = "# レベル（ハブの目標）\n\n"
    text += "標準版（Steam 版）の 26 段。26 段目のあとはフリープレイ（形を乱数で作る）。\n"
    text += "工程と段階は形から見積もったもの（`tools/research/shapez.py` の operations / depth）。\n\n"
    text += table(["Lv", "形", "中身（下の層から）", "要る工程", "段階", "納品数", "報酬（解放する建物）"], rows)
    (out / "levels.md").write_text(text + "\n", encoding="utf-8")


def write_upgrades(sz, out):
    text = "# アップグレード（速度の強化）\n\n"
    text += "4 系統 × 7 段（標準版）。8 段目からは同じ 3 つの形を払い続ける無限強化（約 1,000 段）。\n"
    text += "前の段で払った形も 2.5 倍にして次の段に足される（excludePrevious の段は足さない）。\n\n"
    upgrade_names = sz.ja.get("shopUpgrades", {})
    for name, tiers in sz.upgrades.items():
        text += f"## {upgrade_names.get(name, {}).get('name', name)}\n\n"
        rows = []
        speed = 1.0
        for i, tier in enumerate(tiers, 1):
            speed += tier["improvement"]
            reqs = "<br>".join(f"`{s}` {n:,}" for s, n in tier["required"])
            total = sum(n for _, n in tier["required"])
            rows.append([i, f"×{speed:g}", reqs, f"{total:,}"])
        text += table(["段", "強化後の速さ", "払う形と個数", "合計"], rows) + "\n\n"
    (out / "upgrades.md").write_text(text, encoding="utf-8")


def write_buildings(sz, out):
    unlock_level = {}
    for i, lv in enumerate(sz.levels, 1):
        for meta, variant in sz.reward_buildings.get(lv["reward"], []):
            unlock_level.setdefault((meta, variant), i)
    rows = []
    for (meta, variant), lv in sorted(unlock_level.items(), key=lambda x: x[1]):
        speed_key = {
            ("Cutter", "quad"): "cutterQuad",
            ("Rotater", "ccw"): "rotaterCCW",
            ("Rotater", "rotate180"): "rotater180",
            ("Painter", "double"): "painterDouble",
            ("Painter", "quad"): "painterQuad",
        }.get((meta, variant), meta[0].lower() + meta[1:])
        per_sec = sz.speeds.get(speed_key)
        speed = f"{per_sec * BELT_SPEED:.2g} 個/秒" if per_sec else "—"
        internal = meta if variant == "defaultBuildingVariant" else f"{meta}/{variant}"
        rows.append([lv, sz.building_name(meta, variant), internal, speed])
    text = "# 建物\n\n"
    text += "最初から使えるのはベルト・抽出機・ハブ。下はレベルの報酬で解放される建物。\n"
    text += f"処理速度は強化前（ベルト 1 本 = {BELT_SPEED} 個/秒）。\n\n"
    text += table(["解放 Lv", "名前", "内部名", "処理速度"], rows)
    (out / "buildings.md").write_text(text + "\n", encoding="utf-8")


def write_stats(sz, out):
    depths = Counter(depth(lv["shape"]) for lv in sz.levels)
    layers = Counter(len(parse_shape(lv["shape"])) for lv in sz.levels)
    amounts = [lv["required"] for lv in sz.levels if not lv["throughput"]]
    text = "# 統計\n\n## レベルの形の段階（見積もり）\n\n"
    text += table(["段階", "レベル数"], sorted(depths.items())) + "\n\n"
    text += "## レベルの形の層の数\n\n"
    text += table(["層", "レベル数"], sorted(layers.items())) + "\n\n"
    text += "## 納品数の伸び\n\n"
    rows = []
    prev = None
    for i, lv in enumerate(sz.levels, 1):
        if lv["throughput"]:
            continue
        ratio = f"×{lv['required'] / prev:.2f}" if prev else ""
        rows.append([i, f"{lv['required']:,}", ratio])
        prev = lv["required"]
    text += table(["Lv", "納品数", "前の段との比"], rows) + "\n\n"
    text += f"- 最初 {amounts[0]:,} → 最後 {amounts[-1]:,}\n"
    text += f"- 報酬なしのレベル: {sum(1 for lv in sz.levels if lv['reward'] == 'no_reward')} 件\n"
    (out / "stats.md").write_text(text, encoding="utf-8")


def main():
    repo = Path(sys.argv[1])
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    sz = Shapez(repo)
    write_levels(sz, out)
    write_upgrades(sz, out)
    write_buildings(sz, out)
    write_stats(sz, out)
    print(f"levels {len(sz.levels)}, upgrades {len(sz.upgrades)}")


if __name__ == "__main__":
    main()
