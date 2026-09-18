extends Control

const MEMORIES_RETURN_SCENE_META := "memories_return_scene"
const SELECTED_MEMORY_META := "selected_memory_number"
const TITLE_SCENE := "res://scenes/main.tscn"
const PAGE_SIZE := 12
const GRID_COLUMNS := 6

var records: Array[Dictionary] = []
var current_page: int = 0
var sort_mode: int = 0

var count_label: Label
var sort_option: OptionButton
var cards_grid: GridContainer
var empty_panel: PanelContainer
var page_label: Label
var previous_button: Button
var next_button: Button


func _ready() -> void:
	_build_screen()
	_reload_records()


func _build_screen() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.20, 0.12, 0.04, 0.10)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "ピヨコのおもいで"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("fff7d5"))
	title.add_theme_color_override("font_shadow_color", Color(0.20, 0.12, 0.05, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	layout.add_child(title)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 14)
	layout.add_child(toolbar)

	var count_panel := PanelContainer.new()
	count_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_panel.add_theme_stylebox_override("panel", _make_status_style())
	toolbar.add_child(count_panel)

	count_label = Label.new()
	count_label.custom_minimum_size = Vector2(250, 42)
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 20)
	count_label.add_theme_color_override("font_color", Color("492d16"))
	count_panel.add_child(count_label)

	var sort_label := Label.new()
	sort_label.text = "並び替え"
	sort_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sort_label.add_theme_font_size_override("font_size", 17)
	sort_label.add_theme_color_override("font_color", Color("492d16"))
	toolbar.add_child(sort_label)

	sort_option = OptionButton.new()
	sort_option.custom_minimum_size = Vector2(190, 44)
	sort_option.add_item("新しい順", 0)
	sort_option.add_item("古い順", 1)
	sort_option.add_item("ピヨコの種類", 2)
	sort_option.add_theme_font_size_override("font_size", 16)
	_style_select(sort_option)
	sort_option.item_selected.connect(_on_sort_selected)
	toolbar.add_child(sort_option)

	var album_panel := PanelContainer.new()
	album_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	album_panel.add_theme_stylebox_override("panel", _make_panel_style())
	layout.add_child(album_panel)

	var album_margin := MarginContainer.new()
	album_margin.add_theme_constant_override("margin_left", 18)
	album_margin.add_theme_constant_override("margin_top", 16)
	album_margin.add_theme_constant_override("margin_right", 18)
	album_margin.add_theme_constant_override("margin_bottom", 14)
	album_panel.add_child(album_margin)

	cards_grid = GridContainer.new()
	cards_grid.columns = GRID_COLUMNS
	cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_grid.add_theme_constant_override("h_separation", 10)
	cards_grid.add_theme_constant_override("v_separation", 10)
	album_margin.add_child(cards_grid)

	empty_panel = PanelContainer.new()
	empty_panel.add_theme_stylebox_override("panel", _make_empty_style())
	album_margin.add_child(empty_panel)

	var empty_box := VBoxContainer.new()
	empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
	empty_box.add_theme_constant_override("separation", 12)
	empty_panel.add_child(empty_box)

	var empty_title := Label.new()
	empty_title.text = "まだおもいではありません"
	empty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_title.add_theme_font_size_override("font_size", 27)
	empty_title.add_theme_color_override("font_color", Color("492d16"))
	empty_box.add_child(empty_title)

	var empty_guide := Label.new()
	empty_guide.text = "大人ぴよこまで育てて「育成をおえる」と、\nここに1羽ずつ記録されます。"
	empty_guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_guide.add_theme_font_size_override("font_size", 18)
	empty_guide.add_theme_color_override("font_color", Color("58743b"))
	empty_box.add_child(empty_guide)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 14)
	layout.add_child(footer)

	var back_button := Button.new()
	back_button.text = "もどる"
	_style_button(back_button, Vector2(180, 48))
	back_button.pressed.connect(_on_back_pressed)
	footer.add_child(back_button)

	previous_button = Button.new()
	previous_button.text = "◀ 前のページ"
	_style_button(previous_button, Vector2(165, 48))
	previous_button.pressed.connect(_on_previous_page)
	footer.add_child(previous_button)

	page_label = Label.new()
	page_label.custom_minimum_size.x = 110
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_label.add_theme_font_size_override("font_size", 18)
	page_label.add_theme_color_override("font_color", Color("492d16"))
	footer.add_child(page_label)

	next_button = Button.new()
	next_button.text = "次のページ ▶"
	_style_button(next_button, Vector2(165, 48))
	next_button.pressed.connect(_on_next_page)
	footer.add_child(next_button)


