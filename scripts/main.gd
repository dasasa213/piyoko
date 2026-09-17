extends Control

const COLLECTION_RETURN_SCENE_META := "collection_return_scene"
const MEMORIES_RETURN_SCENE_META := "memories_return_scene"
const TITLE_SCENE := "res://scenes/main.tscn"
const SETTINGS_PATH := "user://piyoko_settings.cfg"

var collection_button: Button
var memories_button: Button
var dialog_dim: ColorRect
var volume_slider: HSlider
var volume_value_label: Label
var fullscreen_toggle: CheckButton


func _ready() -> void:
	_setup_dialog_dim()
	_setup_collection_button()
	_setup_memories_button()
	_setup_options_controls()
	_load_settings()
	_update_start_buttons()
	$OptionsPanel.hide()

	$TitleCenter/TitleMenu/StartButton.pressed.connect(_on_start_button_pressed)
	$TitleCenter/TitleMenu/ContinueButton.pressed.connect(_on_continue_button_pressed)
	$TitleCenter/TitleMenu/NewGameButton.pressed.connect(_on_new_game_button_pressed)
	$TitleCenter/TitleMenu/OptionsButton.pressed.connect(_on_options_button_pressed)
	$TitleCenter/TitleMenu/QuitButton.pressed.connect(_on_quit_button_pressed)
	$OptionsPanel/OptionsBackground/OptionsMenu/FullResetButton.pressed.connect(_on_full_reset_button_pressed)
	$OptionsPanel/OptionsBackground/OptionsMenu/BackButton.pressed.connect(_on_options_back_button_pressed)
	$NewGameConfirm.confirmed.connect(_on_new_game_confirmed)
	$FullResetConfirm.confirmed.connect(_on_full_reset_confirmed)
	_style_title_dialogs()
	_style_options_panel()
	$NewGameConfirm.visibility_changed.connect(_refresh_dialog_dim)
	$FullResetConfirm.visibility_changed.connect(_refresh_dialog_dim)
	$FullResetComplete.visibility_changed.connect(_refresh_dialog_dim)


func _setup_dialog_dim() -> void:
	dialog_dim = ColorRect.new()
	dialog_dim.name = "DialogDim"
	dialog_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog_dim.color = Color(0.08, 0.12, 0.06, 0.38)
	dialog_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_dim.hide()
	add_child(dialog_dim)


func _refresh_dialog_dim() -> void:
	dialog_dim.visible = (
		$NewGameConfirm.visible
		or $FullResetConfirm.visible
		or $FullResetComplete.visible
	)


func _style_title_dialogs() -> void:
	var style_source: Button = $TitleCenter/TitleMenu/OptionsButton
	_apply_dialog_style($NewGameConfirm, style_source, Vector2i(640, 280))
	_apply_dialog_style($FullResetConfirm, style_source, Vector2i(680, 340))
	_apply_dialog_style($FullResetComplete, style_source, Vector2i(520, 240))


func _style_options_panel() -> void:
	$OptionsPanel/OptionsBackground.custom_minimum_size = Vector2(620, 560)
	var options_style := $OptionsPanel/OptionsBackground.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	options_style.content_margin_left = 34.0
	options_style.content_margin_top = 24.0
	options_style.content_margin_right = 34.0
	options_style.content_margin_bottom = 24.0
	$OptionsPanel/OptionsBackground.add_theme_stylebox_override("panel", options_style)

	$OptionsPanel/OptionsBackground/OptionsMenu.add_theme_constant_override("separation", 11)
	$OptionsPanel/OptionsBackground/OptionsMenu/OptionsTitle.add_theme_font_size_override("font_size", 30)
	$OptionsPanel/OptionsBackground/OptionsMenu/DataTitle.add_theme_font_size_override("font_size", 20)

	var style_source: Button = $TitleCenter/TitleMenu/OptionsButton
	var option_buttons: Array[Button] = [
		$OptionsPanel/OptionsBackground/OptionsMenu/FullResetButton,
		$OptionsPanel/OptionsBackground/OptionsMenu/BackButton,
	]

	for button in option_buttons:
		button.custom_minimum_size.y = 52.0
		button.add_theme_font_size_override("font_size", 17)
		button.clip_text = false
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override("font_color", Color("492d16"))
		button.add_theme_color_override("font_hover_color", Color("384514"))
		button.add_theme_color_override("font_pressed_color", Color("492d16"))
		button.add_theme_color_override("font_focus_color", Color("492d16"))
		button.add_theme_color_override("font_disabled_color", Color("75654e"))
		for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			var source_style := style_source.get_theme_stylebox(style_name)
			if source_style != null:
				button.add_theme_stylebox_override(style_name, source_style.duplicate())


