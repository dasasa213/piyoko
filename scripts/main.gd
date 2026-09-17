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
	$OptionsPanel/OptionsMenu/FullResetButton.pressed.connect(_on_full_reset_button_pressed)
	$OptionsPanel/OptionsMenu/BackButton.pressed.connect(_on_options_back_button_pressed)
	$NewGameConfirm.confirmed.connect(_on_new_game_confirmed)
	$FullResetConfirm.confirmed.connect(_on_full_reset_confirmed)


## タイトルからいつでも図鑑を確認できるよう、メニュー内に図鑑ボタンを追加する。
## OptionsButtonの直前へ配置し、既存の開始系ボタンの並びは維持する。
func _setup_collection_button() -> void:
	collection_button = Button.new()
	collection_button.name = "CollectionButton"
	collection_button.text = "ピヨコ図鑑"
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
	# 図鑑側が戻り先を判定できるよう、タイトルから開いたことを一時的に記録する。
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
