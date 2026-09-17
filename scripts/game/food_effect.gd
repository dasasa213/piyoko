class_name FoodEffect
extends Node

## 「ごはん」のリアクション演出を担当するコンポーネント。
## 食べ物素材を後から追加できるよう、現時点では自然系の吹き出しで反応を表現する。

signal finished(food_key: String)

var _card: PanelContainer
var _label: Label
var _active := false


func setup(host: Control) -> void:
	_card = PanelContainer.new()
	_card.visible = false
	_card.z_index = 20
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.size = Vector2(330, 72)
	_card.pivot_offset = _card.size * 0.5

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.82, 0.96)
	style.border_color = Color("6b9140")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.content_margin_left = 22.0
	style.content_margin_top = 10.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.18, 0.25, 0.10, 0.32)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	_card.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 23)
	_label.add_theme_color_override("font_color", Color("492d16"))
	_label.add_theme_color_override("font_outline_color", Color("fff7d5"))
	_label.add_theme_constant_override("outline_size", 3)
	_card.add_child(_label)
	host.add_child(_card)


func is_active() -> bool:
	return _active


func play(food_key: String, display_name: String, viewport_size: Vector2) -> void:
	if _active:
		return

	_active = true
	_label.text = "%sを もぐもぐ♪" % display_name
	_card.modulate = Color(1, 1, 1, 0)
	_card.scale = Vector2(0.82, 0.82)
	_card.position = Vector2(
		viewport_size.x * 0.5 - (_card.size.x * 0.5),
		viewport_size.y * 0.62
	)
	_card.show()

	var target_y := viewport_size.y * 0.48
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_card, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(_card, "scale", Vector2.ONE, 0.28)
	tween.parallel().tween_property(_card, "position:y", target_y, 0.42)
	tween.tween_interval(0.38)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_card, "position:y", target_y - 22.0, 0.28)
	tween.parallel().tween_property(_card, "modulate:a", 0.0, 0.28)
	tween.tween_callback(_finish.bind(food_key))


func _finish(food_key: String) -> void:
	_card.hide()
	_active = false
	finished.emit(food_key)
