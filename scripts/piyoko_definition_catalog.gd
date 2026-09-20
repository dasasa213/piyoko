class_name PiyokoDefinitionCatalog
extends RefCounted

const DATA_PATH := "res://data/piyoko_forms.json"
const SUPPORTED_CONDITIONS := [
	"default", "field_min", "field_true", "field_compare", "strict_max",
	"economy_coin_min"
]

static var _forms: Array[Dictionary] = []
static var _by_id: Dictionary = {}


static func get_forms() -> Array[Dictionary]:
	_ensure_loaded()
	return _forms


static func get_form(form_id: String) -> Dictionary:
	_ensure_loaded()
	return (_by_id.get(form_id, {}) as Dictionary).duplicate(true)


static func get_stage_forms(stage: String) -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	for form in _forms:
		if str(form.get("stage", "")) == stage:
			result.append(form.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	return result


static func get_adults_for_lineage(lineage: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for form in get_stage_forms("adult"):
		if str(form.get("lineage", "")) == lineage:
			result.append(form)
	return result


static func get_display_name(form_id: String, fallback: String) -> String:
	return str(get_form(form_id).get("name", fallback))


static func get_texture(form_id: String) -> Texture2D:
	var form := get_form(form_id)
	return _texture_from_form(form, "texture")


static func get_reaction_texture(form_id: String, reaction_name: String) -> Texture2D:
	var form := get_form(form_id)
	return _texture_from_form(form, "reaction_%s" % reaction_name)


static func _texture_from_form(form: Dictionary, texture_key: String) -> Texture2D:
	if form.is_empty():
		return null
	var source := load(str(form.get(texture_key, ""))) as Texture2D
	if source == null:
		return null
	var region = form.get("region", [])
	if typeof(region) != TYPE_ARRAY or (region as Array).size() != 4:
		return source
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(
		float(region[0]), float(region[1]), float(region[2]), float(region[3])
	)
	return atlas


static func validate() -> bool:
	_ensure_loaded()
	var valid := true
	var seen: Dictionary = {}
	for form in _forms:
		var form_id := str(form.get("id", ""))
		if form_id.is_empty() or seen.has(form_id):
			push_error("ピヨコ定義のIDが空、または重複しています: %s" % form_id)
			valid = false
		seen[form_id] = true
		var texture_path := str(form.get("texture", ""))
		if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
			push_error("ピヨコ画像が見つかりません: %s (%s)" % [form_id, texture_path])
			valid = false
		var evolution = form.get("evolution", {})
		if typeof(evolution) == TYPE_DICTIONARY:
			for condition in (evolution as Dictionary).get("conditions", []):
				if str(condition.get("type", "")) not in SUPPORTED_CONDITIONS:
					push_error("未対応の進化条件です: %s" % condition.get("type", ""))
					valid = false
	return valid


static func _ensure_loaded() -> void:
	if not _forms.is_empty():
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("ピヨコ定義を読み込めません: %s" % DATA_PATH)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("ピヨコ定義JSONが不正です: %s" % json.get_error_message())
		return
	var raw_forms = (json.data as Dictionary).get("forms", [])
	if typeof(raw_forms) != TYPE_ARRAY:
		push_error("ピヨコ定義のformsが配列ではありません")
		return
	for raw_form in raw_forms:
		if typeof(raw_form) == TYPE_DICTIONARY:
			var form: Dictionary = (raw_form as Dictionary).duplicate(true)
			_forms.append(form)
			_by_id[str(form.get("id", ""))] = form
