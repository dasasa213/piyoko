class_name Piyoko
extends RefCounted

## ピヨコ1体分の育成状態と、お世話・成長ルールを管理する。
## 画面表示や演出は持たず、育成データとゲームルールだけを扱う。


# ------------------------------------------------------------
# 成長ルール
# ------------------------------------------------------------

const CHILD_GROWTH_COUNT := 5
const ADULT_GROWTH_COUNT := 15
const STATUS_MIN := 0
const STATUS_MAX := 10


# ------------------------------------------------------------
# 育成状態
# ------------------------------------------------------------

# -1: たまご / 0: ちび / 1: 子 / 2: 大人
var growth_stage: int = 0
var growth_count: int = 0
var total_care_count: int = 0

# 1回の育成を識別し、おもいでの重複登録を防ぐための情報。
# 進化判定やお世話回数には使用しない。
var session_id: String = "%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
var started_at: String = Time.get_datetime_string_from_system(false, true)

var child_type: String = ""
var adult_type: String = ""

var hunger: int = 5
var friendship: int = 5
var mood: int = 5


# ------------------------------------------------------------
# お世話履歴
# ------------------------------------------------------------

var food_count: int = 0
var shortcake_count: int = 0
var onigiri_count: int = 0
var broccoli_count: int = 0

var pet_count: int = 0

var play_count: int = 0
var play_success_count: int = 0
var play_failure_count: int = 0
var help_work_count: int = 0
var chibi_help_count: int = 0
var adult_work_count: int = 0
var earned_coins: int = 0
var child_shop_purchase_count: int = 0
var full_hunger_feed_count: int = 0
var current_play_success_streak: int = 0
var max_play_success_streak: int = 0
var play_streak_achieved: bool = false
var item_use_counts: Dictionary = {}
var moon_fragment_used: bool = false
var horse_ticket_used: bool = false
var rainbow_item_used: bool = false
var flower_item_used: bool = false

# 子ぴよこ期だけの進化判定用履歴。
# ちび期の操作回数と混ざらないよう、子ぴよこへ成長してから記録する。
var adult_food_count: int = 0
var adult_shortcake_count: int = 0
var adult_onigiri_count: int = 0
var adult_broccoli_count: int = 0
var adult_pet_count: int = 0
var adult_play_success_count: int = 0
var adult_play_failure_count: int = 0
var oshimotif_sequence_progress: int = 0

# "food" / "pet" / "play" / "work"
var last_care: String = ""


# ------------------------------------------------------------
# お世話
# ------------------------------------------------------------

func feed(food_type: String) -> void:
	var was_full := hunger >= STATUS_MAX
	_add_growth()
	food_count += 1
	last_care = "food"
	if growth_stage == 1:
		adult_food_count += 1
		if was_full:
			full_hunger_feed_count += 1
		_record_oshimotif_step("food")

	match food_type:
		"shortcake":
			shortcake_count += 1
			if growth_stage == 1:
				adult_shortcake_count += 1
			_add_hunger(2)
			_add_friendship(1)
			_add_mood(2)

		"onigiri":
			onigiri_count += 1
			if growth_stage == 1:
				adult_onigiri_count += 1
			_add_hunger(2)
			_add_mood(1)

		"broccoli":
			broccoli_count += 1
			if growth_stage == 1:
				adult_broccoli_count += 1
			_add_hunger(2)
			_add_friendship(-1)
			_add_mood(-1)


func pet() -> void:
	_add_growth()
	pet_count += 1
	last_care = "pet"
	if growth_stage == 1:
		adult_pet_count += 1
		_record_oshimotif_step("pet")

	_add_friendship(1)
	_add_mood(1)


func play(success: bool) -> void:
	_add_growth()
	play_count += 1
	last_care = "play"

	# 遊ぶと成功・失敗に関係なくおなかが1減る。
	_add_hunger(-1)

	if success:
		play_success_count += 1
		if growth_stage == 1:
			adult_play_success_count += 1
			current_play_success_streak += 1
			max_play_success_streak = maxi(max_play_success_streak, current_play_success_streak)
			if current_play_success_streak >= 5:
				play_streak_achieved = true
			_record_oshimotif_step("play_success")
		_add_friendship(2)
		_add_mood(2)
	else:
		play_failure_count += 1
		if growth_stage == 1:
			adult_play_failure_count += 1
			current_play_success_streak = 0
			_record_oshimotif_step("play_failure")
		_add_mood(-1)


