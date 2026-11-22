"""hex_world.py の集計のテスト。

    python tools/research/test_hex_world.py
"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import hex_world  # noqa: E402

DATA = {
    "items": [
        {"id": "ore", "name": "Ore"},
        {"id": "coal", "name": "Coal"},
        {"id": "ingot", "name": "Ingot"},
        {"id": "steel", "name": "Steel"},
        {"id": "beam", "name": "Beam"},
        {"id": "junk", "name": "Junk"},
    ],
    "biomes": [
        {"id": "plains", "name": "平原", "resource": "ore"},
        {"id": "forest", "name": "森林", "resource": "coal"},
    ],
    "recipes": [
        {"machine": "miner", "inputs": {}, "outputs": {"ore": 1}, "time": 1.0},
        {"machine": "miner", "inputs": {}, "outputs": {"coal": 1}, "time": 1.0},
        {"machine": "smelter", "inputs": {"ore": 1}, "outputs": {"ingot": 1}, "time": 2.0},
        {"machine": "mixer", "inputs": {"ingot": 1, "coal": 1}, "outputs": {"steel": 1}, "time": 4.0},
        {"machine": "cutter", "inputs": {"steel": 1}, "outputs": {"beam": 1}, "time": 4.0},
        {"machine": "cutter", "inputs": {"ingot": 2}, "outputs": {"junk": 1}, "time": 1.0},
    ],
    "research": [
        {"id": "a", "name": "A", "cost": {"ingot": 5}, "level": 2, "requires": [], "effect": {}},
        {"id": "b", "name": "B", "cost": {"steel": 5}, "level": 3, "requires": ["a"], "effect": {}},
        {"id": "c", "name": "C", "cost": {"beam": 5}, "level": 4, "requires": ["b"], "effect": {}},
    ],
    "levels": [
        {"level": 1, "goal_item": "ore", "required": 10, "reward": "x"},
        {"level": 2, "goal_item": "steel", "required": 20, "reward": ""},
    ],
    "build_costs": [{"piece": "smelter_t1", "cost": {"ore": 5}}],
}


class TestHexWorld(unittest.TestCase):
    def setUp(self):
        self.g = hex_world.Game(DATA)

    def test_原料の段階は0で_加工するたびに1段上がる(self):
        self.assertEqual(self.g.tiers["ore"], 0)
        self.assertEqual(self.g.tiers["ingot"], 1)
        self.assertEqual(self.g.tiers["steel"], 2)
        self.assertEqual(self.g.tiers["beam"], 3)

    def test_アイテムに要るバイオームを原料からたどる(self):
        self.assertEqual(self.g.biomes_of("ingot"), ["平原"])
        self.assertEqual(self.g.biomes_of("beam"), ["平原", "森林"])

    def test_アイテムの使い道を設置_研究_目標_材料に分けて集める(self):
        self.assertEqual(self.g.uses("ore"), {"材料": 1, "目標": 1, "設置": 1})
        self.assertEqual(self.g.uses("beam"), {"研究": 1})
        self.assertEqual(self.g.uses("junk"), {})

    def test_研究の深さは前提の鎖の長さ(self):
        self.assertEqual(self.g.research_depth("a"), 1)
        self.assertEqual(self.g.research_depth("c"), 3)

    def test_加工のレシピだけで入力数を数える(self):
        self.assertEqual(self.g.input_count_distribution(), {1: 3, 2: 1})


if __name__ == "__main__":
    unittest.main()
