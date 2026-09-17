extends Control

## ピヨコ図鑑画面。
## カード・進化線・段ラベルを1枚のDiagramCanvas上で同じ座標系に固定する。
## 現在9種類は1画面表示。将来キャンバスを広げた場合のみスクロールする。

const TOTAL_COLLECTION_COUNT := 9
const UNDISCOVERED_NAME := "？？？"
const SILHOUETTE_COLOR := Color(0.12, 0.12, 0.12, 1.0)
const DEFAULT_RETURN_SCENE := "res://scenes/game.tscn"
const RETURN_SCENE_META := "collection_return_scene"

const CARD_SIZE := Vector2(190.0, 126.0)
const CARD_TEXTURE_SIZE := Vector2(190.0, 91.0)
const CARD_NAME_HEIGHT := 31.0
const CARD_NAME_FONT_SIZE := 14

# 承認済みイメージに合わせた系統図座標。
# 左側に段ラベル用の余白を確保し、4列を均等配置する。
const DIAGRAM_SIZE := Vector2(1080.0, 438.0)
const CHIBI_POS := Vector2(475.0, 2.0)
const CHILD_Y := 158.0
const ADULT_Y := 312.0
const COLUMN_X := [105.0, 345.0, 585.0, 825.0]
const STAGE_LABEL_X := 2.0

const LINE_COLOR := Color(0.25, 0.14, 0.07, 0.95)
const LINE_WIDTH := 4.0
const ARROW_SIZE := 8.0
const LINE_GAP := 8.0

@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton
@onready var collection_area: ScrollContainer = $MainMargin/CollectionLayout/CollectionArea
@onready var evolution_tree: VBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree
@onready var chibi_row: HBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChibiRow
@onready var child_row: HBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/ChildRow
@onready var adult_row: HBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree/AdultRow

var diagram_canvas: Control
var evolution_lines: Control
var chibi_card: Control
var child_cards: Array[Control] = []
var adult_cards: Array[Control] = []

func _ready() -> void:
	_build_diagram_canvas()
	_setup_card_frames()
	_setup_stage_labels()
	_setup_evolution_lines()
	_update_collection_count()
	_update_collection_cards()
	_update_back_button_text()
	back_button.pressed.connect(_on_back_button_pressed)
	call_deferred("_finish_layout")

func _build_diagram_canvas() -> void:
	diagram_canvas = Control.new()
	diagram_canvas.name = "DiagramCanvas"
	diagram_canvas.custom_minimum_size = DIAGRAM_SIZE
	diagram_canvas.size = DIAGRAM_SIZE
	diagram_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	evolution_tree.add_child(diagram_canvas)

	chibi_card = chibi_row.get_node("ChibiCard") as Control
	child_cards = [
		child_row.get_node("FoodChildCard") as Control,
		child_row.get_node("PlayChildCard") as Control,
		child_row.get_node("PetChildCard") as Control,
		child_row.get_node("BalanceChildCard") as Control
	]
	# 進化先と同じ列順に固定する。
	adult_cards = [
		adult_row.get_node("SweetsAdultCard") as Control,
		adult_row.get_node("ChampionAdultCard") as Control,
		adult_row.get_node("LoveAdultCard") as Control,
		adult_row.get_node("ChallengerAdultCard") as Control
	]

	_reparent_card(chibi_card, CHIBI_POS)
	for i in child_cards.size():
		_reparent_card(child_cards[i], Vector2(COLUMN_X[i], CHILD_Y))
	for i in adult_cards.size():
		_reparent_card(adult_cards[i], Vector2(COLUMN_X[i], ADULT_Y))

	# 元のContainer行は系統図レイアウトから完全に外す。
	for row in [chibi_row, child_row, adult_row]:
		row.hide()
		row.custom_minimum_size = Vector2.ZERO
		row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var future_space := evolution_tree.get_node_or_null("FutureSpace") as Control
	if future_space != null:
		future_space.hide()
		future_space.custom_minimum_size = Vector2.ZERO

	evolution_tree.custom_minimum_size = Vector2.ZERO
	evolution_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evolution_tree.add_theme_constant_override("separation", 0)

func _reparent_card(card: Control, target_position: Vector2) -> void:
	card.reparent(diagram_canvas)
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.position = target_position
	card.size = CARD_SIZE
	card.custom_minimum_size = CARD_SIZE
	card.z_index = 2

