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
const DEFAULT_RETURN_SCENE := "res://scenes/game.tscn"
const RETURN_SCENE_META := "collection_return_scene"

# frame_card.png は 256x320（4:5）の縦長カード素材。
# 枠の比率は崩さず、名前をカード下部の白い領域へ収める。
const CARD_FRAME_SIZE := Vector2(116.0, 145.0)
const CARD_FRAME_OFFSET := Vector2(0.0, -4.0)
const CARD_SIZE := Vector2(128.0, 145.0)
const CARD_TEXTURE_SIZE := Vector2(116.0, 104.0)
const CARD_NAME_HEIGHT := 34.0

@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton


func _ready() -> void:
	_setup_card_frames()
	_setup_growth_stage_guides()
	_update_collection_count()
	_update_collection_cards()
	_update_back_button_text()
	back_button.pressed.connect(_on_back_button_pressed)


# ------------------------------------------------------------
# カード枠
# ------------------------------------------------------------

func _setup_card_frames() -> void:
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/ChibiTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/ChibiName)
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/FoodChildTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/FoodChildName)
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/PlayChildTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/PlayChildName)
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/PetChildTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/PetChildName)
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/BalanceChildTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/BalanceChildName)
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/SweetsAdultTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/SweetsAdultName)
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/ChampionAdultTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/ChampionAdultName)
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/ChallengerAdultTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/ChallengerAdultName)
	_setup_card($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/Frame, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/LoveAdultTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/LoveAdultName)


func _setup_card(card: VBoxContainer, frame: NinePatchRect, texture_rect: TextureRect, name_label: Label) -> void:
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_constant_override("separation", 0)

	texture_rect.custom_minimum_size = CARD_TEXTURE_SIZE
	texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# FrameはTextureRectの子にしてContainerの自動整列から外す。
	# self_modulateでピヨコだけを暗くするため、未発見でも枠の色は維持される。
	frame.reparent(texture_rect)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = CARD_FRAME_OFFSET
	frame.size = CARD_FRAME_SIZE
	frame.show_behind_parent = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 名前はカードの下部に専用領域を確保する。
	name_label.custom_minimum_size = Vector2(0.0, CARD_NAME_HEIGHT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.20, 0.12, 0.07, 1.0))


# ------------------------------------------------------------
# 成長段階ガイド
# ------------------------------------------------------------

func _setup_growth_stage_guides() -> void:
	# 既存のカード配置は変えず、各段が何の段階か分かる小さなラベルを重ねる。
	_add_stage_label($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow, "ちび", Vector2(-78.0, 54.0))
	_add_stage_label($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow, "こども", Vector2(-82.0, 54.0))
	_add_stage_label($MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow, "おとな", Vector2(-82.0, 54.0))


func _add_stage_label(row: HBoxContainer, text_value: String, offset: Vector2) -> void:
	var label := Label.new()
	label.text = text_value
	label.position = offset
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.31, 0.20, 0.11, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.96, 0.84, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	row.add_child(label)


func _update_back_button_text() -> void:
	if get_tree().has_meta(RETURN_SCENE_META):
		back_button.text = "タイトルにもどる"
	else:
		back_button.text = "育成画面にもどる"


# ------------------------------------------------------------
# 図鑑表示
# ------------------------------------------------------------

func _update_collection_count() -> void:
	var discovered_count := PiyokoCollectionManager.discovered.size()
	count_label.text = "発見数：%d / %d" % [discovered_count, TOTAL_COLLECTION_COUNT]


func _update_collection_cards() -> void:
	_update_card("chibi", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/ChibiTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow/ChibiCard/ChibiName, "ちびぴよこ")
	_update_card("child_food", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/FoodChildTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/FoodChildCard/FoodChildName, "ごはんぴよこ")
	_update_card("child_play", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/PlayChildTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PlayChildCard/PlayChildName, "やんちゃぴよこ")
	_update_card("child_pet", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/PetChildTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/PetChildCard/PetChildName, "あまえぴよこ")
	_update_card("child_balance", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/BalanceChildTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow/BalanceChildCard/BalanceChildName, "へいきんぴよこ")
	_update_card("adult_sweets", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/SweetsAdultTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/SweetsAdultCard/SweetsAdultName, "すいーつぴよこ")
	_update_card("adult_champion", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/ChampionAdultTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChampionAdultCard/ChampionAdultName, "ちゃんぷぴよこ")
	_update_card("adult_challenger", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/ChallengerAdultTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/ChallengerAdultCard/ChallengerAdultName, "ふぁいとぴよこ")
	_update_card("adult_love", $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/LoveAdultTexture, $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow/LoveAdultCard/LoveAdultName, "らぶぴよこ")


func _update_card(piyoko_id: String, texture_rect: TextureRect, name_label: Label, discovered_name: String) -> void:
	var discovered := PiyokoCollectionManager.is_discovered(piyoko_id)

	if discovered:
		texture_rect.self_modulate = Color.WHITE
		name_label.text = discovered_name
		return

	texture_rect.self_modulate = SILHOUETTE_COLOR
	name_label.text = UNDISCOVERED_NAME


# ------------------------------------------------------------
# 画面遷移
# ------------------------------------------------------------

func _on_back_button_pressed() -> void:
	var return_scene := DEFAULT_RETURN_SCENE

	if get_tree().has_meta(RETURN_SCENE_META):
		return_scene = str(get_tree().get_meta(RETURN_SCENE_META))
		get_tree().remove_meta(RETURN_SCENE_META)

	get_tree().change_scene_to_file(return_scene)
