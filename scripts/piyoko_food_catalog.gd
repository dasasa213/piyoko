class_name PiyokoFoodCatalog
extends RefCounted

const DATA_PATH := "res://data/foods.json"
const STATUSES := ["hunger", "friendship", "mood"]

static var _foods: Dictionary = {}
static var _ordered_ids: Array[String] = []


static func get_ordered_ids() -> Array[String]:
	_ensure_loaded()
	return _ordered_ids.duplicate()


static func get_food(food_id: String) -> Dictionary:
	_ensure_loaded()
	return (_foods.get(food_id, {}) as Dictionary).duplicate(true)


static func has_food(food_id: String) -> bool:
	_ensure_loaded()
	return _foods.has(food_id)


static func validate() -> bool:
	_ensure_loaded()
	var valid := not _ordered_ids.is_empty()
	for food_id in _ordered_ids:
		var food: Dictionary = _foods[food_id]
		var image_path := str(food.get("image", ""))
		if image_path.is_empty() or not ResourceLoader.exists(image_path):
			push_error("食べ物画像が見つかりません: %s (%s)" % [food_id, image_path])
			valid = false
		var effects = food.get("effects", {})
		if typeof(effects) != TYPE_DICTIONARY:
			push_error("食べ物効果が不正です: %s" % food_id)
			valid = false
			continue
		for status in (effects as Dictionary):
			if str(status) not in STATUSES:
				push_error("未対応の食べ物効果です: %s (%s)" % [food_id, status])
				valid = false
	return valid


static func _ensure_loaded() -> void:
	if not _ordered_ids.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("食べ物定義を読み込めません: %s" % DATA_PATH)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("食べ物定義JSONが不正です: %s" % json.get_error_message())
		return
	var raw_foods = (json.data as Dictionary).get("foods", [])
	if typeof(raw_foods) != TYPE_ARRAY:
		push_error("食べ物定義のfoodsが配列ではありません")
		return
	var definitions: Array[Dictionary] = []
	for raw_food in raw_foods:
		if typeof(raw_food) == TYPE_DICTIONARY:
			definitions.append((raw_food as Dictionary).duplicate(true))
	definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	for food in definitions:
		var food_id := str(food.get("id", ""))
		if food_id.is_empty() or _foods.has(food_id):
			push_error("食べ物IDが空、または重複しています: %s" % food_id)
			continue
		_foods[food_id] = food
		_ordered_ids.append(food_id)
