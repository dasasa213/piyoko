class_name PiyokoSaveManager
extends RefCounted


const SAVE_PATH := "user://piyoko_save.json"
const SAVE_VERSION := 1

static func save(piyoko: Piyoko) -> bool:
	var save_data := {
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

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error("セーブファイルを開けませんでした")
		return false

	file.store_string(
		JSON.stringify(save_data, "\t")
	)

	file.close()

	print("セーブしました")
	return true


static func load_save(piyoko: Piyoko) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("セーブデータなし：新しいピヨコを開始します")
		return false

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("セーブファイルを開けませんでした")
		return false

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()

	var error := json.parse(json_text)

	if error != OK:
		push_error("セーブデータの読み込みに失敗しました")
		return false

	var data = json.data

	if typeof(data) != TYPE_DICTIONARY:
		push_error("セーブデータの形式が不正です")
		return false

	_apply_save_data(piyoko, data)

	print("ロードしました")
	return true


static func _apply_save_data(
	piyoko: Piyoko,
	data: Dictionary
) -> void:

	piyoko.total_care_count = int(
		data.get("total_care_count", piyoko.total_care_count)
	)
	
	piyoko.growth_stage = int(
		data.get("growth_stage", piyoko.growth_stage)
	)

	piyoko.growth_count = int(
		data.get("growth_count", piyoko.growth_count)
	)

	piyoko.child_type = str(
		data.get("child_type", piyoko.child_type)
	)

	piyoko.adult_type = str(
		data.get("adult_type", piyoko.adult_type)
	)

	piyoko.hunger = int(
		data.get("hunger", piyoko.hunger)
	)

	piyoko.friendship = int(
		data.get("friendship", piyoko.friendship)
	)

	piyoko.mood = int(
		data.get("mood", piyoko.mood)
	)

	piyoko.food_count = int(
		data.get(
			"food_count",
			int(data.get("shortcake_count", 0)) + int(data.get("onigiri_count", 0)) + int(data.get("broccoli_count", 0))
		)
	)

	piyoko.shortcake_count = int(
		data.get("shortcake_count", piyoko.shortcake_count)
	)

	piyoko.onigiri_count = int(
		data.get("onigiri_count", piyoko.onigiri_count)
	)

	piyoko.broccoli_count = int(
		data.get("broccoli_count", piyoko.broccoli_count)
	)

	piyoko.pet_count = int(
		data.get("pet_count", piyoko.pet_count)
	)

	piyoko.play_count = int(
		data.get("play_count", piyoko.play_count)
	)

	piyoko.play_success_count = int(
		data.get(
			"play_success_count",
			piyoko.play_success_count
		)
	)

	piyoko.play_failure_count = int(
		data.get(
			"play_failure_count",
			piyoko.play_failure_count
		)
	)

	piyoko.last_care = str(
		data.get("last_care", piyoko.last_care)
	)


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func delete_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("削除するセーブデータはありません")
		return true

	var error := DirAccess.remove_absolute(
		ProjectSettings.globalize_path(SAVE_PATH)
	)

	if error != OK:
		push_error("セーブデータの削除に失敗しました")
		return false

	print("セーブデータを削除しました")
	return true
