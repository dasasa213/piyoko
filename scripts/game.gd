extends Control

## ゲーム画面全体の制御を担当する。
## 個別のお世話演出は scripts/game/ 配下のコンポーネントへ委譲し、
## このファイルでは育成状態・画面更新・画面遷移を中心に扱う。

const FoodEffectScript = preload("res://scripts/game/food_effect.gd")
const PetEffectScript = preload("res://scripts/game/pet_effect.gd")
const PlayMinigameScript = preload("res://scripts/game/play_minigame.gd")
const ReactionEffectScript = preload("res://scripts/game/reaction_effect.gd")
const PiyokoMotionEffectScript = preload("res://scripts/game/piyoko_motion_effect.gd")
const GAME_BACKGROUND := preload("res://assets/backgrounds/02_main_room.png")
const BIRTH_BACKGROUND := preload("res://assets/backgrounds/05_birth_nursery.png")
const MEMORIES_RETURN_SCENE_META := "memories_return_scene"
const PIYOKO_RUG_OFFSET_Y := 120.0

var piyoko: Piyoko
var is_growing := false
var is_hatching := false

var finish_care_button: Button
var finish_care_confirm: ConfirmationDialog
var finish_result_overlay: Control
var finish_result_portrait: TextureRect
var finish_result_name_label: Label
var finish_result_number_label: Label
var dialog_dim: ColorRect
var room_background: TextureRect
var birth_message_panel: PanelContainer
var memories_button: Button
var food_close_button: Button

var food_effect: Node
var pet_effect: Node
var play_minigame: Node
var reaction_effect: Node
var piyoko_motion_effect: Node
var sad_reaction_tween: Tween
var status_bars: Dictionary = {}
var status_titles: Dictionary = {}


# ------------------------------------------------------------
# 初期化
# ------------------------------------------------------------

func _ready() -> void:
	AudioManager.play_care_bgm()
	_setup_background()
	_setup_birth_ui()
	_setup_memories_button()
	_setup_dialog_dim()
	_load_piyoko()
	_connect_scene_signals()
	_setup_components()
	_setup_initial_view()
	_apply_nature_ui_styles()

	print("ゲーム画面：ピヨコを作成しました")
	piyoko.print_status()


# 既存の単色背景を非表示にし、育成画面用の画像を最背面に配置する。
func _setup_background() -> void:
	$Background.hide()

	room_background = TextureRect.new()
	room_background.name = "RoomBackground"
	room_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_background.texture = GAME_BACKGROUND
	room_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(room_background)
	move_child(room_background, 0)


# はじめから選んだ時だけ表示する、誕生画面専用の案内カード。
func _setup_birth_ui() -> void:
	birth_message_panel = PanelContainer.new()
	birth_message_panel.name = "BirthMessagePanel"
	birth_message_panel.anchor_left = 0.5
	birth_message_panel.anchor_top = 0.0
	birth_message_panel.anchor_right = 0.5
	birth_message_panel.anchor_bottom = 0.0
	birth_message_panel.offset_left = -350.0
	birth_message_panel.offset_top = 28.0
	birth_message_panel.offset_right = 350.0
	birth_message_panel.offset_bottom = 126.0
	birth_message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.97, 0.82, 0.94)
	panel_style.border_color = Color("6b9140")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(22)
	panel_style.content_margin_left = 26.0
	panel_style.content_margin_top = 14.0
	panel_style.content_margin_right = 26.0
	panel_style.content_margin_bottom = 14.0
	panel_style.shadow_color = Color(0.12, 0.25, 0.10, 0.28)
	panel_style.shadow_size = 8
	birth_message_panel.add_theme_stylebox_override("panel", panel_style)

	var message_box := VBoxContainer.new()
	message_box.alignment = BoxContainer.ALIGNMENT_CENTER
	message_box.add_theme_constant_override("separation", 4)

	var main_message := Label.new()
	main_message.text = "たまごから、新しい毎日がはじまります。"
	main_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_message.add_theme_font_size_override("font_size", 24)
	main_message.add_theme_color_override("font_color", Color("492d16"))
	message_box.add_child(main_message)

	var sub_message := Label.new()
	sub_message.text = "たまごをやさしくタッチしてね"
	sub_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_message.add_theme_font_size_override("font_size", 17)
	sub_message.add_theme_color_override("font_color", Color("58743b"))
	message_box.add_child(sub_message)

	birth_message_panel.add_child(message_box)
	birth_message_panel.hide()
	add_child(birth_message_panel)

	var hatch_guide: Label = $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel
	hatch_guide.text = "たまごをタッチ"
	hatch_guide.add_theme_font_size_override("font_size", 21)
	hatch_guide.add_theme_color_override("font_color", Color("492d16"))
	hatch_guide.add_theme_color_override("font_outline_color", Color("fff7d5"))
	hatch_guide.add_theme_constant_override("outline_size", 7)


