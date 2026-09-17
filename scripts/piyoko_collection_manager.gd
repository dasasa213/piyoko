extends Node

const COLLECTION_PATH := "user://piyoko_collection.json"

var discovered: Array[String] = []


func _ready() -> void:
	load_collection()


func discover(piyoko_id: String) -> void:
	if piyoko_id in discovered:
		return

	discovered.append(piyoko_id)
	save_collection()

	print("図鑑登録: ", piyoko_id)


func is_discovered(piyoko_id: String) -> bool:
	return piyoko_id in discovered


func save_collection() -> void:
	var file := FileAccess.open(
		COLLECTION_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error("図鑑データを保存できませんでした")
		return

	var data := {
		"discovered": discovered
	}

	file.store_string(
		JSON.stringify(data)
	)


func load_collection() -> void:
	if not FileAccess.file_exists(COLLECTION_PATH):
		discovered = []
		return

	var file := FileAccess.open(
		COLLECTION_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("図鑑データを読み込めませんでした")
		return

	var json = JSON.parse_string(
		file.get_as_text()
	)

	if typeof(json) != TYPE_DICTIONARY:
		push_error("図鑑データが不正です")
		discovered = []
		return

	discovered.clear()

	for piyoko_id in json.get("discovered", []):
		discovered.append(str(piyoko_id))
