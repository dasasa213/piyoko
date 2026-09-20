extends Control

## ピヨコ図鑑画面。
## ちびぴよこ1種 → 子ぴよこ5種 → 大人ぴよこ15種を、
## 1枚のキャンバス上へ系統図として配置する。

const UNDISCOVERED_NAME := "???"
const SILHOUETTE_COLOR := Color(0.12, 0.12, 0.12, 1.0)
const DEFAULT_RETURN_SCENE := "res://scenes/game.tscn"
const RETURN_SCENE_META := "collection_return_scene"
const SELECTED_ID_META := "collection_selected_id"

const FRAME_TEXTURE := preload("res://assets/ui/panels/frame_card.png")

const CARD_SIZE := Vector2(165.0, 130.0)
const CARD_TEXTURE_POSITION := Vector2(7.5, 5.0)
const CARD_TEXTURE_SIZE := Vector2(150.0, 90.0)
const CARD_NAME_POSITION := Vector2(5.0, 96.0)
const CARD_NAME_SIZE := Vector2(155.0, 29.0)
const CARD_NAME_FONT_SIZE := 14

# 全21形態を矢印ごと崩さず確認できる横長キャンバス。
const CHIBI_Y := 0.0
const CHILD_Y := 200.0
const ADULT_Y := 405.0
const CARD_STEP_X := 190.0
const BRANCH_GAP_X := 45.0

const LINE_COLOR := Color(0.25, 0.14, 0.07, 0.95)
const LINE_WIDTH := 4.0
const ARROW_SIZE := 9.0
const ARROW_LINE_GAP := 5.0
const LINE_GAP := 14.0

@onready var title_label: Label = $MainMargin/CollectionLayout/TitleLabel
@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton
@onready var collection_area: ScrollContainer = $MainMargin/CollectionLayout/CollectionArea
@onready var evolution_tree: VBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree

var diagram_canvas: Control
var evolution_lines: Control
var cards: Dictionary = {}
var form_data: Array[Dictionary] = []
var diagram_size := Vector2(3200.0, 570.0)
var center_card_x := 1420.0
var child_x: Array[float] = []
var adult_x: Array[float] = []


func _ready() -> void:
	form_data = PiyokoCollectionCatalog.get_forms()
	_calculate_diagram_positions()
	_build_diagram_canvas()
	_setup_evolution_lines()
	_update_collection_count()
	_update_collection_cards()
	_update_back_button_text()
	_style_collection_controls()
	back_button.pressed.connect(_on_back_button_pressed)
	call_deferred("_finish_layout")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and OS.has_feature("mobile"):
		_on_back_button_pressed()


func _style_collection_controls() -> void:
	# 系統図・矢印・カード配置には触れず、画面外周の案内と戻る操作だけを整える。
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color("fff7d5"))
	title_label.add_theme_color_override("font_shadow_color", Color(0.20, 0.12, 0.05, 0.92))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 3)

	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", Color("fff1b8"))
	count_label.add_theme_color_override("font_shadow_color", Color(0.20, 0.12, 0.05, 0.92))
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 2)

	back_button.custom_minimum_size = Vector2(300, 56)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 19)
	back_button.add_theme_color_override("font_color", Color("492d16"))
	back_button.add_theme_color_override("font_hover_color", Color("384514"))
	back_button.add_theme_color_override("font_pressed_color", Color("492d16"))
	back_button.add_theme_color_override("font_focus_color", Color("492d16"))
	back_button.add_theme_color_override("font_disabled_color", Color("75654e"))
	back_button.add_theme_stylebox_override("normal", _make_collection_button_style(Color("fff7d5"), Color("76502c"), 2))
	back_button.add_theme_stylebox_override("hover", _make_collection_button_style(Color("ffe38a"), Color("6b9140"), 3))
	back_button.add_theme_stylebox_override("pressed", _make_collection_button_style(Color("f5ce63"), Color("567a31"), 3))
	back_button.add_theme_stylebox_override("focus", _make_collection_button_style(Color("fff7d5"), Color("6b9140"), 3))


func _make_collection_button_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24.0
	style.content_margin_top = 10.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.18, 0.12, 0.05, 0.28)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style


