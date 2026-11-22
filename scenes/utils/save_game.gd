class_name SaveGame
extends RefCounted

## ゲームの進行状況を Dictionary（JSON にできる形）へ取り出し、そこから復元する。
## 保存するのは「配置」と「進行度」: 惑星のシード、訪れた chunk の鉱床とピース、
## 所有している chunk、キャラクターの立っている場所、ハブ目標の進み具合、ハブに貯めた在庫、研究、チェストの共有倉庫の中身。
## ベルト上や機械の中にあるアイテムは保存しない（ロード後は空の状態から動き出す）。

const VERSION := 1
const DEFAULT_PATH := "user://save.json"
# 名前を変えたピース {旧シーン: 新シーン}。旧セーブを読み込むときに読み替える
const RENAMED_SCENES := {
	"res://scenes/components/piece/sender.tscn": "res://scenes/components/piece/bridge.tscn",
}
# 廃止したピース。旧セーブにあっても置かない（Receiver は橋が直接受け取り先へ渡すので不要）
const RETIRED_SCENES := [
	"res://scenes/components/piece/receiver.tscn",
	"res://scenes/components/piece/painter.tscn",
]

# 実際に読み書きするファイル。テストや動作確認ツールが本物のセーブを触らないよう差し替えられる。
static var path: String = DEFAULT_PATH


static func capture(world: World, goals: Node, active_hex = null) -> Dictionary:
	var data := {
		"version": VERSION,
		"hub_goals":
		{
			"level": goals.level,
			"rewards": goals.gained_rewards.keys(),
			"stock": goals.stock.duplicate(),
			"researched": goals.researched.keys(),
		},
		"chunks": [],
		"planet_storage": world.planet_storage.get_contents(),
		"region_storages": world.get_region_storage_contents(),
	}
	var planet = world.get_planet()
	if planet:
		data["planet"] = {"radius": planet.radius, "seed": planet.seed_value}
	var active = active_hex if active_hex != null else world.get_active_hex()
	if active != null:
		data["active_chunk"] = _hex_to_array(active)
	for chunk_hex in world.get_chunk_hexes():
		data["chunks"].append(_capture_chunk(chunk_hex, world.get_chunk(chunk_hex)))
	data["owned_chunks"] = world.territory.get_owned_hexes().map(_hex_to_array)
	if world.player:
		data["player"] = {
			"chunk": _hex_to_array(world.player.chunk_hex),
			"hex": _hex_to_array(world.player.hex),
			"position": [world.player.position.x, world.player.position.y],
		}
	return data


# まだ chunk を持たない world に data の内容を復元する
static func apply(world: World, data: Dictionary, goals: Node) -> void:
	var hub_goals: Dictionary = data.get("hub_goals", {})
	goals.level = int(hub_goals.get("level", 1))
	goals.gained_rewards = {}
	for reward in hub_goals.get("rewards", []):
		goals.gained_rewards[reward] = true
	# 到達済みのレベルの報酬は必ず解放済みにする
	# （機械の解放が研究だった頃のセーブデータでも、機械が使えなくならないように）
	for i in mini(goals.level - 1, goals.LEVELS.size()):
		var reward: String = goals.LEVELS[i]["reward"]
		if reward != "":
			goals.gained_rewards[reward] = true
	goals.researched = {}
	for id in hub_goals.get("researched", []):
		goals.researched[id] = true
	goals.stock = {}
	var saved_stock: Dictionary = hub_goals.get("stock", {})
	for item_id in saved_stock:
		goals.stock[item_id] = int(saved_stock[item_id])
	if data.has("planet"):
		var planet: Dictionary = data["planet"]
		world.setup_planet(Planet.new(int(planet["radius"]), int(planet["seed"])))
	world.planet_storage.load_contents(data.get("planet_storage", {}))
	var region_storages: Dictionary = data.get("region_storages", {})
	for region_id in region_storages:
		# JSON を経るとキーは文字列になる
		world.get_region_storage(int(region_id)).load_contents(region_storages[region_id])
	for chunk_data in data.get("chunks", []):
		_apply_chunk(world, chunk_data, goals)
	# 所有の仕組みが無かった頃のセーブでは、それまでに見えていた chunk をすべて所有とする
	var owned: Array = data.get("owned_chunks", world.get_chunk_hexes().map(_hex_to_array))
	for values in owned:
		world.territory.claim(_array_to_hex(values))
	if data.has("active_chunk"):
		world.set_active_chunk(_array_to_hex(data["active_chunk"]))
	# キャラクターの記録が無い旧セーブでは置かない（呼び出し側がハブの隣に立たせる）
	if data.has("player"):
		var player: Dictionary = data["player"]
		world.place_player(_array_to_hex(player["chunk"]), _array_to_hex(player["hex"]))
		# マスの中の細かい位置（無い旧セーブではマスの中心）
		if player.has("position"):
			var values: Array = player["position"]
			world.move_player_to(Vector2(float(values[0]), float(values[1])))


