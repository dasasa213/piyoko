class_name PiyokoItemCatalog
extends RefCounted

const DATA_PATH := "res://data/shop_items.json"
const SUPPORTED_EFFECTS := ["status_change"]

static var _items: Dictionary = {}
static var _ordered_ids: Array[String] = []


static func get_items() -> Dictionary:
	_ensure_loaded()
	return _items


static func get_ordered_ids() -> Array[String]:
	_ensure_loaded()
	return _ordered_ids


static func get_item(item_id: String) -> Dictionary:
	_ensure_loaded()
	return (_items.get(item_id, {}) as Dictionary).duplicate(true)


static func has_item(item_id: String) -> bool:
	_ensure_loaded()
	return _items.has(item_id)


static func validate() -> bool:
	_ensure_loaded()
	var valid := true
	for item_id in _ordered_ids:
		var item: Dictionary = _items[item_id]
		if int(item.get("price", -1)) < 0:
			push_error("アイテム価格が不正です: %s" % item_id)
			valid = false
		for effect in item.get("effects", []):
			if str(effect.get("type", "")) not in SUPPORTED_EFFECTS:
				push_error("未対応のアイテム効果です: %s" % effect.get("type", ""))
				valid = false
	return valid


static func _ensure_loaded() -> void:
	if not _ordered_ids.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("アイテム定義を読み込めません: %s" % DATA_PATH)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("アイテム定義JSONが不正です: %s" % json.get_error_message())
		return
	var raw_items = (json.data as Dictionary).get("items", [])
	if typeof(raw_items) != TYPE_ARRAY:
		push_error("アイテム定義のitemsが配列ではありません")
		return
	for raw_item in raw_items:
		if typeof(raw_item) == TYPE_DICTIONARY:
			var item: Dictionary = (raw_item as Dictionary).duplicate(true)
			var item_id := str(item.get("id", ""))
			if item_id.is_empty() or _items.has(item_id):
				push_error("アイテムIDが空、または重複しています: %s" % item_id)
				continue
			_items[item_id] = item
			_ordered_ids.append(item_id)
