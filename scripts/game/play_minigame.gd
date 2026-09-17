class_name PlayMinigame
extends Node

## 「あそぶ」のタッチミニゲームを担当するコンポーネント。
## ゲーム本体には成功/失敗だけを通知し、育成値の変更は game.gd 側で行う。

signal completed(success: bool)

const TARGET_COUNT := 3
const TIME_LIMIT := 5.0
const RESULT_TIME := 1.2

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
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(_panel)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.91764706, 0.95686275, 0.8745098, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(background)

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
	_result_label.add_theme_font_size_override("font_size", 52)
	_result_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.95))
	_result_label.anchor_top = 0.5
	_result_label.anchor_right = 1.0
	_result_label.anchor_bottom = 0.5
	_result_label.offset_top = -55.0
	_result_label.offset_bottom = 55.0
	_panel.add_child(_result_label)

	_target = TextureButton.new()
	_target.ignore_texture_size = true
	_target.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_target.size = Vector2(128, 128)
	_target.pressed.connect(_on_target_pressed)
	_panel.add_child(_target)

	_cancel_button = Button.new()
	_cancel_button.text = "やめる"
	_cancel_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_cancel_button.offset_left = 24.0
	_cancel_button.offset_right = -24.0
	_cancel_button.offset_top = -70.0
	_cancel_button.offset_bottom = -18.0
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_panel.add_child(_cancel_button)


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
