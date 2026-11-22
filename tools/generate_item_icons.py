"""アイテムのアイコン（記号的な線画の SVG）を assets/items/ に作る。

    python tools/generate_item_icons.py

方針（docs/ の参考画像に寄せる）:
- 形で加工の段階が分かる（鉱石=ごつごつした塊、インゴット=延べ棒、板、棒、ネジ…）
- 色で素材が分かる（鉄=青灰、銅=橙、鋼=濃い青灰、砂/ガラス=黄土/水色、回路=緑）
- 塗りは素材の色1色、線は同じ色相の暗い色。陰影やグラデーションは付けない
- 暗い画面でも紙の画面でも読めるよう、塗りは中間の明るさにする
"""

import math
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "items")
SIZE = 64
STROKE = 3.5

# 素材の色: (塗り, 線)
IRON = ("#a7b4c2", "#3c4652")
COPPER = ("#de8a4f", "#6b3415")
COAL = ("#5b5b5f", "#1b1b1d")
STEEL = ("#73879b", "#232d38")
SAND = ("#e4c57f", "#7a5a1e")
GLASS = ("#9fd8e4", "#2f6874")
CIRCUIT = ("#68b884", "#1f4d30")
LIMESTONE = ("#d3cdb4", "#5e5940")
QUICKLIME = ("#f1efe6", "#6b6858")
CONCRETE = ("#a4a6a8", "#3e4144")


def _style(color, width=STROKE):
    fill, stroke = color
    return (
        f'fill="{fill}" stroke="{stroke}" stroke-width="{width}" '
        'stroke-linejoin="round" stroke-linecap="round"'
    )


def _line_style(color, width=STROKE):
    return (
        f'fill="none" stroke="{color[1]}" stroke-width="{width}" '
        'stroke-linejoin="round" stroke-linecap="round"'
    )


def _poly(points, color, width=STROKE):
    pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    return f'<polygon points="{pts}" {_style(color, width)}/>'


def _polyline(points, color, width=STROKE):
    pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    return f'<polyline points="{pts}" {_line_style(color, width)}/>'


def _circle(cx, cy, r, color, width=STROKE):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" {_style(color, width)}/>'


def _rect(x, y, w, h, color, rx=2, width=STROKE):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" {_style(color, width)}/>'


# --- 形 -------------------------------------------------------------------


def ore(color):
    # ごつごつした塊と、面の境目の線
    body = [(14, 40), (20, 22), (34, 14), (48, 20), (54, 36), (46, 50), (26, 52)]
    return [
        _poly(body, color),
        _polyline([(20, 22), (30, 32), (34, 14)], color, 2.5),
        _polyline([(30, 32), (46, 50)], color, 2.5),
        _polyline([(30, 32), (54, 36)], color, 2.5),
    ]


def ingot(color):
    # 台形の延べ棒（上面と前面）
    return [
        _poly([(10, 44), (16, 30), (48, 30), (54, 44)], color),
        _poly([(16, 30), (22, 20), (42, 20), (48, 30)], color),
    ]


def plate(color):
    # 厚みのある平たい板
    top = [(8, 30), (32, 18), (56, 30), (32, 42)]
    return [
        _poly([(8, 30), (8, 36), (32, 48), (56, 36), (56, 30), (32, 42)], color),
        _poly(top, color),
    ]


def screw(color):
    # 六角の頭とねじ山
    head = [(22, 10), (42, 10), (46, 18), (18, 18)]
    thread = [(26, 20)]
    y = 20
    left = True
    while y < 50:
        y += 5
        thread.append((38 if left else 26, y))
        left = not left
    return [
        _rect(26, 18, 12, 34, color, rx=2),
        _poly(head, color),
        _polyline(thread, color, 2.5),
    ]


def wire(color):
    # 巻いた線（糸巻き）
    parts = [_rect(14, 14, 36, 36, color, rx=6)]
    for x in (22, 29, 36, 43):
        parts.append(_polyline([(x, 16), (x, 48)], color, 2.5))
    parts.append(_polyline([(48, 32), (58, 40)], color, 3))
    return parts


def beam(color):
    # I 形の断面
    return [
        _poly(
            [
                (12, 12), (52, 12), (52, 21), (37, 21), (37, 43), (52, 43),
                (52, 52), (12, 52), (12, 43), (27, 43), (27, 21), (12, 21),
            ],
            color,
        )
    ]


def sand_pile(color):
    # 砂の山と粒
    parts = [_poly([(8, 50), (22, 30), (32, 24), (42, 30), (56, 50)], color)]
    for x, y in [(24, 40), (32, 34), (40, 42), (30, 45), (36, 30)]:
        parts.append(f'<circle cx="{x}" cy="{y}" r="1.6" fill="{color[1]}"/>')
    return parts


def glass(color):
    # 板ガラスと光の筋
    return [
        _rect(14, 12, 36, 40, color, rx=3),
        _polyline([(22, 26), (30, 18)], color, 2.5),
        _polyline([(22, 36), (40, 18)], color, 2.5),
    ]


def lens(color):
    # 両凸レンズ
    return [
        '<path d="M32 8 C48 20 48 44 32 56 C16 44 16 20 32 8 Z" '
        + _style(color)
        + "/>",
        _polyline([(32, 14), (32, 50)], color, 2),
    ]


