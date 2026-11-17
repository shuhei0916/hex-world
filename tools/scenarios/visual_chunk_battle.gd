extends RefCounted

# 見た目確認用。環境変数 BATTLE_VIEW で場面を選ぶ:
#   map（既定）: 新しいゲームのワールドマップ（所有・戦って解放できる隣・霧）
#   battle: 東隣の chunk の上で戦闘を始め、歩くスキルを選んだところ
#   intent: その戦闘で、敵にマウスを乗せて予定を出したところ
#   result: その戦闘に勝った結果の表示
#   built: 勝って結果を閉じたあと（同じ画面のまま建築できる状態）


func run(scene: Node) -> void:
	var view_name = OS.get_environment("BATTLE_VIEW")
	scene._enter_world_map_mode()
	scene.world_map_view.set_hovered_chunk(Hex.new(1, 0))
	if view_name not in ["battle", "intent", "result", "built"]:
		return
	scene.select_world_map_chunk(Hex.new(1, 0))
	var battle_scene: BattleScene = scene.battle_overlay.battle_scene
	battle_scene.animations_enabled = false
	if view_name == "battle":
		battle_scene.select_skill(battle_scene.skill_turn.skills[0])
		return
	if view_name == "intent":
		battle_scene.hover_hex(battle_scene.battle.enemies()[0].position)
		return
	for enemy in battle_scene.battle.enemies():
		battle_scene.battle.field.remove_unit(enemy)
	battle_scene.refresh()
	if view_name == "built":
		scene.battle_overlay.confirm_result()