func _setup_dialog_dim() -> void:
	dialog_dim = ColorRect.new()
	dialog_dim.name = "DialogDim"
	dialog_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog_dim.color = Color(0.08, 0.12, 0.06, 0.38)
	dialog_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_dim.hide()
	add_child(dialog_dim)


func _refresh_dialog_dim() -> void:
	var finish_visible := is_instance_valid(finish_care_confirm) and finish_care_confirm.visible
	dialog_dim.visible = $ResetConfirmDialog.visible or finish_visible


func _load_piyoko() -> void:
	piyoko = Piyoko.new()

	if not PiyokoSaveManager.has_save():
		piyoko.growth_stage = -1
		return

	var loaded := PiyokoSaveManager.load_save(piyoko)
	if not loaded:
		piyoko.growth_stage = -1


func _connect_scene_signals() -> void:
	$MainMargin/GameLayout/ActionMenu/FoodButton.pressed.connect(_on_food_button_pressed)
	$MainMargin/GameLayout/ActionMenu/PetButton.pressed.connect(_on_pet_button_pressed)
	$MainMargin/GameLayout/ActionMenu/PlayButton.pressed.connect(_on_play_button_pressed)

	$FoodPanel/FoodMenu/ShortcakeButton.pressed.connect(_on_shortcake_button_pressed)
	$FoodPanel/FoodMenu/OnigiriButton.pressed.connect(_on_onigiri_button_pressed)
	$FoodPanel/FoodMenu/BroccoliButton.pressed.connect(_on_broccoli_button_pressed)

	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.pressed.connect(_on_hatch_button_pressed)
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.animation_finished.connect(_on_animation_finished)
	$GrowthMessageTimer.timeout.connect(_on_growth_message_timeout)

	$MenuButton.pressed.connect(_on_menu_button_pressed)
	$GameMenuPanel/GameMenu/BackToTitleButton.pressed.connect(_on_back_to_title_button_pressed)
	$GameMenuPanel/GameMenu/QuitButton.pressed.connect(_on_quit_button_pressed)
	$GameMenuPanel/GameMenu/CloseMenuButton.pressed.connect(_on_close_menu_button_pressed)
	$GameMenuPanel/GameMenu/CollectionButton.pressed.connect(_on_collection_button_pressed)
	$GameMenuPanel/GameMenu/ResetButton.pressed.connect(_on_reset_button_pressed)
	$ResetConfirmDialog.confirmed.connect(_on_reset_confirmed)
	$ResetConfirmDialog.visibility_changed.connect(_refresh_dialog_dim)
	_apply_dialog_style($ResetConfirmDialog, Vector2i(680, 340))


func _setup_components() -> void:
	_create_finish_care_ui()
	_setup_status_bars()
	_setup_food_menu_ui()

	food_effect = FoodEffectScript.new()
	add_child(food_effect)
	food_effect.setup(self)
	food_effect.finished.connect(_on_food_effect_finished)

	pet_effect = PetEffectScript.new()
	add_child(pet_effect)
	pet_effect.setup(self)
	pet_effect.finished.connect(_on_pet_effect_finished)

	play_minigame = PlayMinigameScript.new()
	add_child(play_minigame)
	play_minigame.setup(self)
	play_minigame.completed.connect(_on_play_minigame_finished)

	reaction_effect = ReactionEffectScript.new()
	add_child(reaction_effect)
	reaction_effect.setup(self)

	piyoko_motion_effect = PiyokoMotionEffectScript.new()
	add_child(piyoko_motion_effect)
	piyoko_motion_effect.setup($MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite)
	piyoko_motion_effect.finished.connect(_on_piyoko_motion_finished)