func _setup_options_controls() -> void:
	var options_menu := $OptionsPanel/OptionsBackground/OptionsMenu
	var data_title := $OptionsPanel/OptionsBackground/OptionsMenu/DataTitle

	var sound_title := _make_option_heading("サウンド")
	options_menu.add_child(sound_title)
	options_menu.move_child(sound_title, data_title.get_index())

	var volume_row := HBoxContainer.new()
	volume_row.custom_minimum_size.y = 52.0
	volume_row.add_theme_constant_override("separation", 18)
	options_menu.add_child(volume_row)
	options_menu.move_child(volume_row, data_title.get_index())

	var volume_name := Label.new()
	volume_name.text = "全体音量"
	volume_name.custom_minimum_size.x = 130.0
	volume_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_name.add_theme_font_size_override("font_size", 18)
	volume_name.add_theme_color_override("font_color", Color("492d16"))
	volume_row.add_child(volume_name)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 5.0
	volume_slider.value = 80.0
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.custom_minimum_size = Vector2(300, 42)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(volume_slider)

	volume_value_label = Label.new()
	volume_value_label.text = "80%"
	volume_value_label.custom_minimum_size.x = 62.0
	volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_value_label.add_theme_font_size_override("font_size", 18)
	volume_value_label.add_theme_color_override("font_color", Color("492d16"))
	volume_row.add_child(volume_value_label)

	var display_title := _make_option_heading("画面")
	options_menu.add_child(display_title)
	options_menu.move_child(display_title, data_title.get_index())

	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "フルスクリーンで表示"
	fullscreen_toggle.custom_minimum_size.y = 48.0
	fullscreen_toggle.add_theme_font_size_override("font_size", 18)
	fullscreen_toggle.add_theme_color_override("font_color", Color("492d16"))
	fullscreen_toggle.add_theme_color_override("font_hover_color", Color("492d16"))
	fullscreen_toggle.add_theme_color_override("font_pressed_color", Color("492d16"))
	fullscreen_toggle.add_theme_color_override("font_hover_pressed_color", Color("492d16"))
	fullscreen_toggle.add_theme_color_override("font_focus_color", Color("492d16"))
	fullscreen_toggle.add_theme_color_override("font_disabled_color", Color("75654e"))
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	options_menu.add_child(fullscreen_toggle)
	options_menu.move_child(fullscreen_toggle, data_title.get_index())


func _make_option_heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("6b4f3a"))
	return label


func _load_settings() -> void:
	var config := ConfigFile.new()
	var load_result := config.load(SETTINGS_PATH)
	var volume := 80.0
	var fullscreen := false

	if load_result == OK:
		volume = float(config.get_value("audio", "master_volume", 80.0))
		fullscreen = bool(config.get_value("display", "fullscreen", false))

	volume_slider.set_value_no_signal(clamp(volume, 0.0, 100.0))
	fullscreen_toggle.set_pressed_no_signal(fullscreen)
	_apply_master_volume(volume_slider.value)
	_apply_fullscreen(fullscreen)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", volume_slider.value)
	config.set_value("display", "fullscreen", fullscreen_toggle.button_pressed)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_error("設定の保存に失敗しました")


func _on_volume_changed(value: float) -> void:
	_apply_master_volume(value)
	_save_settings()


func _apply_master_volume(value: float) -> void:
	volume_value_label.text = "%d%%" % int(round(value))
	AudioServer.set_bus_mute(0, value <= 0.0)
	if value > 0.0:
		AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))


func _on_fullscreen_toggled(enabled: bool) -> void:
	_apply_fullscreen(enabled)
	_save_settings()


func _apply_fullscreen(enabled: bool) -> void:
	get_window().mode = (
		Window.MODE_FULLSCREEN
		if enabled
		else Window.MODE_WINDOWED
	)


func _apply_dialog_style(dialog: AcceptDialog, style_source: Button, minimum_size: Vector2i) -> void:
	dialog.min_size = minimum_size
	dialog.borderless = true
	dialog.unresizable = true
	# Godot標準のタイトルバーは本文と別レイヤーになるため、
	# 見出しを本文へ移して一枚のカードとして表示する。
	var heading := dialog.title
	if not heading.is_empty():
		dialog.dialog_text = "%s\n\n%s" % [heading, dialog.dialog_text]
		dialog.title = ""

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("fff7d5")
	panel_style.border_color = Color("6b9140")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(22)
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_top = 22.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_bottom = 20.0
	panel_style.shadow_color = Color(0.12, 0.25, 0.10, 0.4)
	panel_style.shadow_size = 10
	# 枠線付きカードは本文側の1枚だけ。背面の標準ウィンドウ枠は空にする。
	dialog.add_theme_stylebox_override("panel", panel_style)
	dialog.add_theme_stylebox_override("embedded_border", StyleBoxEmpty.new())

	var message_label := dialog.get_label()
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color("492d16"))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var dialog_buttons: Array[Button] = [dialog.get_ok_button()]
	if dialog is ConfirmationDialog:
		dialog_buttons.append((dialog as ConfirmationDialog).get_cancel_button())

	for button in dialog_buttons:
		button.custom_minimum_size = Vector2(260, 60)
		button.add_theme_font_size_override("font_size", 16)
		button.clip_text = false
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override("font_color", Color("492d16"))
		button.add_theme_color_override("font_hover_color", Color("384514"))
		button.add_theme_color_override("font_pressed_color", Color("492d16"))
		button.add_theme_color_override("font_focus_color", Color("492d16"))
		button.add_theme_color_override("font_disabled_color", Color("75654e"))
		for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			var source_style := style_source.get_theme_stylebox(style_name)
			if source_style != null:
				button.add_theme_stylebox_override(style_name, source_style.duplicate())


