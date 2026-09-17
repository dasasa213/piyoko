extends Node

## 一度発見したピヨコを育成データとは独立して保存する。
## 育成を終えたり育て直したりしても、図鑑の発見記録は維持される。

const COLLECTION_PATH := "user://piyoko_collection.json"

var discovered: Array[String] = []


func _ready() -> void:
	load_collection()


# ------------------------------------------------------------
# 発見状態
# ------------------------------------------------------------

func discover(piyoko_id: String) -> void:
	if is_discovered(piyoko_id):
		return

	discovered.append(piyoko_id)
	save_collection()

	print("図鑑登録: ", piyoko_id)


func is_discovered(piyoko_id: String) -> bool:
	return piyoko_id in discovered


# ------------------------------------------------------------
# 保存・読み込み
# ------------------------------------------------------------

func save_collection() -> void:
	var file := FileAccess.open(COLLECTION_PATH, FileAccess.WRITE)
	if file == null:
		push_error("図鑑データを保存できませんでした")
		return

	var data := {
		"discovered": discovered
	}

	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_collection() -> void:
	if not FileAccess.file_exists(COLLECTION_PATH):
		discovered.clear()
		return

	var data := _read_collection_data()
	if data.is_empty():
		discovered.clear()
		return

	_apply_collection_data(data)


func _read_collection_data() -> Dictionary:
	var file := FileAccess.open(COLLECTION_PATH, FileAccess.READ)
	if file == null:
		push_error("図鑑データを読み込めませんでした")
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("図鑑データの読み込みに失敗しました")
		return {}

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("図鑑データが不正です")
		return {}

	return json.data as Dictionary


func _apply_collection_data(data: Dictionary) -> void:
	discovered.clear()

	var saved_discovered = data.get("discovered", [])
	if typeof(saved_discovered) != TYPE_ARRAY:
		push_error("図鑑の発見データが不正です")
		return

	for piyoko_id in saved_discovered:
		discovered.append(str(piyoko_id))


# ------------------------------------------------------------
# 完全初期化
# ------------------------------------------------------------

func delete_collection() -> bool:
	discovered.clear()

	if not FileAccess.file_exists(COLLECTION_PATH):
		print("削除する図鑑データはありません")
		return true

	var absolute_path := ProjectSettings.globalize_path(COLLECTION_PATH)
	var error := DirAccess.remove_absolute(absolute_path)

	if error != OK:
		push_error("図鑑データの削除に失敗しました")
		return false

	print("図鑑データを削除しました")
	return true