# レイアウト再計算や別画面からの復帰後も、リアクションをピヨコへ追従させる。
func _process(_delta: float) -> void:
	if is_instance_valid(reaction_effect):
		reaction_effect.update_anchor(_get_piyoko_center())


func _setup_food_menu_ui() -> void:
	# 動的リアクションより各メニューを前面へ固定する。
	$FoodPanel.z_index = 40
	$GameMenuPanel.z_index = 40
	$MenuButton.z_index = 41

	$FoodPanel.custom_minimum_size.y = 320.0
	$FoodPanel.offset_top = -160.0
	$FoodPanel.offset_bottom = 160.0

	food_close_button = Button.new()
	food_close_button.name = "CloseFoodButton"
	food_close_button.text = "とじる"
	food_close_button.custom_minimum_size.y = 46.0
	food_close_button.pressed.connect(_on_food_close_button_pressed)
	$FoodPanel/FoodMenu.add_child(food_close_button)


func _setup_status_bars() -> void:
	var status_container: HBoxContainer = $MainMargin/GameLayout/Header/StatusMargin/StatusContainer
	var definitions := [
		{"key": "growth", "label": "せいちょう", "color": Color("7faf4c")},
		{"key": "hunger", "label": "おなか", "color": Color("efa85b")},
		{"key": "friendship", "label": "なかよし", "color": Color("ef91ae")},
		{"key": "mood", "label": "きげん", "color": Color("79bce3")},
	]

	for old_label_name in ["GrowthLabel", "HungerLabel", "FriendshipLabel", "MoodLabel"]:
		status_container.get_node(old_label_name).hide()

	for definition in definitions:
		var item := VBoxContainer.new()
		item.name = "%sStatus" % definition.key.capitalize()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.add_theme_constant_override("separation", 5)
		status_container.add_child(item)

		var title := Label.new()
		title.text = definition.label
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", Color("492d16"))
		title.add_theme_color_override("font_outline_color", Color("fff7d5"))
		title.add_theme_constant_override("outline_size", 3)
		item.add_child(title)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(125, 18)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.show_percentage = false

		var background_style := StyleBoxFlat.new()
		background_style.bg_color = Color(0.88, 0.84, 0.72, 0.82)
		background_style.border_color = Color("76502c")
		background_style.set_border_width_all(2)
		background_style.set_corner_radius_all(8)
		bar.add_theme_stylebox_override("background", background_style)

		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = definition.color
		fill_style.set_corner_radius_all(7)
		fill_style.content_margin_left = 2.0
		fill_style.content_margin_right = 2.0
		bar.add_theme_stylebox_override("fill", fill_style)

		item.add_child(bar)
		status_titles[definition.key] = title
		status_bars[definition.key] = bar

	# 右上のメニューボタンと「きげん」バーが重ならないための予約領域。
	var menu_button_space := Control.new()
	menu_button_space.name = "MenuButtonSpace"
	menu_button_space.custom_minimum_size = Vector2(76, 0)
	menu_button_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_container.add_child(menu_button_space)


func _apply_nature_ui_styles() -> void:
	var style_source: Button = $MainMargin/GameLayout/ActionMenu/FoodButton
	var submenu_buttons: Array[Button] = [
		$FoodPanel/FoodMenu/ShortcakeButton,
		$FoodPanel/FoodMenu/OnigiriButton,
		$FoodPanel/FoodMenu/BroccoliButton,
		food_close_button,
		$PlayPanel/PlayMenu/SuccessButton,
		$PlayPanel/PlayMenu/FailureButton,
		$PlayPanel/PlayMenu/CancelButton,
		$GameMenuPanel/GameMenu/CollectionButton,
		memories_button,
		$GameMenuPanel/GameMenu/ResetButton,
		$GameMenuPanel/GameMenu/BackToTitleButton,
		$GameMenuPanel/GameMenu/QuitButton,
		$GameMenuPanel/GameMenu/CloseMenuButton,
	]

	for button in submenu_buttons:
		button.custom_minimum_size.y = 46.0
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color("492d16"))
		button.add_theme_color_override("font_hover_color", Color("384514"))
		button.add_theme_color_override("font_pressed_color", Color("492d16"))
		button.add_theme_color_override("font_focus_color", Color("492d16"))
		button.add_theme_color_override("font_disabled_color", Color("75654e"))
		for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			button.add_theme_stylebox_override(
				style_name,
				style_source.get_theme_stylebox(style_name).duplicate()
			)


