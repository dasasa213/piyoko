class_name PiyokoEconomyManager
extends RefCounted

## 通貨・消費アイテム・将来の恒久解放を、育成中データとは分離して管理する。

const ECONOMY_PATH := "user://piyoko_economy.json"
const DATA_VERSION := 1
const INITIAL_COINS := 50
const MAX_COINS := 99999

static func default_data() -> Dictionary:
	return {
		"data_version": DATA_VERSION,
		"coins": INITIAL_COINS,
		"inventory": {},
		"unlocks": {},
	}


static func load_data() -> Dictionary:
	if not FileAccess.file_exists(ECONOMY_PATH):
		return default_data()
	var file := FileAccess.open(ECONOMY_PATH, FileAccess.READ)
	if file == null:
		return default_data()
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return default_data()
	var data: Dictionary = json.data as Dictionary
	data["coins"] = clampi(int(data.get("coins", INITIAL_COINS)), 0, MAX_COINS)
	if typeof(data.get("inventory", {})) != TYPE_DICTIONARY:
		data["inventory"] = {}
	if typeof(data.get("unlocks", {})) != TYPE_DICTIONARY:
		data["unlocks"] = {}
	return data


static func save_data(data: Dictionary) -> bool:
	data["data_version"] = DATA_VERSION
	data["coins"] = clampi(int(data.get("coins", INITIAL_COINS)), 0, MAX_COINS)
	var file := FileAccess.open(ECONOMY_PATH, FileAccess.WRITE)
	if file == null:
		push_error("おかね・もちものデータを保存できませんでした")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


static func add_coins(amount: int) -> int:
	var data := load_data()
	var before := int(data["coins"])
	data["coins"] = clampi(before + amount, 0, MAX_COINS)
	if not save_data(data):
		return 0
	return int(data["coins"]) - before


static func buy(item_id: String) -> bool:
	if not PiyokoItemCatalog.has_item(item_id):
		return false
	var data := load_data()
	var price := int(PiyokoItemCatalog.get_item(item_id).get("price", 0))
	if int(data["coins"]) < price:
		return false
	data["coins"] = int(data["coins"]) - price
	var inventory: Dictionary = data["inventory"]
	inventory[item_id] = int(inventory.get(item_id, 0)) + 1
	return save_data(data)


static func consume(item_id: String) -> bool:
	var data := load_data()
	var inventory: Dictionary = data["inventory"]
	var count := int(inventory.get(item_id, 0))
	if count <= 0:
		return false
	inventory[item_id] = count - 1
	return save_data(data)


static func get_count(item_id: String) -> int:
	return int((load_data()["inventory"] as Dictionary).get(item_id, 0))


static func delete_all() -> bool:
	if not FileAccess.file_exists(ECONOMY_PATH):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(ECONOMY_PATH)) == OK
