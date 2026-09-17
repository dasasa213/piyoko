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

const LINE_COLOR := Color(0.28, 0.17, 0.09, 0.92)
const LINE_WIDTH := 4.0
const ARROW_SIZE := 8.0

@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton
@onready var collection_area: ScrollContainer = $MainMargin/CollectionLayout/CollectionArea
@onready var evolution_tree: VBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree
@onready var chibi_row: HBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow
@onready var child_row: HBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow
@onready var adult_row: HBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow

var evolution_lines: Control

func _ready() -> void:
	_setup_tree_layout()
	_setup_card_frames()
	_setup_stage_labels()
	_setup_evolution_lines()
	_update_collection_count()
	_update_collection_cards()
	_update_back_button_text()
	back_button.pressed.connect(_on_back_button_pressed)

func _setup_tree_layout() -> void:
	evolution_tree.custom_minimum_size = Vector2.ZERO
	evolution_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evolution_tree.alignment = BoxContainer.ALIGNMENT_BEGIN
	evolution_tree.add_theme_constant_override("separation", 3)
	chibi_row.custom_minimum_size = Vector2(0.0, 142.0)
	child_row.custom_minimum_size = Vector2(0.0, 142.0)
	adult_row.custom_minimum_size = Vector2(0.0, 142.0)
	child_row.add_theme_constant_override("separation", 34)
	adult_row.add_theme_constant_override("separation", 34)
	var future_space := evolution_tree.get_node_or_null("FutureSpace") as Control
	if future_space != null:
		future_space.custom_minimum_size = Vector2.ZERO
		future_space.hide()
	collection_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	collection_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func _setup_card_frames() -> void:
	_setup_card(chibi_row.get_node("ChibiCard"), chibi_row.get_node("ChibiCard/Frame"), chibi_row.get_node("ChibiCard/ChibiTexture"), chibi_row.get_node("ChibiCard/ChibiName"))
	_setup_card(child_row.get_node("FoodChildCard"), child_row.get_node("FoodChildCard/Frame"), child_row.get_node("FoodChildCard/FoodChildTexture"), child_row.get_node("FoodChildCard/FoodChildName"))
	_setup_card(child_row.get_node("PlayChildCard"), child_row.get_node("PlayChildCard/Frame"), child_row.get_node("PlayChildCard/PlayChildTexture"), child_row.get_node("PlayChildCard/PlayChildName"))
	_setup_card(child_row.get_node("PetChildCard"), child_row.get_node("PetChildCard/Frame"), child_row.get_node("PetChildCard/PetChildTexture"), child_row.get_node("PetChildCard/PetChildName"))
	_setup_card(child_row.get_node("BalanceChildCard"), child_row.get_node("BalanceChildCard/Frame"), child_row.get_node("BalanceChildCard/BalanceChildTexture"), child_row.get_node("BalanceChildCard/BalanceChildName"))
	_setup_card(adult_row.get_node("SweetsAdultCard"), adult_row.get_node("SweetsAdultCard/Frame"), adult_row.get_node("SweetsAdultCard/SweetsAdultTexture"), adult_row.get_node("SweetsAdultCard/SweetsAdultName"))
	_setup_card(adult_row.get_node("ChampionAdultCard"), adult_row.get_node("ChampionAdultCard/Frame"), adult_row.get_node("ChampionAdultCard/ChampionAdultTexture"), adult_row.get_node("ChampionAdultCard/ChampionAdultName"))
	_setup_card(adult_row.get_node("ChallengerAdultCard"), adult_row.get_node("ChallengerAdultCard/Frame"), adult_row.get_node("ChallengerAdultCard/ChallengerAdultTexture"), adult_row.get_node("ChallengerAdultCard/ChallengerAdultName"))
	_setup_card(adult_row.get_node("LoveAdultCard"), adult_row.get_node("LoveAdultCard/Frame"), adult_row.get_node("LoveAdultCard/LoveAdultTexture"), adult_row.get_node("LoveAdultCard/LoveAdultName"))

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

func _setup_stage_labels() -> void:
	_add_stage_label("🌱 ちび", chibi_row)
	_add_stage_label("🌸 こども", child_row)
	_add_stage_label("♛ おとな", adult_row)

