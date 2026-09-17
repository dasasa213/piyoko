extends Control

## 図鑑で選択した1形態の詳細を表示する独立画面。
## 系統図は変更せず、collection.gd から選択IDだけ受け取る。

const SELECTED_ID_META := "collection_selected_id"
const SILHOUETTE_COLOR := Color(0.12, 0.12, 0.12, 1.0)
const BACKGROUND_TEXTURE := preload("res://assets/backgrounds/03_encyclopedia_room.png")

var selected_form: Dictionary
var discovered := false


func _ready() -> void:
	var piyoko_id := str(get_tree().get_meta(SELECTED_ID_META, ""))
	selected_form = PiyokoCollectionCatalog.get_form(piyoko_id)
	if selected_form.is_empty():
		get_tree().change_scene_to_file("res://scenes/collection.tscn")
		return

	discovered = PiyokoCollectionManager.is_discovered(piyoko_id)
	_build_screen(piyoko_id)


func _build_screen(piyoko_id: String) -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.12, 0.08, 0.04, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 58)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 58)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "ピヨコ図鑑　― 詳細 ―"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("fff7d5"))
	title.add_theme_color_override("font_shadow_color", Color(0.20, 0.12, 0.05, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	layout.add_child(title)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _make_panel_style())
	layout.add_child(detail_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 28)
	panel_margin.add_theme_constant_override("margin_top", 22)
	panel_margin.add_theme_constant_override("margin_right", 28)
	panel_margin.add_theme_constant_override("margin_bottom", 22)
	detail_panel.add_child(panel_margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	panel_margin.add_child(columns)

	_build_portrait_column(columns)
	_build_information_column(columns, piyoko_id)

	var back_button := Button.new()
	back_button.text = "図鑑にもどる"
	back_button.custom_minimum_size = Vector2(300, 56)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 19)
	back_button.add_theme_color_override("font_color", Color("492d16"))
	back_button.add_theme_color_override("font_hover_color", Color("384514"))
	back_button.add_theme_color_override("font_pressed_color", Color("492d16"))
	back_button.add_theme_color_override("font_focus_color", Color("492d16"))
	back_button.add_theme_stylebox_override("normal", _make_button_style(Color("fff7d5"), Color("76502c"), 2))
	back_button.add_theme_stylebox_override("hover", _make_button_style(Color("ffe38a"), Color("6b9140"), 3))
	back_button.add_theme_stylebox_override("pressed", _make_button_style(Color("f5ce63"), Color("567a31"), 3))
	back_button.add_theme_stylebox_override("focus", _make_button_style(Color("fff7d5"), Color("6b9140"), 3))
	back_button.pressed.connect(_on_back_button_pressed)
	layout.add_child(back_button)


func _build_portrait_column(parent: HBoxContainer) -> void:
	var portrait_column := VBoxContainer.new()
	portrait_column.custom_minimum_size = Vector2(390, 0)
	portrait_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_column.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_column.add_theme_constant_override("separation", 8)
	parent.add_child(portrait_column)

	var image_panel := PanelContainer.new()
	image_panel.custom_minimum_size = Vector2(360, 330)
	image_panel.add_theme_stylebox_override("panel", _make_image_style())
	portrait_column.add_child(image_panel)

	var texture_rect := TextureRect.new()
	texture_rect.texture = selected_form["texture"] as Texture2D
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.self_modulate = Color.WHITE if discovered else SILHOUETTE_COLOR
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_panel.add_child(texture_rect)

	var name_label := Label.new()
	name_label.text = str(selected_form["name"]) if discovered else "？？？"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Color("492d16"))
	portrait_column.add_child(name_label)

	var state_label := Label.new()
	state_label.text = "発見済み" if discovered else "まだ見つけていません"
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 17)
	state_label.add_theme_color_override("font_color", Color("58743b") if discovered else Color("76502c"))
	portrait_column.add_child(state_label)


func _build_information_column(parent: HBoxContainer, piyoko_id: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var information := VBoxContainer.new()
	information.custom_minimum_size = Vector2(0, 480)
	information.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	information.add_theme_constant_override("separation", 11)
	scroll.add_child(information)

	_add_heading(information, "基本情報")
	_add_info(information, "成長段階", str(selected_form["stage"]))

	if discovered:
		var discovered_date := PiyokoCollectionManager.get_discovered_date(piyoko_id)
		_add_info(information, "発見日", discovered_date if not discovered_date.is_empty() else "記録なし")
		_add_info(information, "好物", "ショートケーキ")
		_add_info(information, "苦手", "ブロッコリー")
		_add_heading(information, "このピヨコについて")
		_add_description(information, str(selected_form["description"]))
		_add_heading(information, "成長経路")
		_add_info(information, "成長元", str(selected_form["previous"]))
		_add_info(information, "次の成長先", str(selected_form["next"]))
		_add_heading(information, "発見条件")
		_add_description(information, PiyokoCollectionCatalog.get_condition(piyoko_id))
	else:
		_add_heading(information, "成長のヒント")
		_add_description(information, PiyokoCollectionCatalog.get_hint(piyoko_id))
		_add_heading(information, "系統")
		_add_description(information, "詳しい名前や条件は、発見すると確認できるようになります。\n系統図のつながりを手がかりに育ててみましょう。")


func _add_heading(parent: VBoxContainer, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color("58743b"))
	parent.add_child(label)


func _add_info(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 125
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("76502c"))
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.add_theme_font_size_override("font_size", 17)
	value.add_theme_color_override("font_color", Color("342315"))
	row.add_child(value)


func _add_description(parent: VBoxContainer, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 48
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("342315"))
	parent.add_child(label)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.86, 0.96)
	style.border_color = Color("76502c")
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.16, 0.10, 0.04, 0.35)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style


func _make_image_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.99, 0.94, 0.92)
	style.border_color = Color("6b9140")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	return style


func _make_button_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24
	style.content_margin_top = 10
	style.content_margin_right = 24
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.18, 0.12, 0.05, 0.28)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style


func _on_back_button_pressed() -> void:
	get_tree().set_meta(SELECTED_ID_META, "")
	get_tree().change_scene_to_file("res://scenes/collection.tscn")
