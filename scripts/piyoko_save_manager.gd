class_name PiyokoSaveManager
extends RefCounted

## 現在育成中のピヨコのセーブデータを管理する。
## 図鑑データは PiyokoCollectionManager が別ファイルで管理する。

const SAVE_PATH := "user://piyoko_save.json"
const SAVE_VERSION := 4


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
		"session_id": piyoko.session_id,
		"started_at": piyoko.started_at,
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
		"help_work_count": piyoko.help_work_count,
		"chibi_help_count": piyoko.chibi_help_count,
		"adult_work_count": piyoko.adult_work_count,
		"earned_coins": piyoko.earned_coins,
		"child_shop_purchase_count": piyoko.child_shop_purchase_count,
		"full_hunger_feed_count": piyoko.full_hunger_feed_count,
		"current_play_success_streak": piyoko.current_play_success_streak,
		"max_play_success_streak": piyoko.max_play_success_streak,
		"play_streak_achieved": piyoko.play_streak_achieved,
		"item_use_counts": piyoko.item_use_counts,
		"moon_fragment_used": piyoko.moon_fragment_used,
		"horse_ticket_used": piyoko.horse_ticket_used,
		"rainbow_item_used": piyoko.rainbow_item_used,
		"flower_item_used": piyoko.flower_item_used,
		"pc_parts_used": piyoko.pc_parts_used,
		"poker_chip_used": piyoko.poker_chip_used,
		"adult_food_count": piyoko.adult_food_count,
		"adult_shortcake_count": piyoko.adult_shortcake_count,
		"adult_onigiri_count": piyoko.adult_onigiri_count,
		"adult_broccoli_count": piyoko.adult_broccoli_count,
		"adult_pet_count": piyoko.adult_pet_count,
		"adult_play_success_count": piyoko.adult_play_success_count,
		"adult_play_failure_count": piyoko.adult_play_failure_count,
		"oshimotif_sequence_progress": piyoko.oshimotif_sequence_progress,
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
	piyoko.session_id = str(data.get("session_id", piyoko.session_id))
	piyoko.started_at = str(data.get("started_at", ""))
	piyoko.growth_stage = int(data.get("growth_stage", piyoko.growth_stage))
	piyoko.growth_count = int(data.get("growth_count", piyoko.growth_count))

	piyoko.child_type = str(data.get("child_type", piyoko.child_type))
	piyoko.adult_type = str(data.get("adult_type", piyoko.adult_type))
	if piyoko.adult_type == "yankee":
		# 旧名称の育成途中データは、同じ個体をはなぴよことして引き継ぐ。
		piyoko.adult_type = "hana"
	elif piyoko.adult_type == "suit":
		# 廃止したすーつぴよこは、同じ仕事系統のださぴよことして引き継ぐ。
		piyoko.adult_type = "dasa"

	var old_scale := int(data.get("save_version", 1)) < SAVE_VERSION
	var scale := 2 if old_scale else 1
	piyoko.hunger = clampi(int(data.get("hunger", piyoko.hunger)) * scale, 0, Piyoko.STATUS_MAX)
	piyoko.friendship = clampi(int(data.get("friendship", piyoko.friendship)) * scale, 0, Piyoko.STATUS_MAX)
	piyoko.mood = clampi(int(data.get("mood", piyoko.mood)) * scale, 0, Piyoko.STATUS_MAX)

	piyoko.shortcake_count = int(data.get("shortcake_count", piyoko.shortcake_count))
	piyoko.onigiri_count = int(data.get("onigiri_count", piyoko.onigiri_count))
	piyoko.broccoli_count = int(data.get("broccoli_count", piyoko.broccoli_count))
	piyoko.food_count = _load_food_count(data, piyoko)

	piyoko.pet_count = int(data.get("pet_count", piyoko.pet_count))
	piyoko.play_count = int(data.get("play_count", piyoko.play_count))
	piyoko.play_success_count = int(data.get("play_success_count", piyoko.play_success_count))
	piyoko.play_failure_count = int(data.get("play_failure_count", piyoko.play_failure_count))
	piyoko.help_work_count = int(data.get("help_work_count", piyoko.help_work_count))
	piyoko.chibi_help_count = int(data.get("chibi_help_count", piyoko.chibi_help_count))
	piyoko.adult_work_count = int(data.get("adult_work_count", piyoko.adult_work_count))
	piyoko.earned_coins = int(data.get("earned_coins", piyoko.earned_coins))
	piyoko.child_shop_purchase_count = int(data.get("child_shop_purchase_count", piyoko.child_shop_purchase_count))
	piyoko.full_hunger_feed_count = int(data.get("full_hunger_feed_count", piyoko.full_hunger_feed_count))
	piyoko.current_play_success_streak = int(data.get("current_play_success_streak", piyoko.current_play_success_streak))
	piyoko.max_play_success_streak = int(data.get("max_play_success_streak", piyoko.max_play_success_streak))
	piyoko.play_streak_achieved = bool(data.get("play_streak_achieved", piyoko.play_streak_achieved))
	var raw_item_counts = data.get("item_use_counts", {})
	if typeof(raw_item_counts) == TYPE_DICTIONARY:
		piyoko.item_use_counts = (raw_item_counts as Dictionary).duplicate(true)
	piyoko.moon_fragment_used = bool(data.get("moon_fragment_used", false))
	piyoko.horse_ticket_used = bool(data.get("horse_ticket_used", false))
	piyoko.rainbow_item_used = bool(data.get("rainbow_item_used", false))
	piyoko.flower_item_used = bool(data.get("flower_item_used", false))
	piyoko.pc_parts_used = bool(data.get("pc_parts_used", false))
	piyoko.poker_chip_used = bool(data.get("poker_chip_used", false))

	# バージョン1のセーブには子ぴよこ期専用履歴がないため、0から安全に再開する。
	piyoko.adult_food_count = int(data.get("adult_food_count", piyoko.adult_food_count))
	piyoko.adult_shortcake_count = int(data.get("adult_shortcake_count", piyoko.adult_shortcake_count))
	piyoko.adult_onigiri_count = int(data.get("adult_onigiri_count", piyoko.adult_onigiri_count))
	piyoko.adult_broccoli_count = int(data.get("adult_broccoli_count", piyoko.adult_broccoli_count))
	piyoko.adult_pet_count = int(data.get("adult_pet_count", piyoko.adult_pet_count))
	piyoko.adult_play_success_count = int(data.get("adult_play_success_count", piyoko.adult_play_success_count))
	piyoko.adult_play_failure_count = int(data.get("adult_play_failure_count", piyoko.adult_play_failure_count))
	piyoko.oshimotif_sequence_progress = int(data.get("oshimotif_sequence_progress", piyoko.oshimotif_sequence_progress))

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