func work() -> bool:
	if hunger <= STATUS_MIN or mood <= STATUS_MIN:
		return false
	if growth_stage < 2:
		_add_growth()
	else:
		total_care_count += 1
	help_work_count += 1
	last_care = "work"
	if growth_stage == 0:
		chibi_help_count += 1
	elif growth_stage == 1:
		adult_work_count += 1
	_add_hunger(-1)
	_add_mood(-1)
	earned_coins += 10
	return true


func record_shop_purchase(quantity: int = 1) -> void:
	if growth_stage == 1:
		child_shop_purchase_count += maxi(0, quantity)


func use_item(item_id: String, hunger_delta: int = 0, friendship_delta: int = 0, mood_delta: int = 0) -> bool:
	var before := Vector3i(hunger, friendship, mood)
	_add_hunger(hunger_delta)
	_add_friendship(friendship_delta)
	_add_mood(mood_delta)
	if before == Vector3i(hunger, friendship, mood):
		return false
	item_use_counts[item_id] = int(item_use_counts.get(item_id, 0)) + 1
	return true


func use_special_item(item_id: String) -> bool:
	if not can_use_special_item(item_id):
		return false
	var item := PiyokoItemCatalog.get_item(item_id)
	set(str(item.get("special_flag", "")), true)
	item_use_counts[item_id] = int(item_use_counts.get(item_id, 0)) + 1
	return true


func can_use_special_item(item_id: String) -> bool:
	var item := PiyokoItemCatalog.get_item(item_id)
	var flag := str(item.get("special_flag", ""))
	if item.is_empty() or flag.is_empty() or not _item_allows_current_stage(item) or bool(get(flag)):
		return false
	var allowed: Array = item.get("allowed_lineages", [])
	return allowed.is_empty() or child_type in allowed


func can_use_item(item_id: String) -> bool:
	var item := PiyokoItemCatalog.get_item(item_id)
	if item.is_empty() or not _item_allows_current_stage(item):
		return false
	if not str(item.get("special_flag", "")).is_empty():
		return can_use_special_item(item_id)
	return true


func _item_allows_current_stage(item: Dictionary) -> bool:
	var stage_name := ""
	match growth_stage:
		0: stage_name = "chibi"
		1: stage_name = "child"
		2: stage_name = "adult"
	var allowed_stages: Array = item.get("use_stages", [])
	return not stage_name.is_empty() and (allowed_stages.is_empty() or stage_name in allowed_stages)


# ------------------------------------------------------------
# ステータス共通処理
# ------------------------------------------------------------

func _add_hunger(value: int) -> void:
	hunger = clamp(hunger + value, STATUS_MIN, STATUS_MAX)


func _add_friendship(value: int) -> void:
	friendship = clamp(friendship + value, STATUS_MIN, STATUS_MAX)


func _add_mood(value: int) -> void:
	mood = clamp(mood + value, STATUS_MIN, STATUS_MAX)


func _add_growth() -> void:
	growth_count += 1
	total_care_count += 1


## 旧セーブとの互換性のため履歴値は保持するが、現在の進化判定には使用しない。
func _record_oshimotif_step(step: String) -> void:
	var expected_steps := ["food", "play_success", "pet"]
	var expected_step: String = expected_steps[oshimotif_sequence_progress % expected_steps.size()]

	if step == expected_step:
		oshimotif_sequence_progress += 1
	else:
		# 間違えた後のごはんは、新しい1周目の開始として扱う。
		oshimotif_sequence_progress = 1 if step == "food" else 0


# ------------------------------------------------------------
# 成長判定
# ------------------------------------------------------------

## 現在のお世話回数を確認し、成長した場合だけ true を返す。
func check_growth() -> bool:
	if growth_stage == 0 and growth_count >= CHILD_GROWTH_COUNT:
		_grow_to_child()
		return true

	if growth_stage == 1 and growth_count >= ADULT_GROWTH_COUNT:
		_grow_to_adult()
		return true

	return false


func _grow_to_child() -> void:
	_determine_child_type()
	_discover_form("child_" + child_type)

	growth_stage = 1
	growth_count = 0