func _setup_initial_view() -> void:
	$GameMenuPanel.hide()
	$PlayPanel.hide()
	$GrowthMessageLabel.position.y -= 110.0

	# PiyokoHolder 自体は CenterContainer が位置を管理するため動かさない。
	# Holder 内の表示要素は通常の Control なので、こちらを直接ずらす。
	_position_piyoko_on_rug()

	_update_status_display()
	_update_piyoko_texture()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("idle")

	if piyoko.growth_stage == -1:
		_start_egg_sequence()
	else:
		_show_care_room()
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.hide()
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.hide()
		_set_action_buttons_disabled(false)

	_update_finish_care_button()


func _position_piyoko_on_rug() -> void:
	var holder := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder
	holder.get_node("PiyokoSprite").position.y += PIYOKO_RUG_OFFSET_Y
	holder.get_node("HatchButton").position.y += PIYOKO_RUG_OFFSET_Y
	holder.get_node("HatchGuideLabel").position.y += PIYOKO_RUG_OFFSET_Y
	if is_instance_valid(piyoko_motion_effect):
		piyoko_motion_effect.sync_base_position()


# ------------------------------------------------------------
# ごはん
# ------------------------------------------------------------

func _on_food_button_pressed() -> void:
	$FoodPanel.visible = not $FoodPanel.visible


func _on_food_close_button_pressed() -> void:
	$FoodPanel.hide()


func _on_shortcake_button_pressed() -> void:
	_start_food_effect("shortcake", "ショートケーキ")


func _on_onigiri_button_pressed() -> void:
	_start_food_effect("onigiri", "おにぎり")


func _on_broccoli_button_pressed() -> void:
	_start_food_effect("broccoli", "ブロッコリー")


func _start_food_effect(food_key: String, display_name: String) -> void:
	if food_effect.is_active():
		return

	$FoodPanel.hide()
	_set_action_buttons_disabled(true)
	_set_reaction_texture("eat")
	food_effect.play(food_key, display_name, get_viewport_rect().size)


func _on_food_effect_finished(food_key: String) -> void:
	piyoko.feed(food_key)

	var likes_food := food_key != "broccoli"
	_finish_care_action(likes_food)

	if not likes_food and not is_growing:
		_play_sad_reaction()
		reaction_effect.play_sad(_get_piyoko_center())


# ------------------------------------------------------------
# なでる
# ------------------------------------------------------------

func _on_pet_button_pressed() -> void:
	if pet_effect.is_active() or food_effect.is_active():
		return

	_set_action_buttons_disabled(true)
	var sprite := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite
	pet_effect.play(sprite, get_viewport_rect().size)


func _on_pet_effect_finished() -> void:
	piyoko.pet()
	_finish_care_action(true)


# ------------------------------------------------------------
# あそぶ
# ------------------------------------------------------------

func _on_play_button_pressed() -> void:
	var texture := PiyokoTextureManager.get_texture(
		piyoko.growth_stage,
		piyoko.child_type,
		piyoko.adult_type
	)
	play_minigame.start(texture, get_viewport_rect().size)


func _on_play_minigame_finished(success: bool) -> void:
	piyoko.play(success)
	_finish_care_action(success)
	if not success and not is_growing:
		_play_sad_reaction()
		reaction_effect.play_sad(_get_piyoko_center())