static func exists(file_path: String = path) -> bool:
	return FileAccess.file_exists(file_path)


static func write(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


# 読めない・壊れているファイルは空の Dictionary を返す
static func read(file_path: String = path) -> Dictionary:
	if not exists(file_path):
		return {}
	var json = JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	return json.data if json.data is Dictionary else {}


static func delete(file_path: String = path) -> void:
	if exists(file_path):
		DirAccess.remove_absolute(file_path)


static func _capture_chunk(chunk_hex: Vector2i, chunk: Chunk) -> Dictionary:
	var resources := []
	for hex in chunk.get_all_hexes():
		var resource_type = chunk.get_hex_resource(hex)
		if resource_type != "":
			resources.append([hex.x, hex.y, resource_type])
	var pieces := []
	for piece in chunk.get_all_pieces():
		pieces.append(_capture_piece(chunk, piece))
	return {
		"hex": _hex_to_array(chunk_hex),
		"grid_radius": chunk.grid_radius,
		"resources": resources,
		"storage": chunk.storage.get_contents(),
		"pieces": pieces,
	}


static func _capture_piece(chunk: Chunk, piece: Piece) -> Dictionary:
	var result := {
		"scene": piece.scene_file_path,
		"hex": _hex_to_array(chunk.get_base_hex(piece)),
		"rotation": piece.rotation_state,
		"input_direction": piece.input_direction,
	}
	var hub = piece.hub
	if hub:
		result["received"] = hub.received_count
	var chest_output = piece.chest_output
	if chest_output:
		result["chest_item"] = chest_output.selected_item
	return result


static func _apply_chunk(world: World, chunk_data: Dictionary, goals: Node) -> void:
	# 鉱床は保存された配置を使うので、生成時のランダム配置は行わない
	var chunk = world.create_chunk(_array_to_hex(chunk_data["hex"]), false)
	var grid_radius = int(chunk_data.get("grid_radius", chunk.grid_radius))
	if grid_radius != chunk.grid_radius:
		chunk.create_hex_grid(grid_radius)
	chunk.storage.load_contents(chunk_data.get("storage", {}))
	# Miner は設置時に足元の鉱床を見るため、ピースより先に鉱床を戻す
	for entry in chunk_data.get("resources", []):
		chunk.mark_resource_hex(Vector2i(int(entry[0]), int(entry[1])), entry[2])
	for piece_data in chunk_data.get("pieces", []):
		_apply_piece(chunk, piece_data, goals)


static func _apply_piece(chunk: Chunk, piece_data: Dictionary, goals: Node) -> void:
	var scene_path: String = RENAMED_SCENES.get(piece_data["scene"], piece_data["scene"])
	if scene_path in RETIRED_SCENES or not ResourceLoader.exists(scene_path):
		return
	var scene = load(scene_path)
	if scene == null:
		return
	var hex = _array_to_hex(piece_data["hex"])
	chunk.place_piece(
		scene, hex, int(piece_data.get("rotation", 0)), int(piece_data.get("input_direction", -1))
	)
	var piece = chunk.get_piece_at_hex(hex)
	var chest_output = piece.chest_output
	if chest_output:
		chest_output.selected_item = piece_data.get("chest_item", "")
	var hub = piece.hub
	if hub:
		var goal = goals.get_current_goal()
		hub.setup(goal["goal_item"], goal["required"])
		hub.received_count = int(piece_data.get("received", 0))
		hub.refresh_display()


static func _hex_to_array(hex: Vector2i) -> Array:
	return [hex.x, hex.y]


static func _array_to_hex(values: Array) -> Vector2i:
	return Vector2i(int(values[0]), int(values[1]))
