extends RefCounted
## 設置済みピースにマウスを乗せたときの情報パネルの内容を出力する。
##
## 配置（アクティブチャンク）: 鉱床の上に Miner（搬出先なし）、離れた場所に Smelter（材料なし）と
## 行き止まりのコンベア。5秒動かしてから、それぞれとハブにホバーする。

const CONVEYOR = preload("res://scenes/components/piece/conveyor.tscn")
const MINER = preload("res://scenes/components/piece/miner_t1.tscn")
const SMELTER = preload("res://scenes/components/piece/smelter_t1.tscn")


func run(scene: Node) -> void:
	var chunk: Chunk = scene.world.get_active_chunk()
	var targets := {"Hub": Hex.new(0, 0)}
	for hex in chunk.get_all_hexes():
		if chunk.get_hex_resource(hex) != "" and chunk.can_place([Hex.new(0, 0)], hex):
			chunk.place_piece(MINER, hex)
			targets["Miner"] = hex
			break
	for entry in [["Smelter", SMELTER], ["Conveyor", CONVEYOR]]:
		for hex in chunk.get_outer_hexes():
			if chunk.get_piece_at_hex(hex) == null and chunk.get_hex_resource(hex) == "":
				chunk.place_piece(entry[1], hex)
				targets[entry[0]] = hex
				break
	await scene.get_tree().create_timer(5.0).timeout
	for label in targets:
		scene._hover_local(chunk.hex_to_pixel(targets[label]))
		_report(label, scene)
	scene._hover_local(Vector2(99999, 99999))
	_report("何も無い場所", scene)


func _report(label: String, scene: Node) -> void:
	var panel = scene.hud.info_panel
	if not panel.visible:
		print("[%s] パネル非表示" % label)
		return
	print(
		(
			"[%s] 名前=%s / 本文=%s / 速度=%s"
			% [
				label,
				panel.name_label.text,
				panel.description_label.text.replace("\n", " | "),
				panel.rate_label.text if panel.rate_label.visible else "(非表示)"
			]
		)
	)