func _play_sad_reaction() -> void:
	_set_reaction_texture("sad")
	if is_instance_valid(piyoko_motion_effect):
		piyoko_motion_effect.play_sad()

	var sprite: Control = $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite
	sprite.pivot_offset = sprite.size * 0.5

	if is_instance_valid(sad_reaction_tween):
		sad_reaction_tween.kill()

	sad_reaction_tween = create_tween()
	sad_reaction_tween.tween_property(sprite, "rotation_degrees", -5.0, 0.20).set_trans(Tween.TRANS_SINE)
	sad_reaction_tween.parallel().tween_property(sprite, "scale", Vector2(0.92, 0.88), 0.20).set_trans(Tween.TRANS_SINE)
	sad_reaction_tween.parallel().tween_property(sprite, "modulate", Color(0.76, 0.86, 1.0, 1.0), 0.20)
	sad_reaction_tween.tween_interval(0.38)
	sad_reaction_tween.tween_property(sprite, "rotation_degrees", 0.0, 0.28).set_trans(Tween.TRANS_SINE)
	sad_reaction_tween.parallel().tween_property(sprite, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_SINE)
	sad_reaction_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.28)


# ------------------------------------------------------------
# お世話共通処理
# ------------------------------------------------------------

func _finish_care_action(play_happy_animation: bool) -> void:
	var grew := _check_growth()
	_update_status_display()

	if not grew:
		_set_action_buttons_disabled(false)
		if play_happy_animation:
			_set_reaction_texture("happy")
			$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("happy")
			if is_instance_valid(piyoko_motion_effect):
				piyoko_motion_effect.play_happy()
			reaction_effect.play_happy(_get_piyoko_center())

	piyoko.print_status()
	_save_game()


func _set_reaction_texture(reaction_name: String) -> void:
	var reaction_texture := PiyokoTextureManager.get_reaction_texture(
		reaction_name,
		piyoko.growth_stage,
		piyoko.child_type,
		piyoko.adult_type
	)
	if reaction_texture == null:
		return

	var sprite: TextureRect = $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite
	sprite.texture = reaction_texture


func _on_piyoko_motion_finished() -> void:
	# 一時リアクションの終了後は、現在の成長形態の通常画像へ戻す。
	_update_piyoko_texture()


# ------------------------------------------------------------
# 成長・孵化
# ------------------------------------------------------------

func _on_animation_finished(animation_name: StringName) -> void:
	var animation_player := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer
	var sprite := $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite

	match animation_name:
		"happy":
			sprite.scale = Vector2.ONE
			animation_player.play("idle")
			animation_player.seek(0.0, true)
		"grow_out":
			_update_piyoko_texture()
			animation_player.play("grow_in")
		"grow_in":
			_finish_growth_animation(animation_player, sprite)
		"hatch":
			_finish_hatch_animation(animation_player)


func _finish_growth_animation(animation_player: AnimationPlayer, sprite: Control) -> void:
	sprite.scale = Vector2.ONE

	if is_hatching:
		_show_care_room()
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.hide()
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.hide()
		$GrowthMessageLabel.text = "ピヨコが生まれた！"
		is_hatching = false
	else:
		$GrowthMessageLabel.text = "%sになった！" % piyoko.get_growth_stage_name()

	$GrowthMessageLabel.show()
	reaction_effect.play_growth(_get_piyoko_center())
	$GrowthMessageTimer.start()
	is_growing = false
	_set_action_buttons_disabled(false)
	_update_finish_care_button()
	animation_player.play("idle")
	animation_player.seek(0.0, true)


func _finish_hatch_animation(animation_player: AnimationPlayer) -> void:
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
	if not piyoko.check_growth():
		return false

	is_growing = true
	AudioManager.play_se("growth")
	_set_action_buttons_disabled(true)
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("grow_out")
	return true


func _start_egg_sequence() -> void:
	PiyokoCollectionManager.discover("egg")
	_set_action_buttons_disabled(true)
	room_background.texture = BIRTH_BACKGROUND
	birth_message_panel.show()
	$MainMargin/GameLayout/Header.hide()
	$MainMargin/GameLayout/ActionMenu.hide()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.show()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.show()
	_update_piyoko_texture()
	_update_finish_care_button()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("egg_idle")


