class_name Piyoko
extends RefCounted

## ピヨコ1体分の育成状態と、お世話・成長ルールを管理する。
## 画面表示や演出は持たず、育成データとゲームルールだけを扱う。


# ------------------------------------------------------------
# 成長ルール
# ------------------------------------------------------------

const CHILD_GROWTH_COUNT := 5
const ADULT_GROWTH_COUNT := 10
const STATUS_MIN := 0
const STATUS_MAX := 5


# ------------------------------------------------------------
# 育成状態
# ------------------------------------------------------------

# -1: たまご / 0: ちび / 1: 子 / 2: 大人
var growth_stage: int = 0
var growth_count: int = 0
var total_care_count: int = 0

var child_type: String = ""
var adult_type: String = ""

var hunger: int = 3
var friendship: int = 3
var mood: int = 3


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

# "food" / "pet" / "play"
var last_care: String = ""


# ------------------------------------------------------------
# お世話
# ------------------------------------------------------------

func feed(food_type: String) -> void:
	_add_growth()
	food_count += 1
	last_care = "food"

	match food_type:
		"shortcake":
			shortcake_count += 1
			_add_hunger(2)
			_add_friendship(1)
			_add_mood(2)

		"onigiri":
			onigiri_count += 1
			_add_hunger(2)
			_add_mood(1)

		"broccoli":
			broccoli_count += 1
			_add_hunger(2)
			_add_friendship(-1)
			_add_mood(-1)


func pet() -> void:
	_add_growth()
	pet_count += 1
	last_care = "pet"

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
		_add_friendship(2)
		_add_mood(2)
	else:
		play_failure_count += 1
		_add_mood(-1)


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
	PiyokoCollectionManager.discover("child_" + child_type)

	growth_stage = 1
	growth_count = 0


func _grow_to_adult() -> void:
	_determine_adult_type()
	PiyokoCollectionManager.discover("adult_" + adult_type)

	growth_stage = 2
	growth_count = 0


## ちび期のお世話回数で子ぴよこの系統を決定する。
## 同数または突出したお世話がない場合は balance とする。
func _determine_child_type() -> void:
	if food_count > pet_count and food_count > play_count:
		child_type = "food"
	elif play_count > food_count and play_count > pet_count:
		child_type = "play"
	elif pet_count > food_count and pet_count > play_count:
		child_type = "pet"
	else:
		child_type = "balance"


## 大人の進化先は子ぴよこの系統だけで決定する。
func _determine_adult_type() -> void:
	match child_type:
		"food":
			adult_type = "sweets"
		"play":
			adult_type = "champion"
		"pet":
			adult_type = "love"
		"balance":
			adult_type = "challenger"
		_:
			# 想定外の系統でも進行不能にならないための保険。
			adult_type = "challenger"


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
	match child_type:
		"food":
			return "ごはんぴよこ"
		"play":
			return "やんちゃぴよこ"
		"pet":
			return "あまえぴよこ"
		"balance":
			return "へいきんぴよこ"
		_:
			return ""


func get_adult_type_name() -> String:
	match adult_type:
		"sweets":
			return "すいーつぴよこ"
		"champion":
			return "ちゃんぷぴよこ"
		"challenger":
			return "ふぁいとぴよこ"
		"love":
			return "らぶぴよこ"
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

	if growth_stage == 2:
		print("大人タイプ: ", adult_type)

	print("--------------------")
