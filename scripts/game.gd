extends Control


var piyoko: Piyoko
var is_growing: bool = false
var is_hatching: bool = false
var finish_care_button: Button
var finish_care_confirm: ConfirmationDialog

# あそぶミニゲーム
const PLAY_TARGET_COUNT := 3
const PLAY_TIME_LIMIT := 5.0
var play_minigame_panel: Control
var play_minigame_target: TextureButton
var play_minigame_count_label: Label
var play_minigame_time_label: Label
var play_minigame_timer: Timer
var play_minigame_hits: int = 0
var play_minigame_active: bool = false


func _ready() -> void:
	piyoko = Piyoko.new()
	if PiyokoSaveManager.has_save():
		var loaded := PiyokoSaveManager.load_save(piyoko)
		if not loaded:
			piyoko.growth_stage = -1
	else:
		piyoko.growth_stage = -1

	$GameMenuPanel.hide()
	$PlayPanel.hide()
	$MainMargin/GameLayout/ActionMenu/FoodButton.pressed.connect(_on_food_button_pressed)
	$MainMargin/GameLayout/ActionMenu/PetButton.pressed.connect(_on_pet_button_pressed)
	$MainMargin/GameLayout/ActionMenu/PlayButton.pressed.connect(_on_play_button_pressed)
	$FoodPanel/FoodMenu/ShortcakeButton.pressed.connect(_on_shortcake_button_pressed)
	$FoodPanel/FoodMenu/OnigiriButton.pressed.connect(_on_onigiri_button_pressed)
	$FoodPanel/FoodMenu/BroccoliButton.pressed.connect(_on_broccoli_button_pressed)
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.animation_finished.connect(_on_animation_finished)
	$GrowthMessageTimer.timeout.connect(_on_growth_message_timeout)
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.pressed.connect(_on_hatch_button_pressed)
	$MenuButton.pressed.connect(_on_menu_button_pressed)
	$GameMenuPanel/GameMenu/BackToTitleButton.pressed.connect(_on_back_to_title_button_pressed)
	$GameMenuPanel/GameMenu/QuitButton.pressed.connect(_on_quit_button_pressed)
	$GameMenuPanel/GameMenu/CloseMenuButton.pressed.connect(_on_close_menu_button_pressed)
	$GameMenuPanel/GameMenu/CollectionButton.pressed.connect(_on_collection_button_pressed)
	$GameMenuPanel/GameMenu/ResetButton.pressed.connect(_on_reset_button_pressed)
	$ResetConfirmDialog.confirmed.connect(_on_reset_confirmed)
	$GrowthMessageLabel.position.y -= 110.0
	_create_finish_care_ui()
	_create_play_minigame_ui()
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


func _create_play_minigame_ui() -> void:
	play_minigame_panel = Control.new()
	play_minigame_panel.name = "PlayMinigamePanel"
	play_minigame_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_minigame_panel.visible = false
	play_minigame_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(play_minigame_panel)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.91764706, 0.95686275, 0.8745098, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	play_minigame_panel.add_child(background)
	var title := Label.new()
	title.text = "ピヨコを3回タッチ！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.36, 0.20, 0.12, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24.0
	title.offset_bottom = 66.0
	play_minigame_panel.add_child(title)
	play_minigame_count_label = Label.new()
	play_minigame_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_minigame_count_label.add_theme_font_size_override("font_size", 24)
	play_minigame_count_label.add_theme_color_override("font_color", Color(0.72, 0.24, 0.16, 1.0))
	play_minigame_count_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	play_minigame_count_label.offset_top = 72.0
	play_minigame_count_label.offset_bottom = 106.0
	play_minigame_panel.add_child(play_minigame_count_label)
	play_minigame_time_label = Label.new()
	play_minigame_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_minigame_time_label.add_theme_font_size_override("font_size", 22)
	play_minigame_time_label.add_theme_color_override("font_color", Color(0.18, 0.32, 0.22, 1.0))
	play_minigame_time_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	play_minigame_time_label.offset_top = 108.0
	play_minigame_time_label.offset_bottom = 142.0
	play_minigame_panel.add_child(play_minigame_time_label)
	play_minigame_target = TextureButton.new()
	play_minigame_target.name = "PiyokoTarget"
	play_minigame_target.ignore_texture_size = true
	play_minigame_target.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	play_minigame_target.custom_minimum_size = Vector2(128, 128)
	play_minigame_target.size = Vector2(128, 128)
	play_minigame_target.pressed.connect(_on_play_target_pressed)
	play_minigame_panel.add_child(play_minigame_target)
	var cancel_button := Button.new()
	cancel_button.text = "やめる"
	cancel_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cancel_button.offset_left = 24.0
	cancel_button.offset_right = -24.0
	cancel_button.offset_top = -70.0
	cancel_button.offset_bottom = -18.0
	cancel_button.pressed.connect(_on_play_minigame_cancel_pressed)
	play_minigame_panel.add_child(cancel_button)
	play_minigame_timer = Timer.new()
	play_minigame_timer.name = "PlayMinigameTimer"
	play_minigame_timer.wait_time = PLAY_TIME_LIMIT
	play_minigame_timer.one_shot = true
	play_minigame_timer.timeout.connect(_on_play_minigame_timeout)
	add_child(play_minigame_timer)


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
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("happy")
	print("ピヨコをなでました")
	piyoko.print_status()
	_save_game()