## タイトルからいつでも図鑑を確認できるよう、メニュー内に図鑑ボタンを追加する。
## OptionsButtonの直前へ配置し、タイトル用ボタンの見た目を引き継ぐ。
func _setup_collection_button() -> void:
	collection_button = Button.new()
	collection_button.name = "CollectionButton"
	collection_button.text = "ピヨコ図鑑"
	collection_button.custom_minimum_size = Vector2(292, 48)
	collection_button.add_theme_font_size_override("font_size", 22)
	collection_button.add_theme_color_override("font_color", Color("492d16"))

	var style_source: Button = $TitleCenter/TitleMenu/OptionsButton
	for style_name in [&"normal", &"hover", &"pressed"]:
		collection_button.add_theme_stylebox_override(
			style_name,
			style_source.get_theme_stylebox(style_name).duplicate()
		)

	collection_button.pressed.connect(_on_collection_button_pressed)

	var title_menu := $TitleCenter/TitleMenu
	title_menu.add_child(collection_button)
	title_menu.move_child(collection_button, $TitleCenter/TitleMenu/OptionsButton.get_index())


func _setup_memories_button() -> void:
	memories_button = Button.new()
	memories_button.name = "MemoriesButton"
	memories_button.text = "育成記録"
	memories_button.custom_minimum_size = Vector2(292, 48)
	memories_button.add_theme_font_size_override("font_size", 22)
	memories_button.add_theme_color_override("font_color", Color("492d16"))

	var style_source: Button = $TitleCenter/TitleMenu/OptionsButton
	for style_name in [&"normal", &"hover", &"pressed"]:
		memories_button.add_theme_stylebox_override(
			style_name,
			style_source.get_theme_stylebox(style_name).duplicate()
		)

	memories_button.pressed.connect(_on_memories_button_pressed)

	var title_menu := $TitleCenter/TitleMenu
	title_menu.add_child(memories_button)
	title_menu.move_child(memories_button, $TitleCenter/TitleMenu/OptionsButton.get_index())
	title_menu.position.y = 292.0
	title_menu.add_theme_constant_override("separation", 8)


func _update_start_buttons() -> void:
	var has_save := PiyokoSaveManager.has_save()
	$TitleCenter/TitleMenu/StartButton.visible = not has_save
	$TitleCenter/TitleMenu/ContinueButton.visible = has_save
	$TitleCenter/TitleMenu/NewGameButton.visible = has_save


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_new_game_button_pressed() -> void:
	$NewGameConfirm.popup_centered()


func _on_new_game_confirmed() -> void:
	var success := PiyokoSaveManager.delete_save()
	if not success:
		push_error("セーブデータを削除できませんでした")
		return
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_collection_button_pressed() -> void:
	get_tree().set_meta(COLLECTION_RETURN_SCENE_META, TITLE_SCENE)
	get_tree().change_scene_to_file("res://scenes/collection.tscn")


func _on_memories_button_pressed() -> void:
	get_tree().set_meta(MEMORIES_RETURN_SCENE_META, TITLE_SCENE)
	get_tree().change_scene_to_file("res://scenes/memories.tscn")


func _on_options_button_pressed() -> void:
	$TitleCenter.hide()
	$OptionsPanel.show()


func _on_options_back_button_pressed() -> void:
	$OptionsPanel.hide()
	$TitleCenter.show()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_full_reset_button_pressed() -> void:
	$FullResetConfirm.popup_centered()


func _on_full_reset_confirmed() -> void:
	var save_deleted := PiyokoSaveManager.delete_save()
	var collection_deleted := PiyokoCollectionManager.delete_collection()
	var memories_deleted := PiyokoMemoryManager.delete_all()

	if not save_deleted or not collection_deleted or not memories_deleted:
		push_error("完全初期化に失敗しました")
		return

	$OptionsPanel.hide()
	$TitleCenter.show()
	_update_start_buttons()
	$FullResetComplete.popup_centered()
