extends Control

## ピヨコ図鑑画面。
## たまご1種 → ちびぴよこ1種 → 子ぴよこ4種 → 大人ぴよこ8種を、
## 1枚のキャンバス上へ系統図として配置する。

const TOTAL_COLLECTION_COUNT := 14
const UNDISCOVERED_NAME := "？？？"
const SILHOUETTE_COLOR := Color(0.12, 0.12, 0.12, 1.0)
const DEFAULT_RETURN_SCENE := "res://scenes/game.tscn"
const RETURN_SCENE_META := "collection_return_scene"

const FRAME_TEXTURE := preload("res://assets/ui/panels/frame_card.png")

const CARD_SIZE := Vector2(126.0, 96.0)
const CARD_TEXTURE_POSITION := Vector2(6.0, 3.0)
const CARD_TEXTURE_SIZE := Vector2(114.0, 66.0)
const CARD_NAME_POSITION := Vector2(4.0, 69.0)
const CARD_NAME_SIZE := Vector2(118.0, 24.0)
const CARD_NAME_FONT_SIZE := 12

# 1280x720の画面内で14形態を確認できるサイズ。
const DIAGRAM_SIZE := Vector2(1140.0, 442.0)
const CENTER_CARD_X := 507.0
const EGG_Y := 0.0
const CHIBI_Y := 110.0
const CHILD_Y := 220.0
const ADULT_Y := 330.0
const CHILD_X := [164.0, 420.0, 676.0, 932.0]
const ADULT_X := [100.0, 228.0, 356.0, 484.0, 612.0, 740.0, 868.0, 996.0]
const STAGE_LABEL_X := 2.0

const LINE_COLOR := Color(0.25, 0.14, 0.07, 0.95)
const LINE_WIDTH := 3.0
const ARROW_SIZE := 7.0
const LINE_GAP := 5.0