func _build_diagram_canvas() -> void:
	# 旧9種類用の行は互換性のためシーンへ残し、画面上では使用しない。
	for row_name in ["ChibiRow", "ChildRow", "AdultRow", "FutureSpace"]:
		var old_row := evolution_tree.get_node_or_null(row_name) as Control
		if old_row != null:
			old_row.hide()
			old_row.custom_minimum_size = Vector2.ZERO

	evolution_tree.custom_minimum_size = Vector2.ZERO
	evolution_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evolution_tree.add_theme_constant_override("separation", 0)

	diagram_canvas = Control.new()
	diagram_canvas.name = "DiagramCanvas"
	diagram_canvas.custom_minimum_size = diagram_size
	diagram_canvas.size = diagram_size
	diagram_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	evolution_tree.add_child(diagram_canvas)

	_create_card(form_data[0], Vector2(center_card_x, CHIBI_Y))

	var child_forms := PiyokoDefinitionCatalog.get_stage_forms("child")
	for i in child_forms.size():
		_create_card(PiyokoCollectionCatalog.get_form(str(child_forms[i]["id"])), Vector2(child_x[i], CHILD_Y))

	var adult_position_index := 0
	for child in child_forms:
		for adult in PiyokoDefinitionCatalog.get_adults_for_lineage(str(child["lineage"])):
			_create_card(
				PiyokoCollectionCatalog.get_form(str(adult["id"])),
				Vector2(adult_x[adult_position_index], ADULT_Y)
			)
			adult_position_index += 1


func _calculate_diagram_positions() -> void:
	child_x.clear()
	adult_x.clear()
	var cursor_x := 0.0
	var children := PiyokoDefinitionCatalog.get_stage_forms("child")
	for child in children:
		var adults := PiyokoDefinitionCatalog.get_adults_for_lineage(str(child["lineage"]))
		var branch_count := maxi(1, adults.size())
		child_x.append(cursor_x + float(branch_count - 1) * CARD_STEP_X * 0.5)
		for index in branch_count:
			adult_x.append(cursor_x + float(index) * CARD_STEP_X)
		cursor_x += float(branch_count) * CARD_STEP_X + BRANCH_GAP_X
	diagram_size.x = maxf(1280.0, cursor_x - BRANCH_GAP_X + CARD_SIZE.x)
	center_card_x = child_x[floori(child_x.size() * 0.5)] if not child_x.is_empty() else 0.0


