extends RefCounted

## ゲームのデータを JSON に書き出す。書き出し先は環境変数 EXPORT_PATH（絶対パス）。
## 集計は tools/research/hex_world.py が行う（使い方はそちらの冒頭）。


func run(_scene: Node) -> void:
	var path := OS.get_environment("EXPORT_PATH")
	if path == "":
		print("EXPORT_PATH が設定されていない")
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(GameDataExport.to_dict(), "\t"))
	file.close()
	print("書き出した: ", path)