func _add_stage_label(text_value: String, before_row: Control) -> void:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(0.0, 24.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.31, 0.20, 0.11, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.96, 0.84, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	evolution_tree.add_child(label)
	evolution_tree.move_child(label, before_row.get_index())

## 系統線はカードの実座標から毎回描画する。
## EvolutionLines はカードより手前に置くが、線の端点をカード境界にしているためカード内部には入らない。
func _setup_evolution_lines() -> void:
	evolution_lines = Control.new()
	evolution_lines.name = "EvolutionLines"
	evolution_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# z_index = -1 だと親の描画より後ろに回り、背景に隠れて線が見えない。
	# カード枠より前に描画して、確実に系統線を表示する。
	evolution_lines.z_index = 10
	evolution_lines.draw.connect(_draw_evolution_lines)
	evolution_tree.add_child(evolution_lines)
	call_deferred("_refresh_evolution_lines")

func _refresh_evolution_lines() -> void:
	if evolution_lines == null:
		return
	# VBoxContainer のレイアウト対象にしないため、系統図と同じグローバル矩形へ手動で重ねる。
	evolution_lines.global_position = evolution_tree.global_position
	evolution_lines.size = evolution_tree.size
	evolution_lines.queue_redraw()

func _draw_evolution_lines() -> void:
	if evolution_lines == null:
		return
	var chibi_card := chibi_row.get_node("ChibiCard") as Control
	var child_cards: Array[Control] = [
		child_row.get_node("FoodChildCard"),
		child_row.get_node("PlayChildCard"),
		child_row.get_node("PetChildCard"),
		child_row.get_node("BalanceChildCard")
	]
	var adult_cards: Array[Control] = [
		adult_row.get_node("SweetsAdultCard"),
		adult_row.get_node("ChampionAdultCard"),
		adult_row.get_node("LoveAdultCard"),
		adult_row.get_node("ChallengerAdultCard")
	]

	var start := _bottom_center(chibi_card)
	var child_tops: Array[Vector2] = []
	for card in child_cards:
		child_tops.append(_top_center(card))
	var branch_y := (start.y + child_tops[0].y) * 0.5
	_draw_line_local(start, Vector2(start.x, branch_y))
	_draw_line_local(Vector2(child_tops[0].x, branch_y), Vector2(child_tops[child_tops.size() - 1].x, branch_y))
	for target in child_tops:
		_draw_arrow_path(Vector2(target.x, branch_y), target)

	for i in child_cards.size():
		_draw_arrow_path(_bottom_center(child_cards[i]), _top_center(adult_cards[i]))

func _top_center(card: Control) -> Vector2:
	var global_point := card.global_position + Vector2(card.size.x * 0.5, 0.0)
	return _global_to_line_local(global_point)

func _bottom_center(card: Control) -> Vector2:
	var global_point := card.global_position + Vector2(card.size.x * 0.5, card.size.y)
	return _global_to_line_local(global_point)

func _global_to_line_local(global_point: Vector2) -> Vector2:
	return global_point - evolution_lines.global_position

func _draw_line_local(from: Vector2, to: Vector2) -> void:
	evolution_lines.draw_line(from, to, LINE_COLOR, LINE_WIDTH, true)

func _draw_arrow_path(from: Vector2, to: Vector2) -> void:
	_draw_line_local(from, to)
	var tip := to - Vector2(0.0, 3.0)
	var points := PackedVector2Array([
		tip,
		tip + Vector2(-ARROW_SIZE, -ARROW_SIZE),
		tip + Vector2(ARROW_SIZE, -ARROW_SIZE)
	])
	evolution_lines.draw_colored_polygon(points, LINE_COLOR)

func _update_back_button_text() -> void:
	if get_tree().has_meta(RETURN_SCENE_META):
		back_button.text = "タイトルにもどる"
	else:
		back_button.text = "育成画面にもどる"

func _update_collection_count() -> void:
	var discovered_count := PiyokoCollectionManager.discovered.size()
	count_label.text = "発見数：%d / %d" % [discovered_count, TOTAL_COLLECTION_COUNT]

func _update_collection_cards() -> void:
	_update_card("chibi", chibi_row.get_node("ChibiCard/ChibiTexture"), chibi_row.get_node("ChibiCard/ChibiName"), "ちびぴよこ")
	_update_card("child_food", child_row.get_node("FoodChildCard/FoodChildTexture"), child_row.get_node("FoodChildCard/FoodChildName"), "ごはんぴよこ")
	_update_card("child_play", child_row.get_node("PlayChildCard/PlayChildTexture"), child_row.get_node("PlayChildCard/PlayChildName"), "やんちゃぴよこ")
	_update_card("child_pet", child_row.get_node("PetChildCard/PetChildTexture"), child_row.get_node("PetChildCard/PetChildName"), "あまえぴよこ")
	_update_card("child_balance", child_row.get_node("BalanceChildCard/BalanceChildTexture"), child_row.get_node("BalanceChildCard/BalanceChildName"), "へいきんぴよこ")
	_update_card("adult_sweets", adult_row.get_node("SweetsAdultCard/SweetsAdultTexture"), adult_row.get_node("SweetsAdultCard/SweetsAdultName"), "すいーつぴよこ")
	_update_card("adult_champion", adult_row.get_node("ChampionAdultCard/ChampionAdultTexture"), adult_row.get_node("ChampionAdultCard/ChampionAdultName"), "ちゃんぷぴよこ")
	_update_card("adult_challenger", adult_row.get_node("ChallengerAdultCard/ChallengerAdultTexture"), adult_row.get_node("ChallengerAdultCard/ChallengerAdultName"), "ふぁいとぴよこ")
	_update_card("adult_love", adult_row.get_node("LoveAdultCard/LoveAdultTexture"), adult_row.get_node("LoveAdultCard/LoveAdultName"), "らぶぴよこ")

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