const FORM_DATA := [
	{"id": "egg", "name": "たまご", "texture": PiyokoTextureManager.EGG_TEXTURE},
	{"id": "chibi", "name": "ちびぴよこ", "texture": PiyokoTextureManager.CHIBI_TEXTURE},
	{"id": "child_food", "name": "ごはんぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["food"]},
	{"id": "child_play", "name": "やんちゃぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["play"]},
	{"id": "child_pet", "name": "あまえぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["pet"]},
	{"id": "child_balance", "name": "へいきんぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["balance"]},
	{"id": "adult_sweets", "name": "すいーつぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["sweets"]},
	{"id": "adult_gourmet", "name": "ぐるめぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["gourmet"]},
	{"id": "adult_champion", "name": "ちゃんぷぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["champion"]},
	{"id": "adult_challenger", "name": "ふぁいとぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["challenger"]},
	{"id": "adult_love", "name": "らぶぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["love"]},
	{"id": "adult_nap", "name": "おひるねぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["nap"]},
	{"id": "adult_rainbow", "name": "にじいろぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["rainbow"]},
	{"id": "adult_oshimotif", "name": "おしモチーフぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["oshimotif"]},
]

@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton
@onready var collection_area: ScrollContainer = $MainMargin/CollectionLayout/CollectionArea
@onready var evolution_tree: VBoxContainer = $MainMargin/CollectionLayout/CollectionArea/EvolutionTree

var diagram_canvas: Control
var evolution_lines: Control
var cards: Dictionary = {}


func _ready() -> void:
	_build_diagram_canvas()
	_setup_stage_labels()
	_setup_evolution_lines()
	_update_collection_count()
	_update_collection_cards()
	_update_back_button_text()
	back_button.pressed.connect(_on_back_button_pressed)
	call_deferred("_finish_layout")


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
	diagram_canvas.custom_minimum_size = DIAGRAM_SIZE
	diagram_canvas.size = DIAGRAM_SIZE
	diagram_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	evolution_tree.add_child(diagram_canvas)

	_create_card(FORM_DATA[0], Vector2(CENTER_CARD_X, EGG_Y))
	_create_card(FORM_DATA[1], Vector2(CENTER_CARD_X, CHIBI_Y))

	for i in 4:
		_create_card(FORM_DATA[i + 2], Vector2(CHILD_X[i], CHILD_Y))

	for i in 8:
		_create_card(FORM_DATA[i + 6], Vector2(ADULT_X[i], ADULT_Y))


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
	name_label.add_theme_font_size_override("font_size", CARD_NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", Color(0.20, 0.12, 0.07, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	diagram_canvas.add_child(card)
	cards[str(form["id"])] = card


func _setup_stage_labels() -> void:
	_add_stage_label("たまご", Vector2(STAGE_LABEL_X, EGG_Y + 31.0), Color(1.0, 0.93, 0.68, 0.96))
	_add_stage_label("ちび", Vector2(STAGE_LABEL_X, CHIBI_Y + 31.0), Color(0.98, 0.82, 0.49, 0.96))
	_add_stage_label("子ぴよこ", Vector2(STAGE_LABEL_X, CHILD_Y + 31.0), Color(1.0, 0.76, 0.80, 0.96))
	_add_stage_label("大人", Vector2(STAGE_LABEL_X, ADULT_Y + 31.0), Color(0.67, 0.88, 1.0, 0.96))


func _add_stage_label(text_value: String, target_position: Vector2, background_color: Color) -> void:
	var panel := PanelContainer.new()
	panel.position = target_position
	panel.size = Vector2(90.0, 34.0)
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
	label.custom_minimum_size = Vector2(82.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08, 1.0))
	panel.add_child(label)
	diagram_canvas.add_child(panel)


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
	# たまご → ちびぴよこ。
	_draw_arrow(
		_bottom_center(cards["egg"]) + Vector2(0.0, LINE_GAP),
		_top_center(cards["chibi"]) - Vector2(0.0, LINE_GAP)
	)

	# ちびぴよこ → 子ぴよこ4種。
	_draw_branch(
		cards["chibi"],
		[cards["child_food"], cards["child_play"], cards["child_pet"], cards["child_balance"]]
	)

	# 子ぴよこごとに、大人ぴよこ2種へ分岐する。
	_draw_branch(cards["child_food"], [cards["adult_sweets"], cards["adult_gourmet"]])
	_draw_branch(cards["child_play"], [cards["adult_champion"], cards["adult_challenger"]])
	_draw_branch(cards["child_pet"], [cards["adult_love"], cards["adult_nap"]])
	_draw_branch(cards["child_balance"], [cards["adult_rainbow"], cards["adult_oshimotif"]])


func _draw_branch(source_card: Control, target_cards: Array) -> void:
	var start := _bottom_center(source_card)
	var target_tops: Array[Vector2] = []
	for target_card in target_cards:
		target_tops.append(_top_center(target_card as Control))

	var branch_y := start.y + ((target_tops[0].y - start.y) * 0.48)
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
	_draw_line(from, to)
	var direction := (to - from).normalized()
	var side := Vector2(-direction.y, direction.x)
	var base := to - direction * ARROW_SIZE
	var points := PackedVector2Array([
		to,
		base + side * (ARROW_SIZE * 0.65),
		base - side * (ARROW_SIZE * 0.65)
	])
	evolution_lines.draw_colored_polygon(points, LINE_COLOR)


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
	var discovered_count := 0
	for form in FORM_DATA:
		if PiyokoCollectionManager.is_discovered(str(form["id"])):
			discovered_count += 1
	count_label.text = "発見数：%d / %d" % [discovered_count, TOTAL_COLLECTION_COUNT]


func _update_collection_cards() -> void:
	for form in FORM_DATA:
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


func _on_back_button_pressed() -> void:
	var return_scene := DEFAULT_RETURN_SCENE
	if get_tree().has_meta(RETURN_SCENE_META):
		return_scene = str(get_tree().get_meta(RETURN_SCENE_META))
		get_tree().remove_meta(RETURN_SCENE_META)
	get_tree().change_scene_to_file(return_scene)
