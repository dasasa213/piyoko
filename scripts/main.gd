extends Control


func _ready() -> void:
	#テスト用
	#PiyokoSaveManager.delete_save()
	
	_update_start_buttons()

	$TitleCenter/TitleMenu/StartButton.pressed.connect(
		_on_start_button_pressed
	)

	$TitleCenter/TitleMenu/ContinueButton.pressed.connect(
		_on_continue_button_pressed
	)

	$TitleCenter/TitleMenu/NewGameButton.pressed.connect(
		_on_new_game_button_pressed
	)

	$NewGameConfirm.confirmed.connect(
		_on_new_game_confirmed
	)


func _update_start_buttons() -> void:
	var has_save := PiyokoSaveManager.has_save()

	$TitleCenter/TitleMenu/StartButton.visible = not has_save
	$TitleCenter/TitleMenu/ContinueButton.visible = has_save
	$TitleCenter/TitleMenu/NewGameButton.visible = has_save


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/game.tscn"
	)


func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/game.tscn"
	)


func _on_new_game_button_pressed() -> void:
	$NewGameConfirm.popup_centered()


func _on_new_game_confirmed() -> void:
	var success := PiyokoSaveManager.delete_save()

	if not success:
		push_error("セーブデータを削除できませんでした")
		return

	get_tree().change_scene_to_file(
		"res://scenes/game.tscn"
	)
