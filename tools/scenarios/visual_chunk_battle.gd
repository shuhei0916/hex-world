extends RefCounted

# 見た目確認用。環境変数 BATTLE_VIEW で場面を選ぶ:
#   map（既定）: 新しいゲームのワールドマップ（所有・戦って解放できる隣・霧）
#   battle: 東隣の chunk の戦闘を開き、移動カードを選んだところ
#   result: その戦闘に勝った結果の表示


func run(scene: Node) -> void:
	var view_name = OS.get_environment("BATTLE_VIEW")
	scene._enter_world_map_mode()
	scene.world_map_view.set_hovered_chunk(Hex.new(1, 0))
	if view_name not in ["battle", "result"]:
		return
	scene.select_world_map_chunk(Hex.new(1, 0))
	var battle_scene: BattleScene = scene.battle_overlay.battle_scene
	battle_scene.animations_enabled = false
	if view_name == "battle":
		for card in battle_scene.card_turn.deck.hand:
			if card.kind == Card.Kind.MOVE:
				battle_scene.select_card(card)
				break
		return
	for enemy in battle_scene.battle.enemies():
		battle_scene.battle.field.remove_unit(enemy)
	battle_scene.refresh()