func _reload_records() -> void:
	records = PiyokoMemoryManager.load_memories()
	_sort_records()
	var page_count: int = _page_count()
	current_page = clampi(current_page, 0, maxi(0, page_count - 1))
	_refresh_cards()


func _sort_records() -> void:
	match sort_mode:
		0:
			records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return str(a.get("completed_at", "")) > str(b.get("completed_at", ""))
			)
		1:
			records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return str(a.get("completed_at", "")) < str(b.get("completed_at", ""))
			)
		2:
			records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var a_name: String = _adult_name(str(a.get("adult_type", "")))
				var b_name: String = _adult_name(str(b.get("adult_type", "")))
				if a_name == b_name:
					return int(a.get("育成No", 0)) < int(b.get("育成No", 0))
				return a_name < b_name
			)


func _refresh_cards() -> void:
	for child in cards_grid.get_children():
		child.queue_free()

	count_label.text = "育てたピヨコの数：%d羽" % records.size()
	empty_panel.visible = records.is_empty()
	cards_grid.visible = not records.is_empty()

	var page_count: int = _page_count()
	page_label.text = "%d / %d" % [current_page + 1, maxi(1, page_count)]
	previous_button.disabled = current_page <= 0
	next_button.disabled = current_page + 1 >= page_count

	var start_index: int = current_page * PAGE_SIZE
	var end_index: int = mini(start_index + PAGE_SIZE, records.size())
	for index in range(start_index, end_index):
		cards_grid.add_child(_create_memory_card(records[index]))


func _create_memory_card(record: Dictionary) -> Button:
	var memory_number: int = int(record.get("育成No", 0))
	var adult_type: String = str(record.get("adult_type", ""))

	var card := Button.new()
	card.custom_minimum_size = Vector2(158, 202)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("normal", _make_card_style(Color(1.0, 0.98, 0.90, 0.96), Color("76502c"), 2))
	card.add_theme_stylebox_override("hover", _make_card_style(Color("fff1bd"), Color("6b9140"), 3))
	card.add_theme_stylebox_override("pressed", _make_card_style(Color("f7dda0"), Color("567a31"), 3))
	card.pressed.connect(_on_card_pressed.bind(memory_number))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 9
	box.offset_top = 7
	box.offset_right = -9
	box.offset_bottom = -7
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 1)
	card.add_child(box)

	var number_label := Label.new()
	number_label.text = "No.%03d" % memory_number
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_size_override("font_size", 15)
	number_label.add_theme_color_override("font_color", Color("76502c"))
	number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(number_label)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(132, 92)
	portrait.texture = PiyokoTextureManager.ADULT_TEXTURES.get(adult_type, PiyokoTextureManager.CHIBI_TEXTURE)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)

	var name_label := Label.new()
	name_label.text = _adult_name(adult_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color("492d16"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var lineage_label := Label.new()
	lineage_label.text = "%s系" % _child_short_name(str(record.get("child_type", "")))
	lineage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lineage_label.add_theme_font_size_override("font_size", 13)
	lineage_label.add_theme_color_override("font_color", Color("58743b"))
	lineage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lineage_label)

	var date_label := Label.new()
	date_label.text = _format_datetime(str(record.get("completed_at", "")))
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", Color("76502c"))
	date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(date_label)

	var favorite := Button.new()
	favorite.toggle_mode = true
	favorite.button_pressed = bool(record.get("favorite", false))
	favorite.text = "★" if favorite.button_pressed else "☆"
	favorite.tooltip_text = "お気に入りを解除" if favorite.button_pressed else "お気に入りに登録"
	favorite.anchor_left = 1.0
	favorite.anchor_right = 1.0
	favorite.offset_left = -44
	favorite.offset_top = 6
	favorite.offset_right = -7
	favorite.offset_bottom = 42
	favorite.add_theme_font_size_override("font_size", 22)
	_style_favorite_button(favorite)
	favorite.toggled.connect(_on_favorite_toggled.bind(memory_number, favorite))
	card.add_child(favorite)
	return card


func _adult_name(adult_type: String) -> String:
	var form: Dictionary = PiyokoCollectionCatalog.get_form("adult_" + adult_type)
	return str(form.get("name", "大人ぴよこ"))


func _child_short_name(child_type: String) -> String:
	var form: Dictionary = PiyokoCollectionCatalog.get_form("child_" + child_type)
	return str(form.get("name", "子ぴよこ")).trim_suffix("ぴよこ")


func _format_datetime(value: String) -> String:
	if value.is_empty():
		return "日時不明"
	return value.replace("T", " ")


func _page_count() -> int:
	return int(ceil(float(records.size()) / float(PAGE_SIZE))) if not records.is_empty() else 1


func _on_sort_selected(index: int) -> void:
	sort_mode = index
	current_page = 0
	_sort_records()
	_refresh_cards()


func _on_card_pressed(memory_number: int) -> void:
	get_tree().set_meta(SELECTED_MEMORY_META, memory_number)
	get_tree().change_scene_to_file("res://scenes/memory_detail.tscn")


func _on_favorite_toggled(enabled: bool, memory_number: int, button: Button) -> void:
	if PiyokoMemoryManager.set_favorite(memory_number, enabled):
		button.text = "★" if enabled else "☆"
		button.tooltip_text = "お気に入りを解除" if enabled else "お気に入りに登録"
		for record in records:
			if int(record.get("育成No", 0)) == memory_number:
				record["favorite"] = enabled
				break
	else:
		button.set_pressed_no_signal(not enabled)


func _on_previous_page() -> void:
	if current_page > 0:
		current_page -= 1
		_refresh_cards()


func _on_next_page() -> void:
	if current_page + 1 < _page_count():
		current_page += 1
		_refresh_cards()


func _on_back_pressed() -> void:
	var return_scene: String = TITLE_SCENE
	if get_tree().has_meta(MEMORIES_RETURN_SCENE_META):
		return_scene = str(get_tree().get_meta(MEMORIES_RETURN_SCENE_META))
		get_tree().remove_meta(MEMORIES_RETURN_SCENE_META)
	get_tree().change_scene_to_file(return_scene)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.84, 0.93)
	style.border_color = Color("76502c")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.12, 0.20, 0.08, 0.34)
	style.shadow_size = 8
	return style