func _on_play_button_pressed() -> void:
	_start_play_minigame()

func _start_play_minigame() -> void:
	if play_minigame_active:
		return
	play_minigame_active = true
	play_minigame_hits = 0
	play_minigame_panel.show()
	play_minigame_target.texture_normal = PiyokoTextureManager.get_texture(piyoko.growth_stage, piyoko.child_type, piyoko.adult_type)
	_update_play_minigame_display()
	_move_play_target()
	play_minigame_timer.start()

func _process(_delta: float) -> void:
	if play_minigame_active and play_minigame_timer != null:
		play_minigame_time_label.text = "のこり %.1f 秒" % play_minigame_timer.time_left

func _on_play_target_pressed() -> void:
	if not play_minigame_active:
		return
	play_minigame_hits += 1
	_update_play_minigame_display()
	if play_minigame_hits >= PLAY_TARGET_COUNT:
		_finish_play_minigame(true)
	else:
		_move_play_target()

func _move_play_target() -> void:
	var viewport_size := get_viewport_rect().size
	var target_size := Vector2(128, 128)
	var min_pos := Vector2(40, 155)
	var max_pos := Vector2(max(min_pos.x, viewport_size.x - target_size.x - 40.0), max(min_pos.y, viewport_size.y - target_size.y - 95.0))
	play_minigame_target.position = Vector2(randf_range(min_pos.x, max_pos.x), randf_range(min_pos.y, max_pos.y))

func _update_play_minigame_display() -> void:
	play_minigame_count_label.text = "%d / %d" % [play_minigame_hits, PLAY_TARGET_COUNT]

func _on_play_minigame_timeout() -> void:
	if play_minigame_active:
		_finish_play_minigame(false)

func _on_play_minigame_cancel_pressed() -> void:
	if not play_minigame_active:
		return
	play_minigame_active = false
	play_minigame_timer.stop()
	play_minigame_panel.hide()
	print("あそぶのをやめました")

func _finish_play_minigame(success: bool) -> void:
	if not play_minigame_active:
		return
	play_minigame_active = false
	play_minigame_timer.stop()
	play_minigame_panel.hide()
	piyoko.play(success)
	var grew := _check_growth()
	_update_status_display()
	if success and not grew:
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("happy")
	if success:
		print("あそぶ：成功！")
	else:
		print("あそぶ：失敗")
	piyoko.print_status()
	_save_game()

func _on_shortcake_button_pressed() -> void:
	piyoko.feed("shortcake")
	_check_growth()
	_update_status_display()
	print("ショートケーキをあげました")
	piyoko.print_status()
	_save_game()
	$FoodPanel.hide()

func _on_onigiri_button_pressed() -> void:
	piyoko.feed("onigiri")
	_check_growth()
	_update_status_display()
	print("おにぎりをあげました")
	piyoko.print_status()
	_save_game()
	$FoodPanel.hide()

func _on_broccoli_button_pressed() -> void:
	piyoko.feed("broccoli")
	_check_growth()
	_update_status_display()
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

func _check_growth() -> bool:
	if piyoko.check_growth():
		is_growing = true
		_set_action_buttons_disabled(true)
		print("成長開始！")
		print("成長後：", piyoko.get_growth_stage_name())
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("grow_out")
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
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite.texture = PiyokoTextureManager.get_texture(piyoko.growth_stage, piyoko.child_type, piyoko.adult_type)

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
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("egg_idle")

func _on_hatch_button_pressed() -> void:
	if piyoko.growth_stage != -1:
		return
	is_hatching = true
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.hide()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.hide()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("hatch")

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
