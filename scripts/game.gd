extends Control


var piyoko: Piyoko
var is_growing: bool = false
var is_hatching: bool = false
var finish_care_button: Button
var finish_care_confirm: ConfirmationDialog


func _ready() -> void:
	piyoko = Piyoko.new()

	if PiyokoSaveManager.has_save():
		var loaded := PiyokoSaveManager.load_save(piyoko)
		if not loaded:
			piyoko.growth_stage = -1
	else:
		piyoko.growth_stage = -1

	$GameMenuPanel.hide()
	$MainMargin/GameLayout/ActionMenu/FoodButton.pressed.connect(_on_food_button_pressed)
	$MainMargin/GameLayout/ActionMenu/PetButton.pressed.connect(_on_pet_button_pressed)
	$MainMargin/GameLayout/ActionMenu/PlayButton.pressed.connect(_on_play_button_pressed)
	$FoodPanel/FoodMenu/ShortcakeButton.pressed.connect(_on_shortcake_button_pressed)
	$FoodPanel/FoodMenu/OnigiriButton.pressed.connect(_on_onigiri_button_pressed)
	$FoodPanel/FoodMenu/BroccoliButton.pressed.connect(_on_broccoli_button_pressed)
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.animation_finished.connect(_on_animation_finished)
	$PlayPanel/PlayMenu/SuccessButton.pressed.connect(_on_play_success_pressed)
	$PlayPanel/PlayMenu/FailureButton.pressed.connect(_on_play_failure_pressed)
	$PlayPanel/PlayMenu/CancelButton.pressed.connect(_on_play_cancel_pressed)
	$GrowthMessageTimer.timeout.connect(_on_growth_message_timeout)
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.pressed.connect(_on_hatch_button_pressed)
	$MenuButton.pressed.connect(_on_menu_button_pressed)
	$GameMenuPanel/GameMenu/BackToTitleButton.pressed.connect(_on_back_to_title_button_pressed)
	$GameMenuPanel/GameMenu/QuitButton.pressed.connect(_on_quit_button_pressed)
	$GameMenuPanel/GameMenu/CloseMenuButton.pressed.connect(_on_close_menu_button_pressed)
	$GameMenuPanel/GameMenu/CollectionButton.pressed.connect(_on_collection_button_pressed)
	$GameMenuPanel/GameMenu/ResetButton.pressed.connect(_on_reset_button_pressed)
	$ResetConfirmDialog.confirmed.connect(_on_reset_confirmed)

	# 成長メッセージがピヨコと重ならないように少し上へ表示
	$GrowthMessageLabel.position.y -= 110.0

	_create_finish_care_ui()
	_update_status_display()
	_update_piyoko_texture()

	var animation_player := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer
	animation_player.play("idle")

	if piyoko.growth_stage == -1:
		_start_egg_sequence()
	else:
		$MainMargin/GameLayout/Header/StatusMargin/StatusContainer.show()
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.hide()
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.hide()
		_set_action_buttons_disabled(false)

	_update_finish_care_button()
	print("ゲーム画面：ピヨコを作成しました")
	piyoko.print_status()


func _create_finish_care_ui() -> void:
	finish_care_button = Button.new()
	finish_care_button.name = "FinishCareButton"
	finish_care_button.text = "育成をおえる"
	finish_care_button.custom_minimum_size = Vector2(0, 54)
	finish_care_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_care_button.visible = false
	finish_care_button.pressed.connect(_on_finish_care_button_pressed)
	$MainMargin/GameLayout.add_child(finish_care_button)

	finish_care_confirm = ConfirmationDialog.new()
	finish_care_confirm.name = "FinishCareConfirm"
	finish_care_confirm.title = "育成をおえる"
	finish_care_confirm.dialog_text = "このピヨコの育成をおえますか？\n\n図鑑の発見記録は残り、\n新しいたまごから育成を始められます。"
	finish_care_confirm.ok_button_text = "育成をおえる"
	finish_care_confirm.cancel_button_text = "まだ一緒にいる"
	finish_care_confirm.confirmed.connect(_on_finish_care_confirmed)
	add_child(finish_care_confirm)


func _update_finish_care_button() -> void:
	if finish_care_button != null:
		finish_care_button.visible = piyoko.growth_stage == 2


func _on_finish_care_button_pressed() -> void:
	finish_care_confirm.popup_centered()


func _on_finish_care_confirmed() -> void:
	var success := PiyokoSaveManager.delete_save()
	if not success:
		push_error("育成完了後のセーブデータ削除に失敗しました")
		return

	get_tree().reload_current_scene()


func _on_food_button_pressed() -> void:
	$FoodPanel.show()


func _on_pet_button_pressed() -> void:
	piyoko.pet()
	var grew := _check_growth()
	_update_status_display()
	if not grew:
		var animation_player := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer
		animation_player.play("happy")
	print("ピヨコをなでました")
	piyoko.print_status()
	_save_game()


func _on_play_button_pressed() -> void:
	$PlayPanel.show()


func _on_shortcake_button_pressed() -> void:
	piyoko.feed("shortcake")
	var grew := _check_growth()
	_update_status_display()
	if not grew:
		pass
	print("ショートケーキをあげました")
	piyoko.print_status()
	_save_game()
	$FoodPanel.hide()


func _on_onigiri_button_pressed() -> void:
	piyoko.feed("onigiri")
	var grew := _check_growth()
	_update_status_display()
	if not grew:
		pass
	print("おにぎりをあげました")
	piyoko.print_status()
	_save_game()
	$FoodPanel.hide()


func _on_broccoli_button_pressed() -> void:
	piyoko.feed("broccoli")
	var grew := _check_growth()
	_update_status_display()
	if not grew:
		pass
	print("ブロッコリーをあげました")
	piyoko.print_status()
	_save_game()
	$FoodPanel.hide()