func _show_care_room() -> void:
	room_background.texture = GAME_BACKGROUND
	birth_message_panel.hide()
	$MainMargin/GameLayout/Header.show()
	$MainMargin/GameLayout/Header/StatusMargin/StatusContainer.show()
	$MainMargin/GameLayout/ActionMenu.show()


func _on_hatch_button_pressed() -> void:
	if piyoko.growth_stage != -1:
		return

	is_hatching = true
	AudioManager.play_se("hatch")
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.hide()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.hide()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("hatch")


# ------------------------------------------------------------
# 表示更新
# ------------------------------------------------------------

func _update_status_display() -> void:
	var required_growth := piyoko.get_required_growth_count()

	if not status_bars.is_empty():
		status_titles["growth"].text = piyoko.get_growth_stage_name()
		status_bars["growth"].max_value = max(1, required_growth)
		status_bars["growth"].value = 1 if required_growth <= 0 else piyoko.growth_count

		status_bars["hunger"].max_value = 5
		status_bars["hunger"].value = piyoko.hunger
		status_bars["friendship"].max_value = 5
		status_bars["friendship"].value = piyoko.friendship
		status_bars["mood"].max_value = 5
		status_bars["mood"].value = piyoko.mood

	if is_instance_valid(reaction_effect):
		reaction_effect.update_mood(piyoko.mood, piyoko.growth_stage, _get_piyoko_center())


func _get_piyoko_center() -> Vector2:
	var sprite: Control = $MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite
	return sprite.get_global_rect().get_center()


func _update_piyoko_texture() -> void:
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/PiyokoSprite.texture = PiyokoTextureManager.get_texture(
		piyoko.growth_stage,
		piyoko.child_type,
		piyoko.adult_type
	)


func _set_action_buttons_disabled(disabled: bool) -> void:
	$MainMargin/GameLayout/ActionMenu/FoodButton.disabled = disabled
	$MainMargin/GameLayout/ActionMenu/PetButton.disabled = disabled
	$MainMargin/GameLayout/ActionMenu/PlayButton.disabled = disabled


func _on_growth_message_timeout() -> void:
	$GrowthMessageLabel.hide()


# ------------------------------------------------------------
# 育成終了
# ------------------------------------------------------------

func _create_finish_care_ui() -> void:
	finish_care_button = Button.new()
	finish_care_button.text = "育成をおえる"
	finish_care_button.custom_minimum_size = Vector2(0, 54)
	finish_care_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_care_button.add_theme_font_size_override("font_size", 22)
	finish_care_button.add_theme_color_override("font_color", Color("492d16"))

	var style_source: Button = $MainMargin/GameLayout/ActionMenu/FoodButton
	for style_name in [&"normal", &"hover", &"pressed", &"disabled"]:
		finish_care_button.add_theme_stylebox_override(
			style_name,
			style_source.get_theme_stylebox(style_name).duplicate()
		)

	finish_care_button.visible = false
	finish_care_button.pressed.connect(_on_finish_care_button_pressed)
	$MainMargin/GameLayout.add_child(finish_care_button)

	finish_care_confirm = ConfirmationDialog.new()
	finish_care_confirm.title = "育成をおえる"
	finish_care_confirm.dialog_text = "このピヨコとの育成をおえ、\n次のたまごへ進みますか？\n\n育成結果は「おもいで」に保存されます。"
	finish_care_confirm.ok_button_text = "おもいでを残して進む"
	finish_care_confirm.cancel_button_text = "まだ一緒にいる"
	finish_care_confirm.confirmed.connect(_on_finish_care_confirmed)
	finish_care_confirm.visibility_changed.connect(_refresh_dialog_dim)
	add_child(finish_care_confirm)
	_apply_dialog_style(finish_care_confirm, Vector2i(820, 350))
	_create_finish_result_ui()


