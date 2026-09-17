extends Control

## ピヨコ図鑑画面を管理する。
## 発見済みの姿だけ名前と本来の色で表示し、
## 未発見の姿はシルエット＋「？？？」で表示する。
## 現在の種類数では1画面に収め、将来系統が増えた時だけスクロールできる構造にする。

const TOTAL_COLLECTION_COUNT := 9
const UNDISCOVERED_NAME := "？？？"
const SILHOUETTE_COLOR := Color(0.12, 0.12, 0.12, 1.0)
const DEFAULT_RETURN_SCENE := "res://scenes/game.tscn"
const RETURN_SCENE_META := "collection_return_scene"

const CARD_FRAME_SIZE := Vector2(180.0, 142.0)
const CARD_SIZE := Vector2(180.0, 142.0)
const CARD_TEXTURE_SIZE := Vector2(180.0, 103.0)
const CARD_NAME_HEIGHT := 35.0
const CARD_NAME_FONT_SIZE := 14

@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton
@onready var collection_area: ScrollContainer = $MainMargin/CollectionLayout/CollectionArea
@onready var evolution_tree: VBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree

func _ready() -> void:
	_setup_tree_layout()
	_setup_card_frames()
	_setup_stage_tabs()
	_update_collection_count()
	_update_collection_cards()
	_update_back_button_text()
	back_button.pressed.connect(_on_back_button_pressed)

func _setup_tree_layout() -> void:
	# 9種類の現在は余計なスクロールを発生させない。
	# 将来カードや段が増えて表示領域を超えた場合は ScrollContainer が自動でスクロール可能になる。
	evolution_tree.custom_minimum_size = Vector2(1040.0, 500.0)
	evolution_tree.add_theme_constant_override("separation", 8)
	$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow.custom_minimum_size = Vector2(0.0, 150.0)
	$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow.custom_minimum_size = Vector2(0.0, 150.0)
	$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow.custom_minimum_size = Vector2(0.0, 150.0)
	$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow.add_theme_constant_override("separation", 34)
	$MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow.add_theme_constant_override("separation", 34)
	var future_space := $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/FutureSpace
	future_space.custom_minimum_size = Vector2.ZERO
	future_space.hide()
	collection_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	collection_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

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
	frame.reparent(texture_rect)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = Vector2.ZERO
	frame.size = CARD_FRAME_SIZE
	frame.show_behind_parent = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.custom_minimum_size = Vector2(0.0, CARD_NAME_HEIGHT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", CARD_NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", Color(0.20, 0.12, 0.07, 1.0))

func _setup_stage_tabs() -> void:
	# イメージ画像のように、カテゴリは系統図の左側へ縦に揃えて表示する。
	# ScrollContainer 自体には入れず、カードのレイアウトを押し広げない。
	_add_stage_tab("🌱 ちび", 42.0, Color(1.0, 0.91, 0.62, 0.96))
	_add_stage_tab("🌸 こども", 202.0, Color(1.0, 0.76, 0.73, 0.96))
	_add_stage_tab("♛ おとな", 362.0, Color(0.66, 0.87, 1.0, 0.96))

func _add_stage_tab(text_value: String, y: float, background_color: Color) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(8.0, y)
	panel.size = Vector2(150.0, 48.0)
	panel.z_index = 20
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = Color(1.0, 0.97, 0.86, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.24, 0.13, 0.06, 1.0))
	panel.add_child(label)
	collection_area.add_child(panel)

func _update_back_button_text() -> void:
	if get_tree().has_meta(RETURN_SCENE_META):
		back_button.text = "タイトルにもどる"
	else:
		back_button.text = "育成画面にもどる"

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

func _on_back_button_pressed() -> void:
	var return_scene := DEFAULT_RETURN_SCENE
	if get_tree().has_meta(RETURN_SCENE_META):
		return_scene = str(get_tree().get_meta(RETURN_SCENE_META))
		get_tree().remove_meta(RETURN_SCENE_META)
	get_tree().change_scene_to_file(return_scene)
