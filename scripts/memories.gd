extends Control

const MEMORIES_RETURN_SCENE_META := "memories_return_scene"
const TITLE_SCENE := "res://scenes/main.tscn"

var content_panel: PanelContainer
var empty_panel: PanelContainer
var portrait: TextureRect
var name_label: Label
var stage_label: Label
var status_grid: GridContainer
var care_grid: GridContainer


func _ready() -> void:
	_build_screen()
	_load_record()


func _build_screen() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.20, 0.12, 0.04, 0.08)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var title_panel := PanelContainer.new()
	title_panel.anchor_left = 0.5
	title_panel.anchor_right = 0.5
	title_panel.offset_left = -260.0
	title_panel.offset_top = 20.0
	title_panel.offset_right = 260.0
	title_panel.offset_bottom = 78.0
	title_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(1.0, 0.97, 0.84, 0.95), 18, 3))
	add_child(title_panel)

	var title := Label.new()
	title.text = "育成記録"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("492d16"))
	title_panel.add_child(title)

	var back_button := Button.new()
	back_button.text = "もどる"
	back_button.anchor_left = 1.0
	back_button.anchor_right = 1.0
	back_button.offset_left = -178.0
	back_button.offset_top = 24.0
	back_button.offset_right = -28.0
	back_button.offset_bottom = 76.0
	_style_button(back_button)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

	content_panel = PanelContainer.new()
	content_panel.anchor_left = 0.5
	content_panel.anchor_top = 0.5
	content_panel.anchor_right = 0.5
	content_panel.anchor_bottom = 0.5
	content_panel.offset_left = -500.0
	content_panel.offset_top = -230.0
	content_panel.offset_right = 500.0
	content_panel.offset_bottom = 280.0
	content_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(1.0, 0.97, 0.84, 0.95), 24, 4))
	add_child(content_panel)

	var page_margin := MarginContainer.new()
	page_margin.add_theme_constant_override("margin_left", 34)
	page_margin.add_theme_constant_override("margin_top", 28)
	page_margin.add_theme_constant_override("margin_right", 34)
	page_margin.add_theme_constant_override("margin_bottom", 28)
	content_panel.add_child(page_margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 42)
	page_margin.add_child(columns)

	var profile_column := VBoxContainer.new()
	profile_column.custom_minimum_size = Vector2(360, 0)
	profile_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_column.add_theme_constant_override("separation", 10)
	columns.add_child(profile_column)

	var profile_title := _make_section_title("いまのピヨコ")
	profile_column.add_child(profile_title)

	var portrait_center := CenterContainer.new()
	portrait_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	profile_column.add_child(portrait_center)

	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(210, 210)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_center.add_child(portrait)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 27)
	name_label.add_theme_color_override("font_color", Color("492d16"))
	profile_column.add_child(name_label)

	stage_label = Label.new()
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 18)
	stage_label.add_theme_color_override("font_color", Color("58743b"))
	profile_column.add_child(stage_label)

	var divider := VSeparator.new()
	divider.add_theme_color_override("separator", Color("93aa66"))
	divider.add_theme_constant_override("separation", 3)
	columns.add_child(divider)

	var record_column := VBoxContainer.new()
	record_column.custom_minimum_size = Vector2(500, 0)
	record_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	record_column.add_theme_constant_override("separation", 10)
	columns.add_child(record_column)

	record_column.add_child(_make_section_title("お世話のきろく"))
	care_grid = GridContainer.new()
	care_grid.columns = 2
	care_grid.add_theme_constant_override("h_separation", 24)
	care_grid.add_theme_constant_override("v_separation", 8)
	record_column.add_child(care_grid)

	var line := HSeparator.new()
	line.add_theme_color_override("separator", Color("93aa66"))
	line.add_theme_constant_override("separation", 2)
	record_column.add_child(line)

	record_column.add_child(_make_section_title("いまのようす"))
	status_grid = GridContainer.new()
	status_grid.columns = 2
	status_grid.add_theme_constant_override("h_separation", 24)
	status_grid.add_theme_constant_override("v_separation", 8)
	record_column.add_child(status_grid)

	empty_panel = PanelContainer.new()
	empty_panel.anchor_left = 0.5
	empty_panel.anchor_top = 0.5
	empty_panel.anchor_right = 0.5
	empty_panel.anchor_bottom = 0.5
	empty_panel.offset_left = -360.0
	empty_panel.offset_top = -105.0
	empty_panel.offset_right = 360.0
	empty_panel.offset_bottom = 105.0
	empty_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(1.0, 0.97, 0.84, 0.96), 24, 4))
	add_child(empty_panel)

	var empty_box := VBoxContainer.new()
	empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
	empty_box.add_theme_constant_override("separation", 18)
	empty_panel.add_child(empty_box)

	var empty_title := Label.new()
	empty_title.text = "まだ育成記録はありません"
	empty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_title.add_theme_font_size_override("font_size", 28)
	empty_title.add_theme_color_override("font_color", Color("492d16"))
	empty_box.add_child(empty_title)

	var empty_guide := Label.new()
	empty_guide.text = "たまごから育成を始めると、ここに思い出が残ります。"
	empty_guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_guide.add_theme_font_size_override("font_size", 18)
	empty_guide.add_theme_color_override("font_color", Color("58743b"))
	empty_box.add_child(empty_guide)


