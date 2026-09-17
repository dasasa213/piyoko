extends Control

## ゲーム画面全体の制御を担当する。
## 個別のお世話演出は scripts/game/ 配下のコンポーネントへ委譲し、
## このファイルでは育成状態・画面更新・画面遷移を中心に扱う。

const FoodEffectScript = preload("res://scripts/game/food_effect.gd")
const PetEffectScript = preload("res://scripts/game/pet_effect.gd")
const PlayMinigameScript = preload("res://scripts/game/play_minigame.gd")
const GAME_BACKGROUND := preload("res://assets/backgrounds/main_room.png")
const PIYOKO_RUG_OFFSET_Y := 105.0

var piyoko: Piyoko
var is_growing := false
var is_hatching := false

var finish_care_button: Button
var finish_care_confirm: ConfirmationDialog

var food_effect: Node
var pet_effect: Node
var play_minigame: Node


# ------------------------------------------------------------
# 初期化
# ------------------------------------------------------------

func _ready() -> void:
	_setup_background()
	_load_piyoko()
	_connect_scene_signals()
	_setup_components()
	_setup_initial_view()

	print("ゲーム画面：ピヨコを作成しました")
	piyoko.print_status()


# 既存の単色背景を非表示にし、育成画面用の画像を最背面に配置する。
func _setup_background() -> void:
	$Background.hide()

	var background := TextureRect.new()
	background.name = "RoomBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture = GAME_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)
	move_child(background, 0)


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


func _setup_components() -> void:
	_create_finish_care_ui()

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


func _setup_initial_view() -> void:
	$GameMenuPanel.hide()
	$PlayPanel.hide()
	$GrowthMessageLabel.position.y -= 110.0

	# 背景の絨毯中央に見えるよう、ピヨコ一式を少し下へ配置する。
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder.position.y += PIYOKO_RUG_OFFSET_Y

	_update_status_display()
	_update_piyoko_texture()
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("idle")

	if piyoko.growth_stage == -1:
		_start_egg_sequence()
	else:
		$MainMargin/GameLayout/Header/StatusMargin/StatusContainer.show()
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchButton.hide()
		$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/HatchGuideLabel.hide()
		_set_action_buttons_disabled(false)

	_update_finish_care_button()


# ------------------------------------------------------------
# ごはん
# ------------------------------------------------------------

func _on_food_button_pressed() -> void:
	$FoodPanel.show()


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
	food_effect.play(food_key, display_name, get_viewport_rect().size)


func _on_food_effect_finished(food_key: String) -> void:
	piyoko.feed(food_key)
	_finish_care_action(true)


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


# ------------------------------------------------------------
# お世話共通処理
# ------------------------------------------------------------

func _finish_care_action(play_happy_animation: bool) -> void:
	var grew := _check_growth()
	_update_status_display()

	if not grew:
		_set_action_buttons_disabled(false)
		if play_happy_animation:
			$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("happy")

	piyoko.print_status()
	_save_game()


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
	_set_action_buttons_disabled(true)
	$MainMargin/GameLayout/PiyokoArea/PiyokoHolder/AnimationPlayer.play("grow_out")
	return true


func _start_egg_sequence() -> void:
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


# ------------------------------------------------------------
# 表示更新
# ------------------------------------------------------------

func _update_status_display() -> void:
	var status_container := $MainMargin/GameLayout/Header/StatusMargin/StatusContainer
	var required_growth := piyoko.get_required_growth_count()

	if required_growth > 0:
		status_container.get_node("GrowthLabel").text = "%s：%d/%d" % [
			piyoko.get_growth_stage_name(), piyoko.growth_count, required_growth
		]
	else:
		status_container.get_node("GrowthLabel").text = piyoko.get_growth_stage_name()

	status_container.get_node("HungerLabel").text = "おなか：%d/5" % piyoko.hunger
	status_container.get_node("FriendshipLabel").text = "なかよし：%d/5" % piyoko.friendship
	status_container.get_node("MoodLabel").text = "きげん：%d/5" % piyoko.mood


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
	finish_care_button.visible = false
	finish_care_button.pressed.connect(_on_finish_care_button_pressed)
	$MainMargin/GameLayout.add_child(finish_care_button)

	finish_care_confirm = ConfirmationDialog.new()
	finish_care_confirm.title = "育成をおえる"
	finish_care_confirm.dialog_text = "このピヨコの育成をおえますか？\n\n図鑑の発見記録は残り、\n新しいたまごから育成を始められます。"
	finish_care_confirm.ok_button_text = "育成をおえる"
	finish_care_confirm.cancel_button_text = "まだ一緒にいる"
	finish_care_confirm.confirmed.connect(_on_finish_care_confirmed)
	add_child(finish_care_confirm)


func _update_finish_care_button() -> void:
	finish_care_button.visible = piyoko.growth_stage == 2


func _on_finish_care_button_pressed() -> void:
	finish_care_confirm.popup_centered()


func _on_finish_care_confirmed() -> void:
	if not PiyokoSaveManager.delete_save():
		push_error("育成完了後のセーブデータ削除に失敗しました")
		return
	get_tree().reload_current_scene()


# ------------------------------------------------------------
# メニュー・画面遷移
# ------------------------------------------------------------

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