func _make_empty_style() -> StyleBoxFlat:
	var style := _make_panel_style()
	style.bg_color = Color(1.0, 0.98, 0.88, 0.96)
	return style


func _make_card_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0.18, 0.12, 0.05, 0.24)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _style_button(button: Button, minimum_size: Vector2) -> void:
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("492d16"))
	button.add_theme_color_override("font_hover_color", Color("384514"))
	button.add_theme_stylebox_override("normal", _make_card_style(Color("fff7d5"), Color("76502c"), 2))
	button.add_theme_stylebox_override("hover", _make_card_style(Color("ffe38a"), Color("6b9140"), 3))
	button.add_theme_stylebox_override("pressed", _make_card_style(Color("f5ce63"), Color("567a31"), 3))


func _make_status_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.84, 0.94)
	style.border_color = Color("93aa66")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style


func _style_select(option: OptionButton) -> void:
	option.alignment = HORIZONTAL_ALIGNMENT_CENTER
	option.add_theme_color_override("font_color", Color("492d16"))
	option.add_theme_color_override("font_hover_color", Color("384514"))
	option.add_theme_stylebox_override("normal", _make_card_style(Color("fff7d5"), Color("76502c"), 2))
	option.add_theme_stylebox_override("hover", _make_card_style(Color("ffe38a"), Color("6b9140"), 3))
	option.add_theme_stylebox_override("pressed", _make_card_style(Color("f5ce63"), Color("567a31"), 3))

	var popup: PopupMenu = option.get_popup()
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color("492d16"))
	popup.add_theme_color_override("font_hover_color", Color("384514"))
	popup.add_theme_color_override("font_checked_color", Color("6b9140"))
	popup.add_theme_color_override("font_separator_color", Color("76502c"))
	popup.add_theme_constant_override("item_start_padding", 12)
	popup.add_theme_constant_override("item_end_padding", 12)
	popup.add_theme_constant_override("v_separation", 8)
	popup.add_theme_stylebox_override("panel", _make_popup_panel_style())
	popup.add_theme_stylebox_override("hover", _make_popup_hover_style())


func _style_favorite_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color("a67b24"))
	button.add_theme_color_override("font_hover_color", Color("d89d00"))
	button.add_theme_color_override("font_pressed_color", Color("d89d00"))
	button.add_theme_stylebox_override("normal", _make_card_style(Color("fff9df"), Color("c6a15b"), 1))
	button.add_theme_stylebox_override("hover", _make_card_style(Color("fff0aa"), Color("d89d00"), 2))
	button.add_theme_stylebox_override("pressed", _make_card_style(Color("ffe38a"), Color("d89d00"), 2))



func _make_popup_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.84, 0.99)
	style.border_color = Color("76502c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 6
	style.content_margin_top = 7
	style.content_margin_right = 6
	style.content_margin_bottom = 7
	style.shadow_color = Color(0.18, 0.12, 0.05, 0.34)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


func _make_popup_hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ffe38a")
	style.border_color = Color("93aa66")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
