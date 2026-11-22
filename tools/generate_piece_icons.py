"""ツールバーのピースとジャンルのアイコン（記号的な線画の SVG）を assets/pieces/ に作る。

    python tools/generate_piece_icons.py

方針（docs/ の参考画像に寄せる）:
- 暗い六角形のボタンの上に載せるので、明るい色1色の線だけで描く（塗り・陰影・グラデーションなし）
- 線の太さと角の丸めをそろえ、形だけで何の施設か分かるようにする
"""

import math
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "pieces")
SIZE = 64
STROKE = 4.5
COLOR = "#e8eef5"
STYLE = (
    f'fill="none" stroke="{COLOR}" stroke-width="{STROKE}" '
    'stroke-linejoin="round" stroke-linecap="round"'
)


def _svg(*shapes):
    body = "\n".join(f"  {s}" for s in shapes)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
        f'viewBox="0 0 {SIZE} {SIZE}">\n{body}\n</svg>\n'
    )


def path(d):
    return f'<path d="{d}" {STYLE}/>'


def circle(cx, cy, r):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" {STYLE}/>'


def _gear_path(cx, cy, outer, inner, teeth):
    points = []
    step = math.tau / (teeth * 4)
    for i in range(teeth * 4):
        r = outer if i % 4 in (1, 2) else inner
        a = step * i - math.pi / 2
        points.append(f"{cx + r * math.cos(a):.1f},{cy + r * math.sin(a):.1f}")
    return "M" + " L".join(points) + " Z"


ICONS = {
    # --- ピース ---
    # 流れる向きを示す山形を2つ
    "conveyor": _svg(path("M14 18 L28 32 L14 46"), path("M32 18 L46 32 L32 46")),
    # 溝をまたぐ橋: 橋げたとアーチ
    "bridge": _svg(path("M6 24 L58 24"), path("M12 46 Q32 20 52 46"), path("M12 24 L12 48 M52 24 L52 48")),
    # つるはし
    "miner": _svg(path("M14 22 Q32 6 50 22"), path("M32 14 L20 52")),
    # 炎
    "smelter": _svg(
        path("M32 8 C42 20 48 28 48 38 A16 16 0 0 1 16 38 C16 30 21 24 25 18 C27 26 30 29 33 29 C35 22 34 15 32 8 Z")
    ),
    # 歯車
    "assembler": _svg(path(_gear_path(32, 32, 24, 17, 8)), circle(32, 32, 6)),
    # はさみ
    "cutter": _svg(circle(20, 46, 7), circle(44, 46, 7), path("M25 41 L46 10 M39 41 L18 10")),
    # 鉢とかき混ぜ棒
    "mixer": _svg(path("M10 30 L54 30 Q54 54 32 54 Q10 54 10 30 Z"), path("M44 8 L32 38")),
    # ドーム型の窯と焚き口
    "kiln": _svg(path("M10 54 L10 36 A22 22 0 0 1 54 36 L54 54 Z"), path("M24 54 L24 44 A8 8 0 0 1 40 44 L40 54")),
    # 箱へ入れる（下向きの矢印）
    "chest_in": _svg(path("M10 32 L10 56 L54 56 L54 32"), path("M32 6 L32 38 M22 28 L32 38 L42 28")),
    # 箱から出す（上向きの矢印）
    "chest_out": _svg(path("M10 32 L10 56 L54 56 L54 32"), path("M32 40 L32 8 M22 18 L32 8 L42 18")),
    # --- ジャンル ---
    # 物流: 曲がって進む経路
    "category_logistics": _svg(path("M10 54 L10 34 Q10 20 24 20 L52 20"), path("M42 10 L52 20 L42 30")),
    # 採掘: 山
    "category_extraction": _svg(path("M4 52 L24 18 L36 38 L44 26 L60 52 Z")),
    # 加工: のこぎり屋根の工場と煙突
    "category_processing": _svg(path("M8 54 L8 30 L20 38 L20 30 L32 38 L32 30 L44 38 L44 12 L54 12 L54 54 Z")),
    # 倉庫: ふた付きの箱
    "category_storage": _svg(path("M8 14 L56 14 L56 26 L8 26 Z"), path("M12 26 L12 54 L52 54 L52 26"), path("M26 36 L38 36")),
}


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, svg in ICONS.items():
        with open(os.path.join(OUT_DIR, f"{name}.svg"), "w", encoding="utf-8") as f:
            f.write(svg)
    print(f"wrote {len(ICONS)} icons to {os.path.normpath(OUT_DIR)}")


if __name__ == "__main__":
    main()
