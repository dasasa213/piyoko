class_name PiyokoMemoryManager
extends RefCounted

## 育成を終えた1羽ごとの記録を、現在の育成セーブ・図鑑とは分離して保存する。

const MEMORIES_PATH := "user://piyoko_memories.json"
const DATA_VERSION := 2


static func add_completed_piyoko(piyoko: Piyoko) -> bool:
	if piyoko.growth_stage != 2 or piyoko.adult_type.is_empty():
		push_error("大人ぴよこ以外はおもいでへ登録できません")
		return false

	var records: Array[Dictionary] = load_memories()
	for record in records:
		if str(record.get("source_session_id", "")) == piyoko.session_id:
			# 同じ育成IDは一度だけ保存し、連打や再実行による重複を防ぐ。
			return true

	var next_number: int = 1
	for record in records:
		next_number = maxi(next_number, int(record.get("育成No", 0)) + 1)

	var completed_at: String = Time.get_datetime_string_from_system(false, true)
	records.append({
		"memory_version": DATA_VERSION,
		"育成No": next_number,
		"source_session_id": piyoko.session_id,
		"adult_type": piyoko.adult_type,
		"child_type": piyoko.child_type,
		"started_at": piyoko.started_at,
		"completed_at": completed_at,
		"total_care_count": piyoko.total_care_count,
		"food_count": piyoko.food_count,
		"shortcake_count": piyoko.shortcake_count,
		"onigiri_count": piyoko.onigiri_count,
		"broccoli_count": piyoko.broccoli_count,
		"pet_count": piyoko.pet_count,
		"play_count": piyoko.play_count,
		"play_success_count": piyoko.play_success_count,
		"play_failure_count": piyoko.play_failure_count,
		"help_work_count": piyoko.help_work_count,
		"chibi_help_count": piyoko.chibi_help_count,
		"adult_work_count": piyoko.adult_work_count,
		"earned_coins": piyoko.earned_coins,
		"child_shop_purchase_count": piyoko.child_shop_purchase_count,
		"item_use_count": _sum_item_uses(piyoko.item_use_counts),
		"item_use_counts": piyoko.item_use_counts.duplicate(true),
		"full_hunger_feed_count": piyoko.full_hunger_feed_count,
		"max_play_success_streak": piyoko.max_play_success_streak,
		"play_streak_achieved": piyoko.play_streak_achieved,
		"moon_fragment_used": piyoko.moon_fragment_used,
		"horse_ticket_used": piyoko.horse_ticket_used,
		"rainbow_item_used": piyoko.rainbow_item_used,
		"flower_item_used": piyoko.flower_item_used,
		"lineage": ["chibi", "child_" + piyoko.child_type, "adult_" + piyoko.adult_type],
		"favorite": false
	})
	return _save_memories(records)


static func _sum_item_uses(item_counts: Dictionary) -> int:
	var total := 0
	for value in item_counts.values():
		total += int(value)
	return total


static func load_memories() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if not FileAccess.file_exists(MEMORIES_PATH):
		return records

	var file: FileAccess = FileAccess.open(MEMORIES_PATH, FileAccess.READ)
	if file == null:
		push_error("おもいでデータを読み込めませんでした")
		return records

	var json: JSON = JSON.new()
	var error: Error = json.parse(file.get_as_text())
	file.close()
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("おもいでデータの形式が不正です")
		return records

	var raw_records = (json.data as Dictionary).get("memories", [])
	if typeof(raw_records) != TYPE_ARRAY:
		push_error("おもいで一覧の形式が不正です")
		return records

	for raw_record in raw_records:
		if typeof(raw_record) == TYPE_DICTIONARY:
			var record: Dictionary = (raw_record as Dictionary).duplicate(true)
			_migrate_legacy_record(record)
			records.append(record)
	return records


static func _migrate_legacy_record(record: Dictionary) -> void:
	if str(record.get("adult_type", "")) != "yankee":
		return
	record["adult_type"] = "hana"
	var lineage = record.get("lineage", [])
	if typeof(lineage) == TYPE_ARRAY:
		for index in range(lineage.size()):
			if str(lineage[index]) == "adult_yankee":
				lineage[index] = "adult_hana"


static func get_memory(memory_number: int) -> Dictionary:
	for record in load_memories():
		if int(record.get("育成No", 0)) == memory_number:
			return record
	return {}


static func set_favorite(memory_number: int, favorite: bool) -> bool:
	var records: Array[Dictionary] = load_memories()
	var found: bool = false
	for record in records:
		if int(record.get("育成No", 0)) == memory_number:
			record["favorite"] = favorite
			found = true
			break
	if not found:
		return false
	return _save_memories(records)


static func delete_all() -> bool:
	if not FileAccess.file_exists(MEMORIES_PATH):
		return true
	var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(MEMORIES_PATH))
	if error != OK:
		push_error("おもいでデータの削除に失敗しました")
		return false
	return true


static func _save_memories(records: Array[Dictionary]) -> bool:
	var file: FileAccess = FileAccess.open(MEMORIES_PATH, FileAccess.WRITE)
	if file == null:
		push_error("おもいでデータを保存できませんでした")
		return false
	file.store_string(JSON.stringify({
		"data_version": DATA_VERSION,
		"memories": records
	}, "\t"))
	file.close()
	return true