func _grow_to_adult() -> void:
	_determine_adult_type()
	_discover_form("adult_" + adult_type)

	growth_stage = 2
	growth_count = 0


## モデルをオートロード名に静的依存させず、実行中の図鑑へ登録する。
## これにより通常起動とヘッドレステストの双方で同じ成長処理を使える。
func _discover_form(form_id: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var collection_manager := tree.root.get_node_or_null("PiyokoCollectionManager")
	if collection_manager != null:
		collection_manager.discover(form_id)


## ちび期のお世話回数で子ぴよこの系統を決定する。
## 5回のお世話が 2・2・1・0 または 2・1・1・1 ならバランス、
## それ以外で最大回数が同数なら最後に行った操作を優先する。
func _determine_child_type() -> void:
	var available_counts := {
		"food": food_count,
		"play": play_count,
		"pet": pet_count,
		"work": chibi_help_count
	}
	var counts: Dictionary = {}
	for child in PiyokoDefinitionCatalog.get_stage_forms("child"):
		var care_key := str(child.get("care_key", ""))
		if not care_key.is_empty() and available_counts.has(care_key):
			counts[care_key] = int(available_counts[care_key])
	var sorted_counts := counts.values()
	sorted_counts.sort()

	if sorted_counts == [0, 1, 2, 2] or sorted_counts == [1, 1, 1, 2]:
		child_type = "balance"
		return

	var maximum: int = sorted_counts[-1]
	var maximum_types: Array[String] = []
	for care_type in counts:
		if int(counts[care_type]) == maximum:
			maximum_types.append(str(care_type))

	if maximum_types.size() == 1:
		child_type = maximum_types[0]
	elif last_care in maximum_types:
		child_type = last_care
	else:
		child_type = "balance"


## 子ぴよこ期だけの履歴と使用アイテムから、大人進化先を決定する。
func _determine_adult_type() -> void:
	adult_type = PiyokoEvolutionEvaluator.determine_adult_type(child_type, self)


# ------------------------------------------------------------
# 表示用情報
# ------------------------------------------------------------

func get_growth_stage_name() -> String:
	match growth_stage:
		-1:
			return "たまご"
		0:
			return "ちびぴよこ"
		1:
			var child_name := get_child_type_name()
			return child_name if child_name != "" else "子ぴよこ"
		2:
			var adult_name := get_adult_type_name()
			return adult_name if adult_name != "" else "大人ぴよこ"
		_:
			return "ちびぴよこ"


func get_child_type_name() -> String:
	if child_type.is_empty():
		return ""
	return PiyokoDefinitionCatalog.get_display_name("child_" + child_type, "")


func get_adult_type_name() -> String:
	if adult_type.is_empty():
		return ""
	return PiyokoDefinitionCatalog.get_display_name("adult_" + adult_type, "")


func get_required_growth_count() -> int:
	match growth_stage:
		0:
			return CHILD_GROWTH_COUNT
		1:
			return ADULT_GROWTH_COUNT
		_:
			return 0


# ------------------------------------------------------------
# デバッグ
# ------------------------------------------------------------

## 開発中に現在の育成状態をGodotの出力へ表示する。
func print_status() -> void:
	print("--------------------")
	print("成長段階: ", get_growth_stage_name())
	print("現在段階のお世話: ", growth_count)
	print("総お世話回数: ", total_care_count)
	print("ショートケーキ: ", shortcake_count)
	print("おにぎり: ", onigiri_count)
	print("ブロッコリー: ", broccoli_count)
	print("なでる回数: ", pet_count)
	print("あそぶ回数: ", play_count)
	print("あそぶ成功: ", play_success_count)
	print("あそぶ失敗: ", play_failure_count)
	print("子期ショートケーキ: ", adult_shortcake_count)
	print("子期おにぎり: ", adult_onigiri_count)
	print("子期ブロッコリー: ", adult_broccoli_count)
	print("子期なでる: ", adult_pet_count)
	print("子期あそぶ成功: ", adult_play_success_count)
	print("子期あそぶ失敗: ", adult_play_failure_count)
	print("推しモチーフ順序: ", oshimotif_sequence_progress)

	if growth_stage == 2:
		print("大人タイプ: ", adult_type)

	print("--------------------")