def powder(color):
    # 袋に入った粉（口を縛った袋と、こぼれた粉）
    parts = [
        _poly([(18, 24), (46, 24), (52, 52), (12, 52)], color),
        _polyline([(22, 24), (26, 14), (38, 14), (42, 24)], color, 3),
    ]
    for x, y in [(56, 54), (8, 55), (60, 50)]:
        parts.append(f'<circle cx="{x}" cy="{y}" r="1.8" fill="{color[1]}"/>')
    return parts


def block(color):
    # 直方体のブロック（上面と前面・側面）
    return [
        _poly([(10, 26), (32, 16), (54, 26), (32, 36)], color),
        _poly([(10, 26), (32, 36), (32, 54), (10, 44)], color),
        _poly([(32, 36), (54, 26), (54, 44), (32, 54)], color),
    ]


def gear(color, cx=32, cy=32, r_out=24, r_in=18, teeth=8, hole=7):
    points = []
    for i in range(teeth * 4):
        angle = math.tau * i / (teeth * 4)
        r = r_out if (i % 4) in (1, 2) else r_in
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    return [_poly(points, color), _circle(cx, cy, hole, color)]


def chip(color):
    # 回路の板とピン
    parts = []
    for i in range(3):
        y = 22 + i * 10
        parts.append(_polyline([(8, y), (16, y)], color, 3))
        parts.append(_polyline([(48, y), (56, y)], color, 3))
    parts.append(_rect(16, 14, 32, 36, color, rx=3))
    parts.append(_polyline([(24, 24), (32, 24), (32, 40), (40, 40)], color, 2.5))
    return parts


def motor():
    # 円筒の胴に銅の巻き線、軸
    return [
        _polyline([(50, 32), (60, 32)], STEEL, 4),
        _rect(10, 16, 40, 32, IRON, rx=6),
        _rect(22, 16, 16, 32, COPPER, rx=0),
    ]


def frame(color):
    # 三角に組んだ骨組み
    return [
        _poly([(8, 52), (32, 12), (56, 52)], color),
        _polyline([(20, 32), (44, 32)], color, 3),
        _polyline([(20, 32), (32, 52), (44, 32)], color, 3),
    ]


def sensor():
    # 台座の上のレンズの目と、電波
    return [
        _rect(16, 40, 32, 14, CIRCUIT, rx=3),
        _circle(32, 30, 12, GLASS),
        _circle(32, 30, 4, STEEL, 2),
        _polyline([(10, 18), (6, 26), (10, 34)], GLASS, 2.5),
        _polyline([(54, 18), (58, 26), (54, 34)], GLASS, 2.5),
    ]


def engine():
    # 胴体と吸気のひれ、側面の歯車
    parts = [_rect(8, 24, 36, 28, STEEL, rx=4)]
    for x in (14, 22, 30, 38):
        parts.append(_rect(x - 2, 14, 4, 10, STEEL, rx=1, width=2.5))
    parts += gear(COPPER, cx=48, cy=40, r_out=12, r_in=9, teeth=6, hole=3)
    return parts


def probe():
    # 本体と左右の太陽電池板、アンテナ
    return [
        _polyline([(32, 18), (32, 8)], STEEL, 3),
        _circle(32, 7, 3, STEEL, 2),
        _rect(4, 26, 16, 14, GLASS, rx=1),
        _rect(44, 26, 16, 14, GLASS, rx=1),
        _polyline([(20, 33), (24, 33)], STEEL, 3),
        _polyline([(40, 33), (44, 33)], STEEL, 3),
        _rect(24, 20, 16, 26, IRON, rx=3),
        _circle(32, 52, 5, COPPER, 2.5),
    ]


ICONS = {
    "iron_ore": lambda: ore(IRON),
    "copper_ore": lambda: ore(COPPER),
    "coal": lambda: ore(COAL),
    "sand": lambda: sand_pile(SAND),
    "limestone": lambda: ore(LIMESTONE),
    "quicklime": lambda: powder(QUICKLIME),
    "concrete": lambda: block(CONCRETE),
    "iron_ingot": lambda: ingot(IRON),
    "copper_ingot": lambda: ingot(COPPER),
    "glass": lambda: glass(GLASS),
    "steel": lambda: ingot(STEEL),
    "iron_plate": lambda: plate(IRON),
    "screw": lambda: screw(IRON),
    "copper_wire": lambda: wire(COPPER),
    "steel_beam": lambda: beam(STEEL),
    "lens": lambda: lens(GLASS),
    "gear": lambda: gear(IRON),
    "circuit": lambda: chip(CIRCUIT),
    "motor": motor,
    "frame": lambda: frame(STEEL),
    "sensor": sensor,
    "engine": engine,
    "probe": probe,
}


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for item_id, build in ICONS.items():
        body = "\n  ".join(build())
        svg = (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
            f'viewBox="0 0 {SIZE} {SIZE}">\n  {body}\n</svg>\n'
        )
        with open(os.path.join(OUT_DIR, f"{item_id}.svg"), "w", encoding="utf-8", newline="\n") as f:
            f.write(svg)
    print(f"wrote {len(ICONS)} icons to {os.path.normpath(OUT_DIR)}")


if __name__ == "__main__":
    main()
