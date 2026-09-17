extends Control

## ピヨコ図鑑画面を管理する。
## 発見済みの姿だけ名前と本来の色で表示し、
## 未発見の姿はシルエット＋「？？？」で表示する。
##
## 図鑑IDは育成側の登録形式に合わせる。
## ちび: chibi / 子: child_<type> / 大人: adult_<type>

const TOTAL_COLLECTION_COUNT := 9
const UNDISCOVERED_NAME := "？？？"
const SILHOUETTE_COLOR := Color(0.12, 0.12, 0.12, 1.0)

@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton


func _ready() -> void:
	_update_collection_count()
	_update_collection_cards()
	back_button.pressed.connect(_on_back_button_pressed)


# ------------------------------------------------------------
# 図鑑表示
# ------------------------------------------------------------

func _update_collection_count() -> void:
	var discovered_count := PiyokoCollectionManager.discovered.size()
	count_label.text = "発見数：%d / %d" % [discovered_count, TOTAL_COLLECTION_COUNT]


func _update_collection_cards() -> void:
	_update_card(
		"chibi",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/ChibiTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/ChibiName,
		"ちびぴよこ"
	)

	_update_card(
		"child_food",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/FoodChildTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/FoodChildName,
		"ごはんぴよこ"
	)
	_update_card(
		"child_play",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/PlayChildTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/PlayChildName,
		"やんちゃぴよこ"
	)
	_update_card(
		"child_pet",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/PetChildTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/PetChildName,
		"あまえぴよこ"
	)
	_update_card(
		"child_balance",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/BalanceChildTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/BalanceChildName,
		"へいきんぴよこ"
	)

	_update_card(
		"adult_sweets",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/SweetsAdultTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/SweetsAdultName,
		"すいーつぴよこ"
	)
	_update_card(
		"adult_champion",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/ChampionAdultTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/ChampionAdultName,
		"ちゃんぷぴよこ"
	)
	_update_card(
		"adult_challenger",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/ChallengerAdultTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/ChallengerAdultName,
		"ふぁいとぴよこ"
	)
	_update_card(
		"adult_love",
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/LoveAdultTexture,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/LoveAdultName,
		"らぶぴよこ"
	)


func _update_card(
	piyoko_id: String,
	texture_rect: TextureRect,
	name_label: Label,
	discovered_name: String
) -> void:
	var discovered := PiyokoCollectionManager.is_discovered(piyoko_id)

	if discovered:
		texture_rect.modulate = Color.WHITE
		name_label.text = discovered_name
		return

	# 元画像の輪郭は残しつつ、色や特徴を隠して未発見感を出す。
	texture_rect.modulate = SILHOUETTE_COLOR
	name_label.text = UNDISCOVERED_NAME


# ------------------------------------------------------------
# 画面遷移
# ------------------------------------------------------------

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
