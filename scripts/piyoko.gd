class_name Piyoko
extends RefCounted


# ==============================
# ピヨコの基本ステータス
# ==============================

# 現在の成長段階
# 0 = ちびぴよこ
# 1 = 子ぴよこ
# 2 = 大人ぴよこ
var growth_stage: int = 0
# 現在の成長段階でのお世話回数
var growth_count: int = 0
# ゲーム開始からのお世話総数
var total_care_count: int = 0
#成長タイミング
const CHILD_GROWTH_COUNT = 5
const ADULT_GROWTH_COUNT = 10
#ぴよこタイプ
var child_type: String = ""
var adult_type: String = ""
#おなか
var hunger: int = 3
#なかよし
var friendship: int = 3
#きげん
var mood: int = 3


# ==============================
# お世話回数
# ==============================

#食事履歴
var food_count: int = 0
var shortcake_count: int = 0
var onigiri_count: int = 0
var broccoli_count: int = 0
#なでる履歴
var pet_count: int = 0
#あそぶ履歴
var play_count: int = 0
var play_success_count: int = 0
var play_failure_count: int = 0

# 最後に行ったお世話
var last_care: String = ""


# ==============================
# ステータス共通処理
# ==============================

func add_hunger(value: int) -> void:
	hunger = clamp(hunger + value, 0, 5)


func add_friendship(value: int) -> void:
	friendship = clamp(friendship + value, 0, 5)


func add_mood(value: int) -> void:
	mood = clamp(mood + value, 0, 5)


func add_growth() -> void:
	growth_count += 1
	total_care_count += 1


# ==============================
# お世話
# ==============================

func feed(food_type: String) -> void:
	add_growth()

	food_count += 1
	last_care = "food"

	match food_type:
		"shortcake":
			shortcake_count += 1
			add_hunger(2)
			add_friendship(1)
			add_mood(2)

		"onigiri":
			onigiri_count += 1
			add_hunger(2)
			add_mood(1)

		"broccoli":
			broccoli_count += 1
			add_hunger(2)
			add_friendship(-1)
			add_mood(-1)


func pet() -> void:
	add_growth()

	pet_count += 1
	last_care = "pet"

	add_friendship(1)
	add_mood(1)


func play(success: bool) -> void:
	add_growth()

	play_count += 1
	last_care = "play"
	
	#遊ぶお腹が減る
	add_hunger(-1)

	if success:
		play_success_count += 1

		add_friendship(2)
		add_mood(2)
	else:
		play_failure_count += 1

		add_mood(-1)


func check_growth() -> bool:
	# ちびぴよこ → 子ぴよこ
	if growth_stage == 0 and growth_count >= CHILD_GROWTH_COUNT:
		determine_child_type()
		
		PiyokoCollectionManager.discover(
			"child_" + child_type
		)

		growth_stage = 1
		growth_count = 0

		return true

	# 子ぴよこ → 大人ぴよこ
	if growth_stage == 1 and growth_count >= ADULT_GROWTH_COUNT:
		determine_adult_type()
		
		PiyokoCollectionManager.discover(
			"adult_" + adult_type
		)

		growth_stage = 2
		growth_count = 0

		return true

	return false


func get_growth_stage_name() -> String:
	match growth_stage:
		-1:
			return "たまご"
			
		0:
			return "ちびぴよこ"

		1:
			var child_name := get_child_type_name()

			if child_name != "":
				return child_name
			return "子ぴよこ"

		2:
			var adult_name := get_adult_type_name()

			if adult_name != "":
				return adult_name

			return "大人ぴよこ"

		_:
			return "ちびぴよこ"


func determine_child_type() -> void:
	var feed_count := shortcake_count + onigiri_count + broccoli_count

	if feed_count > pet_count and feed_count > play_count:
		child_type = "food"

	elif play_count > feed_count and play_count > pet_count:
		child_type = "play"

	elif pet_count > feed_count and pet_count > play_count:
		child_type = "pet"

	else:
		child_type = "balance"


func determine_adult_type() -> void:
	var feed_count := shortcake_count + onigiri_count + broccoli_count

	if feed_count >= pet_count and feed_count >= play_count:
		adult_type = "sweets"

	elif pet_count >= feed_count and pet_count >= play_count:
		adult_type = "love"

	else:
		if play_success_count > play_failure_count:
			adult_type = "champion"
		else:
			adult_type = "challenger"


func get_child_type_name() -> String:
	match child_type:
		"food":
			return "ごはんピヨコ"

		"play":
			return "あそびピヨコ"

		"pet":
			return "なでなでピヨコ"

		"balance":
			return "バランスピヨコ"

		_:
			return ""


func get_adult_type_name() -> String:
	match adult_type:
		"sweets":
			return "スウィートタイプ"

		"love":
			return "ラブタイプ"

		"champion":
			return "チャンピオンピヨコ"

		"challenger":
			return "チャレンジャーピヨコ"

		_:
			return ""


func get_required_growth_count() -> int:
	match growth_stage:
		0:
			return CHILD_GROWTH_COUNT

		1:
			return ADULT_GROWTH_COUNT

		_:
			return 0


# ==============================
# 現在の状態を確認
# ==============================

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
	if growth_stage == 2:
		print("大人タイプ: ", adult_type)
	print("--------------------")
