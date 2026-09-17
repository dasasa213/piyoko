class_name PlayMinigame
extends Node

## 「あそぶ」のタッチミニゲームを担当するコンポーネント。
## ゲーム本体には成功/失敗だけを通知し、育成値の変更は game.gd 側で行う。

signal completed(success: bool)

const TARGET_COUNT := 3
const TIME_LIMIT := 5.0
const RESULT_TIME := 1.5

var _panel: Control
var _target: TextureButton
var _count_label: Label
var _time_label: Label
var _result_label: Label
var _cancel_button: Button
var _game_timer: Timer
var _result_timer: Timer

var _hits := 0
var _active := false
var _pending_success := false


func setup(host: Control) -> void:
	_create_panel(host)
	_create_timers()


func start(texture: Texture2D, viewport_size: Vector2) -> void:
	if _active or not _result_timer.is_stopped():
		return

	_active = true
	_hits = 0
	_result_label.hide()
	_count_label.show()
	_time_label.show()
	_target.show()
	_target.disabled = false
	_cancel_button.show()
	_panel.show()

	_target.texture_normal = texture
	_update_count()
	_move_target(viewport_size)
	_game_timer.start()


func _process(_delta: float) -> void:
	if _active:
		_time_label.text = "のこり %.1f 秒" % _game_timer.time_left


func _create_panel(host: Control) -> void:
	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	_panel.z_index = 50
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(_panel)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("fff8df")
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(background)

	var header_card := Panel.new()
	header_card.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header_card.offset_left = 180.0
	header_card.offset_top = 18.0
	header_card.offset_right = -180.0
	header_card.offset_bottom = 150.0
	header_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(1.0, 0.98, 0.88, 0.96)
	header_style.border_color = Color("6b9140")
	header_style.set_border_width_all(3)
	header_style.set_corner_radius_all(24)
	header_style.shadow_color = Color(0.18, 0.25, 0.10, 0.24)
	header_style.shadow_size = 7
	header_style.shadow_offset = Vector2(0, 4)
	header_card.add_theme_stylebox_override("panel", header_style)
	_panel.add_child(header_card)

	var title := Label.new()
	title.text = "ピヨコを3回タッチ！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.36, 0.20, 0.12, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.9))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24.0
	title.offset_bottom = 66.0
	_panel.add_child(title)

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 24)
	_count_label.add_theme_color_override("font_color", Color(0.72, 0.24, 0.16, 1.0))
	_count_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_count_label.offset_top = 72.0
	_count_label.offset_bottom = 106.0
	_panel.add_child(_count_label)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 22)
	_time_label.add_theme_color_override("font_color", Color(0.18, 0.32, 0.22, 1.0))
	_time_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_time_label.offset_top = 108.0
	_time_label.offset_bottom = 142.0
	_panel.add_child(_time_label)

	_result_label = Label.new()
	_result_label.visible = false
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 50)
	_result_label.add_theme_color_override("font_shadow_color", Color(0.22, 0.14, 0.08, 0.24))
	_result_label.add_theme_constant_override("shadow_offset_x", 3)
	_result_label.add_theme_constant_override("shadow_offset_y", 4)
	_result_label.add_theme_color_override("font_outline_color", Color("fff8df"))
	_result_label.add_theme_constant_override("outline_size", 9)
	_result_label.anchor_top = 0.5
	_result_label.anchor_right = 1.0
	_result_label.anchor_bottom = 0.5
	_result_label.offset_top = -70.0
	_result_label.offset_bottom = 70.0
	_panel.add_child(_result_label)

	_target = TextureButton.new()
	_target.ignore_texture_size = true
	_target.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_target.size = Vector2(128, 128)
	_target.pressed.connect(_on_target_pressed)
	_panel.add_child(_target)

	_cancel_button = Button.new()
	_cancel_button.text = "あそびをやめる"
	_cancel_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_cancel_button.offset_left = -150.0
	_cancel_button.offset_right = 150.0
	_cancel_button.offset_top = -78.0
	_cancel_button.offset_bottom = -22.0
	_cancel_button.add_theme_font_size_override("font_size", 19)
	_cancel_button.add_theme_color_override("font_color", Color("492d16"))
	_cancel_button.add_theme_color_override("font_hover_color", Color("384514"))
	_cancel_button.add_theme_color_override("font_pressed_color", Color("492d16"))
	_cancel_button.add_theme_color_override("font_focus_color", Color("492d16"))
	_cancel_button.add_theme_stylebox_override("normal", _make_play_button_style(Color("fff7d5"), Color("76502c"), 2))
	_cancel_button.add_theme_stylebox_override("hover", _make_play_button_style(Color("ffe38a"), Color("6b9140"), 3))
	_cancel_button.add_theme_stylebox_override("pressed", _make_play_button_style(Color("f5ce63"), Color("567a31"), 3))
	_cancel_button.add_theme_stylebox_override("focus", _make_play_button_style(Color("fff7d5"), Color("6b9140"), 3))
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_panel.add_child(_cancel_button)


func _make_play_button_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24.0
	style.content_margin_top = 10.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.18, 0.12, 0.05, 0.28)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style


func _create_timers() -> void:
	_game_timer = Timer.new()
	_game_timer.wait_time = TIME_LIMIT
	_game_timer.one_shot = true
	_game_timer.timeout.connect(_on_time_up)
	add_child(_game_timer)

	_result_timer = Timer.new()
	_result_timer.wait_time = RESULT_TIME
	_result_timer.one_shot = true
	_result_timer.timeout.connect(_on_result_timeout)
	add_child(_result_timer)


func _on_target_pressed() -> void:
	if not _active:
		return

	_hits += 1
	_update_count()

	if _hits >= TARGET_COUNT:
		_show_result(true)
	else:
		_move_target(get_viewport().get_visible_rect().size)


func _move_target(viewport_size: Vector2) -> void:
	var min_position := Vector2(40, 155)
	var max_position := Vector2(
		max(min_position.x, viewport_size.x - 168.0),
		max(min_position.y, viewport_size.y - 223.0)
	)

	_target.position = Vector2(
		randf_range(min_position.x, max_position.x),
		randf_range(min_position.y, max_position.y)
	)


func _update_count() -> void:
	_count_label.text = "%d / %d" % [_hits, TARGET_COUNT]


func _on_time_up() -> void:
	if _active:
		_show_result(false)


func _show_result(success: bool) -> void:
	if not _active:
		return

	_active = false
	_pending_success = success
	_game_timer.stop()

	_target.disabled = true
	_target.hide()
	_count_label.hide()
	_time_label.hide()
	_cancel_button.hide()
	_result_label.show()

	if success:
		_result_label.text = "せいこう！\nやったね！"
		_result_label.add_theme_color_override("font_color", Color(0.90, 0.36, 0.12, 1.0))
	else:
		_result_label.text = "しっぱい…\nざんねん！"
		_result_label.add_theme_color_override("font_color", Color(0.28, 0.36, 0.58, 1.0))

	_result_timer.start()


func _on_result_timeout() -> void:
	_result_label.hide()
	_panel.hide()
	completed.emit(_pending_success)


func _on_cancel_pressed() -> void:
	if not _active:
		return

	_active = false
	_game_timer.stop()
	_panel.hide()