func _apply_dialog_style(dialog: ConfirmationDialog, minimum_size: Vector2i) -> void:
	dialog.min_size = minimum_size
	dialog.borderless = true
	dialog.unresizable = true
	# 標準タイトルバーを使わず、見出しを本文カード内へ収める。
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

	var style_source: Button = $MainMargin/GameLayout/ActionMenu/FoodButton
	for button in [dialog.get_ok_button(), dialog.get_cancel_button()]:
		button.custom_minimum_size = Vector2(330, 66)
		button.add_theme_font_size_override("font_size", 18)
		button.clip_text = false
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override("font_color", Color("492d16"))
		button.add_theme_color_override("font_hover_color", Color("384514"))
		button.add_theme_color_override("font_pressed_color", Color("492d16"))
		button.add_theme_color_override("font_focus_color", Color("492d16"))
		button.add_theme_color_override("font_disabled_color", Color("75654e"))
		for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			button.add_theme_stylebox_override(
				style_name,
				style_source.get_theme_stylebox(style_name).duplicate()
			)


func _update_finish_care_button() -> void:
	finish_care_button.visible = piyoko.growth_stage == 2


func _on_finish_care_button_pressed() -> void:
	finish_care_confirm.popup_centered()


func _on_finish_care_confirmed() -> void:
	finish_care_button.disabled = true
	_set_action_buttons_disabled(true)

	# 育成データを削除する前に、現在のカウンターを1羽分のおもいでとして保存する。
	# Manager側でも育成IDを確認し、同じ個体の重複登録を防止する。
	if not PiyokoMemoryManager.add_completed_piyoko(piyoko):
		finish_care_button.disabled = false
		_set_action_buttons_disabled(false)
		push_error("おもいでの保存に失敗しました")
		return

	var memory_number: int = _find_completed_memory_number()
	if not PiyokoSaveManager.delete_save():
		finish_care_button.disabled = false
		_set_action_buttons_disabled(false)
		push_error("育成完了後のセーブデータ削除に失敗しました")
		return

	_show_finish_result(memory_number)


# 育成結果の保存成功後だけ表示する完了画面。
# 即座に次のたまごへ切り替えず、プレイヤー自身が次の行き先を選ぶ。
func _create_finish_result_ui() -> void:
	finish_result_overlay = Control.new()
	finish_result_overlay.name = "FinishResultOverlay"
	finish_result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	finish_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	finish_result_overlay.z_index = 100
	finish_result_overlay.hide()
	add_child(finish_result_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.12, 0.06, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	finish_result_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish_result_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1000, 540)
	panel.add_theme_stylebox_override("panel", _make_finish_result_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title := Label.new()
	title.text = "育成おつかれさまでした"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("492d16"))
	content.add_child(title)

	var message := Label.new()
	message.text = "この子との毎日を「おもいで」に保存しました。"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color("58743b"))
	content.add_child(message)

	finish_result_portrait = TextureRect.new()
	finish_result_portrait.custom_minimum_size = Vector2(260, 210)
	finish_result_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	finish_result_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(finish_result_portrait)

	finish_result_name_label = Label.new()
	finish_result_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_result_name_label.add_theme_font_size_override("font_size", 27)
	finish_result_name_label.add_theme_color_override("font_color", Color("492d16"))
	content.add_child(finish_result_name_label)

	finish_result_number_label = Label.new()
	finish_result_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_result_number_label.add_theme_font_size_override("font_size", 17)
	finish_result_number_label.add_theme_color_override("font_color", Color("76502c"))
	content.add_child(finish_result_number_label)

	var guide := Label.new()
	guide.text = "また会いたくなったら、いつでも「おもいで」から見られます。"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.add_theme_font_size_override("font_size", 16)
	guide.add_theme_color_override("font_color", Color("58743b"))
	content.add_child(guide)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 30)
	content.add_child(buttons)

	var memories_result_button := Button.new()
	memories_result_button.text = "おもいでを見る"
	_style_finish_result_button(memories_result_button)
	memories_result_button.pressed.connect(_on_finish_result_memories_pressed)
	buttons.add_child(memories_result_button)

	var next_egg_button := Button.new()
	next_egg_button.text = "次のたまごを育てる"
	_style_finish_result_button(next_egg_button)
	next_egg_button.pressed.connect(_on_finish_result_next_egg_pressed)
	buttons.add_child(next_egg_button)


