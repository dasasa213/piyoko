extends Control

const COLLECTION_RETURN_SCENE_META := "collection_return_scene"
const TITLE_SCENE := "res://scenes/main.tscn"

var collection_button: Button


func _ready() -> void:
	_setup_collection_button()
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


func _style_title_dialogs() -> void:
	var style_source: Button = $TitleCenter/TitleMenu/OptionsButton
	_apply_dialog_style($NewGameConfirm, style_source, Vector2i(520, 250))
	_apply_dialog_style($FullResetConfirm, style_source, Vector2i(560, 310))
	_apply_dialog_style($FullResetComplete, style_source, Vector2i(460, 210))


func _style_options_panel() -> void:
	$OptionsPanel/OptionsBackground.custom_minimum_size = Vector2(540, 390)
	var style_source: Button = $TitleCenter/TitleMenu/OptionsButton
	var option_buttons: Array[Button] = [
		$OptionsPanel/OptionsBackground/OptionsMenu/FullResetButton,
		$OptionsPanel/OptionsBackground/OptionsMenu/BackButton,
	]

	for button in option_buttons:
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color("492d16"))
		button.add_theme_color_override("font_hover_color", Color("384514"))
		button.add_theme_color_override("font_pressed_color", Color("492d16"))
		button.add_theme_color_override("font_focus_color", Color("492d16"))
		button.add_theme_color_override("font_disabled_color", Color("75654e"))
		for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			var source_style := style_source.get_theme_stylebox(style_name)
			if source_style != null:
				button.add_theme_stylebox_override(style_name, source_style.duplicate())


func _apply_dialog_style(dialog: AcceptDialog, style_source: Button, minimum_size: Vector2i) -> void:
	dialog.min_size = minimum_size
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
		button.custom_minimum_size = Vector2(190, 52)
		button.add_theme_font_size_override("font_size", 18)
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

	if not save_deleted or not collection_deleted:
		push_error("完全初期化に失敗しました")
		return

	$OptionsPanel.hide()
	$TitleCenter.show()
	_update_start_buttons()
	$FullResetComplete.popup_centered()