func _create_card(form: Dictionary, target_position: Vector2) -> void:
	var card := Control.new()
	card.name = str(form["id"]).to_pascal_case() + "Card"
	card.position = target_position
	card.size = CARD_SIZE
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index = 2

	var frame := NinePatchRect.new()
	frame.name = "Frame"
	card.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.texture = FRAME_TEXTURE
	frame.patch_margin_left = 24
	frame.patch_margin_top = 24
	frame.patch_margin_right = 24
	frame.patch_margin_bottom = 24
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var texture_rect := TextureRect.new()
	texture_rect.name = "PiyokoTexture"
	texture_rect.position = CARD_TEXTURE_POSITION
	texture_rect.size = CARD_TEXTURE_SIZE
	texture_rect.texture = form["texture"] as Texture2D
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(texture_rect)

	var name_label := Label.new()
	name_label.name = "PiyokoName"
	name_label.position = CARD_NAME_POSITION
	name_label.size = CARD_NAME_SIZE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", CARD_NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", Color(0.20, 0.12, 0.07, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	# 見た目を変えず、カード全体を詳細画面へのボタンとして扱う。
	var open_button := Button.new()
	open_button.name = "OpenDetailButton"
	open_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	open_button.flat = true
	open_button.text = ""
	open_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	open_button.tooltip_text = "詳細を見る"
	# タッチドラッグを親のScrollContainerへ渡す。
	open_button.mouse_filter = Control.MOUSE_FILTER_PASS
	open_button.pressed.connect(_on_card_pressed.bind(str(form["id"])))
	card.add_child(open_button)

	diagram_canvas.add_child(card)
	cards[str(form["id"])] = card


func _setup_evolution_lines() -> void:
	evolution_lines = Control.new()
	evolution_lines.name = "EvolutionLines"
	evolution_lines.position = Vector2.ZERO
	evolution_lines.size = diagram_size
	evolution_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	evolution_lines.z_index = 1
	evolution_lines.draw.connect(_draw_evolution_lines)
	diagram_canvas.add_child(evolution_lines)


func _finish_layout() -> void:
	_update_scroll_mode()
	collection_area.scroll_horizontal = maxi(0, int(center_card_x - collection_area.size.x * 0.5 + CARD_SIZE.x * 0.5))
	if evolution_lines != null:
		evolution_lines.queue_redraw()


func _draw_evolution_lines() -> void:
	var child_cards: Array = []
	for child in PiyokoDefinitionCatalog.get_stage_forms("child"):
		child_cards.append(cards[str(child["id"])])
	_draw_branch(cards["chibi"], child_cards)

	for child in PiyokoDefinitionCatalog.get_stage_forms("child"):
		var adult_cards: Array = []
		for adult in PiyokoDefinitionCatalog.get_adults_for_lineage(str(child["lineage"])):
			adult_cards.append(cards[str(adult["id"])])
		if not adult_cards.is_empty():
			_draw_branch(cards[str(child["id"])], adult_cards)


func _draw_branch(source_card: Control, target_cards: Array) -> void:
	var start := _bottom_center(source_card)
	var target_tops: Array[Vector2] = []
	for target_card in target_cards:
		target_tops.append(_top_center(target_card as Control))

	var branch_y := start.y + ((target_tops[0].y - start.y) * 0.5)
	_draw_line(start + Vector2(0.0, LINE_GAP), Vector2(start.x, branch_y))
	_draw_line(Vector2(target_tops[0].x, branch_y), Vector2(target_tops[-1].x, branch_y))

	for target in target_tops:
		_draw_arrow(Vector2(target.x, branch_y), target - Vector2(0.0, LINE_GAP))


func _top_center(card: Control) -> Vector2:
	return card.position + Vector2(card.size.x * 0.5, 0.0)


func _bottom_center(card: Control) -> Vector2:
	return card.position + Vector2(card.size.x * 0.5, card.size.y)


func _draw_line(from: Vector2, to: Vector2) -> void:
	evolution_lines.draw_line(from, to, LINE_COLOR, LINE_WIDTH, true)


func _draw_arrow(from: Vector2, to: Vector2) -> void:
	var direction := (to - from).normalized()
	var side := Vector2(-direction.y, direction.x)
	var base := to - direction * ARROW_SIZE
	# 線を三角形の手前で止め、▼が線に埋もれないようにする。
	_draw_line(from, base - direction * ARROW_LINE_GAP)
	var points := PackedVector2Array([
		to,
		base + side * (ARROW_SIZE * 0.65),
		base - side * (ARROW_SIZE * 0.65)
	])
	evolution_lines.draw_colored_polygon(points, LINE_COLOR)


func _update_scroll_mode() -> void:
	var viewport_size := collection_area.size
	collection_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if diagram_size.x > viewport_size.x else ScrollContainer.SCROLL_MODE_DISABLED
	collection_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if diagram_size.y > viewport_size.y else ScrollContainer.SCROLL_MODE_DISABLED


## Androidではボタンに遮られる前の画面入力からスワイプを取得する。
## カード上から始めた操作でも図鑑全体をドラッグできる。
func _input(event: InputEvent) -> void:
	if not OS.has_feature("mobile") or not (event is InputEventScreenDrag):
		return
	var drag := event as InputEventScreenDrag
	if not collection_area.get_global_rect().has_point(drag.position):
		return
	collection_area.scroll_horizontal -= int(round(drag.relative.x))
	collection_area.scroll_vertical -= int(round(drag.relative.y))
	get_viewport().set_input_as_handled()


func _update_back_button_text() -> void:
	if get_tree().has_meta(RETURN_SCENE_META):
		back_button.text = "タイトルにもどる"
	else:
		back_button.text = "育成画面にもどる"


func _update_collection_count() -> void:
	var discovered_count := 0
	for form in form_data:
		if PiyokoCollectionManager.is_discovered(str(form["id"])):
			discovered_count += 1
	count_label.text = "発見数：%d / %d" % [discovered_count, form_data.size()]


func _update_collection_cards() -> void:
	for form in form_data:
		var piyoko_id := str(form["id"])
		var card := cards[piyoko_id] as Control
		var texture_rect := card.get_node("PiyokoTexture") as TextureRect
		var name_label := card.get_node("PiyokoName") as Label

		if PiyokoCollectionManager.is_discovered(piyoko_id):
			texture_rect.self_modulate = Color.WHITE
			name_label.text = str(form["name"])
		else:
			texture_rect.self_modulate = SILHOUETTE_COLOR
			name_label.text = UNDISCOVERED_NAME


func _on_card_pressed(piyoko_id: String) -> void:
	get_tree().set_meta(SELECTED_ID_META, piyoko_id)
	get_tree().change_scene_to_file("res://scenes/collection_detail.tscn")


func _on_back_button_pressed() -> void:
	var return_scene := DEFAULT_RETURN_SCENE
	if get_tree().has_meta(RETURN_SCENE_META):
		return_scene = str(get_tree().get_meta(RETURN_SCENE_META))
		get_tree().remove_meta(RETURN_SCENE_META)
	get_tree().change_scene_to_file(return_scene)