func _setup_card_frames() -> void:
	_setup_card(chibi_card, chibi_card.get_node("Frame"), chibi_card.get_node("ChibiTexture"), chibi_card.get_node("ChibiName"))
	_setup_card(child_cards[0], child_cards[0].get_node("Frame"), child_cards[0].get_node("FoodChildTexture"), child_cards[0].get_node("FoodChildName"))
	_setup_card(child_cards[1], child_cards[1].get_node("Frame"), child_cards[1].get_node("PlayChildTexture"), child_cards[1].get_node("PlayChildName"))
	_setup_card(child_cards[2], child_cards[2].get_node("Frame"), child_cards[2].get_node("PetChildTexture"), child_cards[2].get_node("PetChildName"))
	_setup_card(child_cards[3], child_cards[3].get_node("Frame"), child_cards[3].get_node("BalanceChildTexture"), child_cards[3].get_node("BalanceChildName"))
	_setup_card(adult_cards[0], adult_cards[0].get_node("Frame"), adult_cards[0].get_node("SweetsAdultTexture"), adult_cards[0].get_node("SweetsAdultName"))
	_setup_card(adult_cards[1], adult_cards[1].get_node("Frame"), adult_cards[1].get_node("ChampionAdultTexture"), adult_cards[1].get_node("ChampionAdultName"))
	_setup_card(adult_cards[2], adult_cards[2].get_node("Frame"), adult_cards[2].get_node("LoveAdultTexture"), adult_cards[2].get_node("LoveAdultName"))
	_setup_card(adult_cards[3], adult_cards[3].get_node("Frame"), adult_cards[3].get_node("ChallengerAdultTexture"), adult_cards[3].get_node("ChallengerAdultName"))

func _setup_card(card: Control, frame: NinePatchRect, texture_rect: TextureRect, name_label: Label) -> void:
	card.add_theme_constant_override("separation", 0)
	texture_rect.custom_minimum_size = CARD_TEXTURE_SIZE
	texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.reparent(texture_rect)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = Vector2.ZERO
	frame.size = CARD_SIZE
	frame.show_behind_parent = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.custom_minimum_size = Vector2(0.0, CARD_NAME_HEIGHT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", CARD_NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", Color(0.20, 0.12, 0.07, 1.0))

## 段ラベルは線上に置かず、左側の専用領域に表示する。
func _setup_stage_labels() -> void:
	_add_stage_label("🌱 ちび", Vector2(STAGE_LABEL_X, 47.0), Color(0.98, 0.82, 0.49, 0.96))
	_add_stage_label("🌸 こども", Vector2(STAGE_LABEL_X, CHILD_Y + 47.0), Color(1.0, 0.76, 0.80, 0.96))
	_add_stage_label("♛ おとな", Vector2(STAGE_LABEL_X, ADULT_Y + 47.0), Color(0.67, 0.88, 1.0, 0.96))

