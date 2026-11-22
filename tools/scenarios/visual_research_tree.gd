extends RefCounted

## 見た目確認用。研究ツリーの画面を開いて映す。ハブ Lv5 まで進め、
## コンベア高速化 I・採掘高速化 I を研究済み、鉄板を少し持った状態（研究済み・研究できる・在庫不足・未解放が混ざる）

const FLOW = preload("res://tools/scenarios/research_flow.gd")


func run(scene: Node) -> void:
	HubGoals.level = 5
	HubGoals.level_up.emit(5, "")
	for item_id in ["iron_ore", "iron_ingot"]:
		HubGoals.add_stock(item_id, 20)
	HubGoals.research("mining_speed_1")
	HubGoals.research("belt_speed_1")
	HubGoals.add_stock("iron_plate", 25)
	scene._handle_key_input(FLOW.new()._key(KEY_E))
	for i in 5:
		await scene.get_tree().process_frame
