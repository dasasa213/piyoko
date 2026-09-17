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

# frame_card.png は 256x320（4:5）の縦長カード素材。
# シーン上ではカードのVBoxContainerに直接置くとContainerのレイアウト対象になり、
# 横長に潰れてしまうため、実行時に各TextureRectの背面へ移して表示する。
const CARD_FRAME_SIZE := Vector2(128.0, 160.0)
const CARD_FRAME_OFFSET := Vector2(0.0, -14.0)

@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton


func _ready() -> void:
	_setup_card_frames()
	_update_collection_count()
	_update_collection_cards()
	back_button.pressed.connect(_on_back_button_pressed)


# ------------------------------------------------------------
# カード枠
# ------------------------------------------------------------

func _setup_card_frames() -> void:
	# frame_card.png の縦横比を保ったまま、ピヨコ画像と名前の背面に配置する。
	# FrameをVBoxContainerの直下に置いたままだと、ContainerがFrame自体を
	# 1行として並べてしまうため、TextureRectの子へ移動してレイアウトから外す。
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/ChibiTexture
	)
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/FoodChildTexture
	)
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/PlayChildTexture
	)
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/PetChildTexture
	)
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/BalanceChildTexture
	)
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/SweetsAdultTexture
	)
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/ChampionAdultTexture
	)
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/ChallengerAdultTexture
	)
	_setup_card_frame(
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/Frame,
		$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/LoveAdultTexture
	)


func _setup_card_frame(frame: NinePatchRect, texture_rect: TextureRect) -> void:
	frame.reparent(texture_rect)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = CARD_FRAME_OFFSET
	frame.size = CARD_FRAME_SIZE
	frame.show_behind_parent = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