func _on_animation_finished(animation_name: StringName) -> void:
	var animation_player := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer
	var sprite := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite

	if animation_name == "happy":
		sprite.scale = Vector2.ONE
		animation_player.play("idle")
		animation_player.seek(0.0, true)

	elif animation_name == "grow_out":
		_update_piyoko_texture()
		animation_player.play("grow_in")

	elif animation_name == "grow_in":
		sprite.scale = Vector2.ONE
		if is_hatching:
			$MainMargin/GameLayout/Header/StatusMargin/StatusContainer.show()
			$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.hide()
			$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.hide()
			$GrowthMessageLabel.text = "ピヨコが生まれた！"
			is_hatching = false
		else:
			$GrowthMessageLabel.text = "%sになった！" % piyoko.get_growth_stage_name()

		$GrowthMessageLabel.show()
		$GrowthMessageTimer.start()
		is_growing = false
		_set_action_buttons_disabled(false)
		_update_finish_care_button()
		animation_player.play("idle")
		animation_player.seek(0.0, true)

	elif animation_name == "hatch":
		piyoko.growth_stage = 0
		piyoko.growth_count = 0
		piyoko.child_type = ""
		piyoko.adult_type = ""
		PiyokoCollectionManager.discover("chibi")
		_update_piyoko_texture()
		_update_status_display()
		PiyokoSaveManager.save(piyoko)
		animation_player.play("grow_in")


func _on_play_success_pressed() -> void:
	piyoko.play(true)
	$PlayPanel.hide()
	var grew := _check_growth()
	_update_status_display()
	if not grew:
		var animation_player := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer
		animation_player.play("happy")
	print("あそぶ：成功！")
	piyoko.print_status()
	_save_game()


func _on_play_failure_pressed() -> void:
	piyoko.play(false)
	var grew := _check_growth()
	_update_status_display()
	if not grew:
		pass
	$PlayPanel.hide()
	print("あそぶ：失敗")
	piyoko.print_status()
	_save_game()


func _on_play_cancel_pressed() -> void:
	$PlayPanel.hide()
	print("あそぶのをやめました")


func _check_growth() -> bool:
	if piyoko.check_growth():
		is_growing = true
		_set_action_buttons_disabled(true)
		print("成長開始！")
		print("成長後：", piyoko.get_growth_stage_name())
		var animation_player := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer
		animation_player.play("grow_out")
		return true
	return false


func _update_status_display() -> void:
	var required_growth := piyoko.get_required_growth_count()
	if required_growth > 0:
		$MainMargin/GameLayout/Header/StatusMargin/StatusContainer/GrowthLabel.text = "%s：%d/%d" % [piyoko.get_growth_stage_name(), piyoko.growth_count, required_growth]
	else:
		$MainMargin/GameLayout/Header/StatusMargin/StatusContainer/GrowthLabel.text = piyoko.get_growth_stage_name()

	$MainMargin/GameLayout/Header/StatusMargin/StatusContainer/HungerLabel.text = "おなか：%d/5" % piyoko.hunger
	$MainMargin/GameLayout/Header/StatusMargin/StatusContainer/FriendshipLabel.text = "なかよし：%d/5" % piyoko.friendship
	$MainMargin/GameLayout/Header/StatusMargin/StatusContainer/MoodLabel.text = "きげん：%d/5" % piyoko.mood


func _update_piyoko_texture() -> void:
	var sprite := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite
	sprite.texture = PiyokoTextureManager.get_texture(piyoko.growth_stage, piyoko.child_type, piyoko.adult_type)


func _set_action_buttons_disabled(disabled: bool) -> void:
	$MainMargin/GameLayout/ActionMenu/FoodButton.disabled = disabled
	$MainMargin/GameLayout/ActionMenu/PetButton.disabled = disabled
	$MainMargin/GameLayout/ActionMenu/PlayButton.disabled = disabled


func _on_growth_message_timeout() -> void:
	$GrowthMessageLabel.hide()


func _save_game() -> void:
	var success := PiyokoSaveManager.save(piyoko)
	if not success:
		push_error("ピヨコのセーブに失敗しました")


func _start_egg_sequence() -> void:
	print("新しいたまごからスタートします")
	_set_action_buttons_disabled(true)
	$MainMargin/GameLayout/Header/StatusMargin/StatusContainer.hide()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.show()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.show()
	_update_piyoko_texture()
	_update_finish_care_button()
	var animation_player := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer
	animation_player.play("egg_idle")


func _on_hatch_button_pressed() -> void:
	if piyoko.growth_stage != -1:
		return
	is_hatching = true
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.hide()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.hide()
	var animation_player := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer
	animation_player.play("hatch")


func _on_menu_button_pressed() -> void:
	$GameMenuPanel.visible = not $GameMenuPanel.visible


func _on_close_menu_button_pressed() -> void:
	$GameMenuPanel.hide()


func _on_back_to_title_button_pressed() -> void:
	if piyoko.growth_stage >= 0:
		PiyokoSaveManager.save(piyoko)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_button_pressed() -> void:
	if piyoko.growth_stage >= 0:
		PiyokoSaveManager.save(piyoko)
	get_tree().quit()


func _on_collection_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/collection.tscn")


func _on_reset_button_pressed() -> void:
	$GameMenuPanel.hide()
	$ResetConfirmDialog.popup_centered()


func _on_reset_confirmed() -> void:
	var success := PiyokoSaveManager.delete_save()
	if not success:
		push_error("育成データのリセットに失敗しました")
		return
	get_tree().reload_current_scene()