func _add_stage_label(text_value: String, target_position: Vector2, background_color: Color) -> void:
	var panel := PanelContainer.new()
	panel.position = target_position
	panel.size = Vector2(96.0, 34.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 3
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = Color(0.48, 0.31, 0.18, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(17)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(88.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08, 1.0))
	panel.add_child(label)
	diagram_canvas.add_child(panel)

## 進化線は専用レイヤーへ描画。
## 負のz_indexは使わず、線=1 / カード=2 / ラベル=3 と明示して過去の「線が背景へ消える」問題を防ぐ。
func _setup_evolution_lines() -> void:
	evolution_lines = Control.new()
	evolution_lines.name = "EvolutionLines"
	evolution_lines.position = Vector2.ZERO
	evolution_lines.size = DIAGRAM_SIZE
	evolution_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	evolution_lines.z_index = 1
	evolution_lines.draw.connect(_draw_evolution_lines)
	diagram_canvas.add_child(evolution_lines)

func _finish_layout() -> void:
	_update_scroll_mode()
	if evolution_lines != null:
		evolution_lines.queue_redraw()

func _draw_evolution_lines() -> void:
	# ちび → こども4種。
	# ちびカード下端から中央幹を伸ばし、空白中央で横分岐して各カード上端へ接続する。
	var start := _bottom_center(chibi_card)
	var child_tops: Array[Vector2] = []
	for card in child_cards:
		child_tops.append(_top_center(card))
	var branch_y := start.y + ((child_tops[0].y - start.y) * 0.48)
	_draw_line(start + Vector2(0.0, LINE_GAP), Vector2(start.x, branch_y))
	_draw_line(Vector2(child_tops[0].x, branch_y), Vector2(child_tops[3].x, branch_y))
	for target in child_tops:
		_draw_arrow(Vector2(target.x, branch_y), target - Vector2(0.0, LINE_GAP))

	# こども → おとな。各進化先を同じ列に置き、完全な縦線にする。
	for i in child_cards.size():
		var from := _bottom_center(child_cards[i]) + Vector2(0.0, LINE_GAP)
		var target := _top_center(adult_cards[i]) - Vector2(0.0, LINE_GAP)
		_draw_arrow(from, target)

func _top_center(card: Control) -> Vector2:
	return card.position + Vector2(card.size.x * 0.5, 0.0)

func _bottom_center(card: Control) -> Vector2:
	return card.position + Vector2(card.size.x * 0.5, card.size.y)

func _draw_line(from: Vector2, to: Vector2) -> void:
	evolution_lines.draw_line(from, to, LINE_COLOR, LINE_WIDTH, true)

func _draw_arrow(from: Vector2, to: Vector2) -> void:
	_draw_line(from, to)
	var direction := (to - from).normalized()
	var side := Vector2(-direction.y, direction.x)
	var tip := to
	var base := tip - direction * ARROW_SIZE
	var points := PackedVector2Array([
		tip,
		base + side * (ARROW_SIZE * 0.65),
		base - side * (ARROW_SIZE * 0.65)
	])
	evolution_lines.draw_colored_polygon(points, LINE_COLOR)

## 9種類が収まる間はバーを出さない。
## 将来DIAGRAM_SIZEが表示領域を超えた場合だけAUTOへ切り替える。
func _update_scroll_mode() -> void:
	var viewport_size := collection_area.size
	collection_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if DIAGRAM_SIZE.x > viewport_size.x else ScrollContainer.SCROLL_MODE_DISABLED
	collection_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if DIAGRAM_SIZE.y > viewport_size.y else ScrollContainer.SCROLL_MODE_DISABLED

func _update_back_button_text() -> void:
	if get_tree().has_meta(RETURN_SCENE_META):
		back_button.text = "タイトルにもどる"
	else:
		back_button.text = "育成画面にもどる"

func _update_collection_count() -> void:
	count_label.text = "発見数：%d / %d" % [PiyokoCollectionManager.discovered.size(), TOTAL_COLLECTION_COUNT]

func _update_collection_cards() -> void:
	_update_card("chibi", chibi_card.get_node("ChibiTexture"), chibi_card.get_node("ChibiName"), "ちびぴよこ")
	_update_card("child_food", child_cards[0].get_node("FoodChildTexture"), child_cards[0].get_node("FoodChildName"), "ごはんぴよこ")
	_update_card("child_play", child_cards[1].get_node("PlayChildTexture"), child_cards[1].get_node("PlayChildName"), "やんちゃぴよこ")
	_update_card("child_pet", child_cards[2].get_node("PetChildTexture"), child_cards[2].get_node("PetChildName"), "あまえぴよこ")
	_update_card("child_balance", child_cards[3].get_node("BalanceChildTexture"), child_cards[3].get_node("BalanceChildName"), "へいきんぴよこ")
	_update_card("adult_sweets", adult_cards[0].get_node("SweetsAdultTexture"), adult_cards[0].get_node("SweetsAdultName"), "すいーつぴよこ")
	_update_card("adult_champion", adult_cards[1].get_node("ChampionAdultTexture"), adult_cards[1].get_node("ChampionAdultName"), "ちゃんぷぴよこ")
	_update_card("adult_love", adult_cards[2].get_node("LoveAdultTexture"), adult_cards[2].get_node("LoveAdultName"), "らぶぴよこ")
	_update_card("adult_challenger", adult_cards[3].get_node("ChallengerAdultTexture"), adult_cards[3].get_node("ChallengerAdultName"), "ふぁいとぴよこ")

func _update_card(piyoko_id: String, texture_rect: TextureRect, name_label: Label, discovered_name: String) -> void:
	if PiyokoCollectionManager.is_discovered(piyoko_id):
		texture_rect.self_modulate = Color.WHITE
		name_label.text = discovered_name
	else:
		texture_rect.self_modulate = SILHOUETTE_COLOR
		name_label.text = UNDISCOVERED_NAME

func _on_back_button_pressed() -> void:
	var return_scene := DEFAULT_RETURN_SCENE
	if get_tree().has_meta(RETURN_SCENE_META):
		return_scene = str(get_tree().get_meta(RETURN_SCENE_META))
		get_tree().remove_meta(RETURN_SCENE_META)
	get_tree().change_scene_to_file(return_scene)