func _show_finish_result(memory_number: int) -> void:
	AudioManager.play_se("care_complete")
	var adult_type: String = piyoko.adult_type
	var adult_form: Dictionary = PiyokoCollectionCatalog.get_form("adult_" + adult_type)
	finish_result_portrait.texture = PiyokoTextureManager.ADULT_TEXTURES.get(
		adult_type,
		PiyokoTextureManager.CHIBI_TEXTURE
	) as Texture2D
	finish_result_name_label.text = str(adult_form.get("name", "大人ぴよこ"))
	finish_result_number_label.text = "おもいで　No.%03d" % memory_number if memory_number > 0 else "おもいでに保存しました"

	$GameMenuPanel.hide()
	$FoodPanel.hide()
	finish_result_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	finish_result_overlay.show()

	finish_result_portrait.pivot_offset = finish_result_portrait.size * 0.5
	finish_result_portrait.scale = Vector2(0.90, 0.90)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(finish_result_overlay, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)
	tween.tween_property(finish_result_portrait, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _find_completed_memory_number() -> int:
	for record in PiyokoMemoryManager.load_memories():
		if str(record.get("source_session_id", "")) == piyoko.session_id:
			return int(record.get("育成No", 0))
	return 0


func _on_finish_result_memories_pressed() -> void:
	get_tree().set_meta(MEMORIES_RETURN_SCENE_META, "res://scenes/game.tscn")
	get_tree().change_scene_to_file("res://scenes/memories.tscn")


func _on_finish_result_next_egg_pressed() -> void:
	get_tree().reload_current_scene()


func _make_finish_result_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.84, 0.98)
	style.border_color = Color("6b9140")
	style.set_border_width_all(4)
	style.set_corner_radius_all(26)
	style.shadow_color = Color(0.12, 0.20, 0.08, 0.42)
	style.shadow_size = 12
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style


func _style_finish_result_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(410, 72)
	button.clip_text = false
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("492d16"))
	button.add_theme_color_override("font_hover_color", Color("384514"))
	button.add_theme_color_override("font_pressed_color", Color("492d16"))

	var style_source: Button = $MainMargin/GameLayout/ActionMenu/FoodButton
	for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(
			style_name,
			style_source.get_theme_stylebox(style_name).duplicate()
		)


# ------------------------------------------------------------
# メニュー・画面遷移
# ------------------------------------------------------------

func _setup_memories_button() -> void:
	memories_button = Button.new()
	memories_button.name = "MemoriesButton"
	memories_button.text = "おもいで"
	memories_button.pressed.connect(_on_memories_button_pressed)

	var game_menu := $GameMenuPanel/GameMenu
	game_menu.add_child(memories_button)
	game_menu.move_child(memories_button, $GameMenuPanel/GameMenu/ResetButton.get_index())
	$GameMenuPanel.custom_minimum_size.y = 350.0
	$GameMenuPanel.offset_bottom = 440.0


func _on_menu_button_pressed() -> void:
	$GameMenuPanel.visible = not $GameMenuPanel.visible


func _on_close_menu_button_pressed() -> void:
	$GameMenuPanel.hide()


func _on_back_to_title_button_pressed() -> void:
	_save_if_started()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_button_pressed() -> void:
	_save_if_started()
	get_tree().quit()


func _on_collection_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/collection.tscn")


func _on_memories_button_pressed() -> void:
	_save_if_started()
	get_tree().set_meta(MEMORIES_RETURN_SCENE_META, "res://scenes/game.tscn")
	get_tree().change_scene_to_file("res://scenes/memories.tscn")


func _on_reset_button_pressed() -> void:
	$GameMenuPanel.hide()
	$ResetConfirmDialog.popup_centered()


func _on_reset_confirmed() -> void:
	if not PiyokoSaveManager.delete_save():
		push_error("育成データのリセットに失敗しました")
		return
	get_tree().reload_current_scene()


# ------------------------------------------------------------
# セーブ
# ------------------------------------------------------------

func _save_game() -> void:
	if not PiyokoSaveManager.save(piyoko):
		push_error("ピヨコのセーブに失敗しました")


func _save_if_started() -> void:
	if piyoko.growth_stage >= 0:
		_save_game()
