extends Control

const SELECTED_MEMORY_META := "selected_memory_number"

var record: Dictionary
var favorite_button: CheckButton


func _ready() -> void:
	var memory_number: int = int(get_tree().get_meta(SELECTED_MEMORY_META, 0))
	record = PiyokoMemoryManager.get_memory(memory_number)
	if record.is_empty():
		get_tree().change_scene_to_file("res://scenes/memories.tscn")
		return
	_build_screen()


func _build_screen() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.20, 0.12, 0.04, 0.10)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)

	var header_spacer := Control.new()
	header_spacer.custom_minimum_size.x = 180
	header.add_child(header_spacer)

	var title := Label.new()
	title.text = "おもいで詳細　No.%03d" % int(record.get("育成No", 0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("fff7d5"))
	title.add_theme_color_override("font_shadow_color", Color(0.20, 0.12, 0.05, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	header.add_child(title)

	favorite_button = CheckButton.new()
	favorite_button.text = "★ お気に入り"
	favorite_button.custom_minimum_size.x = 180
	favorite_button.button_pressed = bool(record.get("favorite", false))
	favorite_button.add_theme_font_size_override("font_size", 17)
	favorite_button.add_theme_color_override("font_color", Color("fff1b8"))
	favorite_button.add_theme_color_override("font_pressed_color", Color("ffd34f"))
	favorite_button.toggled.connect(_on_favorite_toggled)
	header.add_child(favorite_button)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _make_panel_style())
	layout.add_child(detail_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 24)
	panel_margin.add_theme_constant_override("margin_top", 18)
	panel_margin.add_theme_constant_override("margin_right", 24)
	panel_margin.add_theme_constant_override("margin_bottom", 18)
	detail_panel.add_child(panel_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel_margin.add_child(content)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	content.add_child(columns)

	_build_profile(columns)
	_add_vertical_divider(columns)
	_build_care_record(columns)
	_add_vertical_divider(columns)
	_build_lineage(columns)

	var feature_panel := PanelContainer.new()
	feature_panel.custom_minimum_size.y = 92
	feature_panel.add_theme_stylebox_override("panel", _make_feature_style())
	content.add_child(feature_panel)

	var feature_box := VBoxContainer.new()
	feature_box.add_theme_constant_override("separation", 4)
	feature_panel.add_child(feature_box)
	feature_box.add_child(_make_section_title("この子の特徴"))

	var adult_form: Dictionary = PiyokoCollectionCatalog.get_form("adult_" + str(record.get("adult_type", "")))
	var feature := Label.new()
	feature.text = str(adult_form.get("description", "大切に育てられたピヨコです。"))
	feature.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feature.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feature.add_theme_font_size_override("font_size", 17)
	feature.add_theme_color_override("font_color", Color("492d16"))
	feature_box.add_child(feature)

	var back_button := Button.new()
	back_button.text = "おもいで一覧にもどる"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_button(back_button)
	back_button.pressed.connect(_on_back_pressed)
	layout.add_child(back_button)


func _build_profile(parent: HBoxContainer) -> void:
	var adult_type: String = str(record.get("adult_type", ""))
	var adult_form: Dictionary = PiyokoCollectionCatalog.get_form("adult_" + adult_type)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(270, 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 5)
	parent.add_child(column)

	column.add_child(_make_section_title("育てたピヨコ"))

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(230, 210)
	portrait.texture = PiyokoTextureManager.ADULT_TEXTURES.get(adult_type, PiyokoTextureManager.CHIBI_TEXTURE)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(portrait)

	var name_label := Label.new()
	name_label.text = str(adult_form.get("name", "大人ぴよこ"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 25)
	name_label.add_theme_color_override("font_color", Color("492d16"))
	column.add_child(name_label)

	var child_form: Dictionary = PiyokoCollectionCatalog.get_form("child_" + str(record.get("child_type", "")))
	_add_center_info(column, "子ども形態：%s" % str(child_form.get("name", "子ぴよこ")))
	_add_center_info(column, "育成開始：%s" % _format_datetime(str(record.get("started_at", ""))))
	_add_center_info(column, "育成完了：%s" % _format_datetime(str(record.get("completed_at", ""))))


func _build_care_record(parent: HBoxContainer) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(390, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 7)
	parent.add_child(column)

	column.add_child(_make_section_title("お世話のきろく"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 5)
	column.add_child(grid)

	_add_value_row(grid, "お世話合計", _count_text("total_care_count"))
	_add_value_row(grid, "ごはん合計", _count_text("food_count"))
	_add_value_row(grid, "ショートケーキ", _count_text("shortcake_count"))
	_add_value_row(grid, "おにぎり", _count_text("onigiri_count"))
	_add_value_row(grid, "ブロッコリー", _count_text("broccoli_count"))
	_add_value_row(grid, "なでる", _count_text("pet_count"))
	_add_value_row(grid, "あそぶ合計", _count_text("play_count"))
	_add_value_row(grid, "あそぶ成功", _count_text("play_success_count"))
	_add_value_row(grid, "あそぶ失敗", _count_text("play_failure_count"))


func _build_lineage(parent: HBoxContainer) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(250, 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	parent.add_child(column)
	column.add_child(_make_section_title("進化のながれ"))

	var lineage: Array = record.get("lineage", []) as Array
	if typeof(lineage) != TYPE_ARRAY:
		return
	for index in range(lineage.size()):
		var form_id: String = str(lineage[index])
		var form: Dictionary = PiyokoCollectionCatalog.get_form(form_id)
		var texture := TextureRect.new()
		texture.custom_minimum_size = Vector2(120, 78)
		texture.texture = form.get("texture", PiyokoTextureManager.CHIBI_TEXTURE) as Texture2D
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		column.add_child(texture)

		var name_label := Label.new()
		name_label.text = str(form.get("name", "ピヨコ"))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", Color("492d16"))
		column.add_child(name_label)

		if index + 1 < lineage.size():
			var arrow := Label.new()
			arrow.text = "▼"
			arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			arrow.add_theme_font_size_override("font_size", 18)
			arrow.add_theme_color_override("font_color", Color("76502c"))
			column.add_child(arrow)


func _count_text(key: String) -> String:
	return "%d 回" % int(record.get(key, 0))


func _format_datetime(value: String) -> String:
	if value.is_empty():
		return "記録なし"
	return value.replace("T", " ")


func _add_center_info(parent: VBoxContainer, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("76502c"))
	parent.add_child(label)


func _add_value_row(grid: GridContainer, item_name: String, value_text: String) -> void:
	var item := Label.new()
	item.text = item_name
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_theme_font_size_override("font_size", 16)
	item.add_theme_color_override("font_color", Color("76502c"))
	grid.add_child(item)

	var value := Label.new()
	value.text = value_text
	value.custom_minimum_size.x = 105
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 17)
	value.add_theme_color_override("font_color", Color("492d16"))
	grid.add_child(value)


func _make_section_title(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color("58743b"))
	return label


func _add_vertical_divider(parent: HBoxContainer) -> void:
	var divider := VSeparator.new()
	divider.add_theme_color_override("separator", Color("93aa66"))
	divider.add_theme_constant_override("separation", 3)
	parent.add_child(divider)


func _on_favorite_toggled(enabled: bool) -> void:
	if PiyokoMemoryManager.set_favorite(int(record.get("育成No", 0)), enabled):
		record["favorite"] = enabled
	else:
		favorite_button.set_pressed_no_signal(not enabled)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/memories.tscn")


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.84, 0.95)
	style.border_color = Color("76502c")
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.12, 0.20, 0.08, 0.36)
	style.shadow_size = 9
	return style


func _make_feature_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.94, 0.72, 0.72)
	style.border_color = Color("93aa66")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 18
	style.content_margin_top = 8
	style.content_margin_right = 18
	style.content_margin_bottom = 8
	return style


func _style_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(290, 50)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("492d16"))
	button.add_theme_color_override("font_hover_color", Color("384514"))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("fff7d5")
	normal.border_color = Color("76502c")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)
	normal.shadow_color = Color(0.18, 0.12, 0.05, 0.28)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("ffe38a")
	hover.border_color = Color("6b9140")
	hover.set_border_width_all(3)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
