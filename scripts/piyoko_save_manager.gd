class_name PiyokoSaveManager
extends RefCounted

## 現在育成中のピヨコのセーブデータを管理する。
## 図鑑データは PiyokoCollectionManager が別ファイルで管理する。

const SAVE_PATH := "user://piyoko_save.json"
const SAVE_VERSION := 1


# ------------------------------------------------------------
# 保存
# ------------------------------------------------------------

static func save(piyoko: Piyoko) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("セーブファイルを開けませんでした")
		return false

	var save_data := _create_save_data(piyoko)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	print("セーブしました")
	return true


static func _create_save_data(piyoko: Piyoko) -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"total_care_count": piyoko.total_care_count,
		"growth_stage": piyoko.growth_stage,
		"growth_count": piyoko.growth_count,
		"child_type": piyoko.child_type,
		"adult_type": piyoko.adult_type,
		"hunger": piyoko.hunger,
		"friendship": piyoko.friendship,
		"mood": piyoko.mood,
		"food_count": piyoko.food_count,
		"shortcake_count": piyoko.shortcake_count,
		"onigiri_count": piyoko.onigiri_count,
		"broccoli_count": piyoko.broccoli_count,
		"pet_count": piyoko.pet_count,
		"play_count": piyoko.play_count,
		"play_success_count": piyoko.play_success_count,
		"play_failure_count": piyoko.play_failure_count,
		"last_care": piyoko.last_care
	}


# ------------------------------------------------------------
# 読み込み
# ------------------------------------------------------------

static func load_save(piyoko: Piyoko) -> bool:
	if not has_save():
		print("セーブデータなし：新しいピヨコを開始します")
		return false

	var data := _read_save_data()
	if data.is_empty():
		return false

	_apply_save_data(piyoko, data)

	print("ロードしました")
	return true


static func _read_save_data() -> Dictionary:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("セーブファイルを開けませんでした")
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("セーブデータの読み込みに失敗しました")
		return {}

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("セーブデータの形式が不正です")
		return {}

	return json.data as Dictionary


static func _apply_save_data(piyoko: Piyoko, data: Dictionary) -> void:
	piyoko.total_care_count = int(data.get("total_care_count", piyoko.total_care_count))
	piyoko.growth_stage = int(data.get("growth_stage", piyoko.growth_stage))
	piyoko.growth_count = int(data.get("growth_count", piyoko.growth_count))

	piyoko.child_type = str(data.get("child_type", piyoko.child_type))
	piyoko.adult_type = str(data.get("adult_type", piyoko.adult_type))

	piyoko.hunger = int(data.get("hunger", piyoko.hunger))
	piyoko.friendship = int(data.get("friendship", piyoko.friendship))
	piyoko.mood = int(data.get("mood", piyoko.mood))

	piyoko.shortcake_count = int(data.get("shortcake_count", piyoko.shortcake_count))
	piyoko.onigiri_count = int(data.get("onigiri_count", piyoko.onigiri_count))
	piyoko.broccoli_count = int(data.get("broccoli_count", piyoko.broccoli_count))
	piyoko.food_count = _load_food_count(data, piyoko)

	piyoko.pet_count = int(data.get("pet_count", piyoko.pet_count))
	piyoko.play_count = int(data.get("play_count", piyoko.play_count))
	piyoko.play_success_count = int(data.get("play_success_count", piyoko.play_success_count))
	piyoko.play_failure_count = int(data.get("play_failure_count", piyoko.play_failure_count))

	piyoko.last_care = str(data.get("last_care", piyoko.last_care))


# 旧セーブには food_count が存在しないため、食べ物ごとの回数から復元する。
static func _load_food_count(data: Dictionary, piyoko: Piyoko) -> int:
	if data.has("food_count"):
		return int(data["food_count"])

	return (
		int(data.get("shortcake_count", piyoko.shortcake_count))
		+ int(data.get("onigiri_count", piyoko.onigiri_count))
		+ int(data.get("broccoli_count", piyoko.broccoli_count))
	)


# ------------------------------------------------------------
# セーブデータの有無・削除
# ------------------------------------------------------------

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func delete_save() -> bool:
	if not has_save():
		print("削除するセーブデータはありません")
		return true

	var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
	var error := DirAccess.remove_absolute(absolute_path)

	if error != OK:
		push_error("セーブデータの削除に失敗しました")
		return false

	print("セーブデータを削除しました")
	return true