func _load_record() -> void:
	if not PiyokoSaveManager.has_save():
		content_panel.hide()
		empty_panel.show()
		return

	var piyoko := Piyoko.new()
	if not PiyokoSaveManager.load_save(piyoko):
		content_panel.hide()
		empty_panel.show()
		return

	empty_panel.hide()
	content_panel.show()
	portrait.texture = PiyokoTextureManager.get_texture(
		piyoko.growth_stage,
		piyoko.child_type,
		piyoko.adult_type
	)
	name_label.text = piyoko.get_growth_stage_name()
	stage_label.text = _stage_description(piyoko)

	_clear_grid(care_grid)
	_add_value_row(care_grid, "総お世話回数", "%d 回" % piyoko.total_care_count)
	_add_value_row(care_grid, "ごはん", "%d 回" % piyoko.food_count)
	_add_value_row(care_grid, "  ケーキ・おにぎり・野菜", "%d・%d・%d 回" % [
		piyoko.shortcake_count,
		piyoko.onigiri_count,
		piyoko.broccoli_count
	])
	_add_value_row(care_grid, "なでる", "%d 回" % piyoko.pet_count)
	_add_value_row(care_grid, "あそぶ", "%d 回（成功 %d／失敗 %d）" % [
		piyoko.play_count,
		piyoko.play_success_count,
		piyoko.play_failure_count
	])
	_add_value_row(care_grid, "さいごのお世話", _last_care_name(piyoko.last_care))

	_clear_grid(status_grid)
	_add_value_row(status_grid, "おなか", "%d / 5" % piyoko.hunger)
	_add_value_row(status_grid, "なかよし", "%d / 5" % piyoko.friendship)
	_add_value_row(status_grid, "きげん", "%d / 5" % piyoko.mood)


func _stage_description(piyoko: Piyoko) -> String:
	var required := piyoko.get_required_growth_count()
	if required <= 0:
		return "大人になったピヨコ"
	return "次の成長まで %d / %d" % [piyoko.growth_count, required]


func _last_care_name(last_care: String) -> String:
	match last_care:
		"food":
			return "ごはん"
		"pet":
			return "なでる"
		"play":
			return "あそぶ"
		_:
			return "まだありません"


func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()


func _add_value_row(grid: GridContainer, item_name: String, value: String) -> void:
	var item := Label.new()
	item.text = item_name
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_theme_font_size_override("font_size", 17)
	item.add_theme_color_override("font_color", Color("76512f"))
	grid.add_child(item)

	var value_label := Label.new()
	value_label.text = value
	value_label.custom_minimum_size.x = 240.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color("492d16"))
	grid.add_child(value_label)


func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("58743b"))
	return label


func _make_panel_style(color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("6b9140")
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.12, 0.25, 0.10, 0.36)
	style.shadow_size = 9
	return style


func _style_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(150, 52)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("492d16"))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 0.945, 0.753, 0.96)
	normal.border_color = Color("7c4c26")
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(18)
	normal.shadow_color = Color(0.18, 0.33, 0.15, 0.4)
	normal.shadow_size = 5
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("ffd360")
	hover.border_color = Color("639133")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)


func _on_back_pressed() -> void:
	var return_scene := TITLE_SCENE
	if get_tree().has_meta(MEMORIES_RETURN_SCENE_META):
		return_scene = str(get_tree().get_meta(MEMORIES_RETURN_SCENE_META))
		get_tree().remove_meta(MEMORIES_RETURN_SCENE_META)
	get_tree().change_scene_to_file(return_scene)
