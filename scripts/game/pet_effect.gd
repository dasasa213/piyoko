class_name PetEffect
extends Node

## 「なでる」のリアクション演出を担当するコンポーネント。
## 操作はボタンを押すだけで、ピヨコへの直接ドラッグ操作は行わない。
## PiyokoSprite は TextureRect のため、演出対象は Control として受け取る。

signal finished

var _card: PanelContainer
var _label: Label
var _active := false


func setup(host: Control) -> void:
	_card = PanelContainer.new()
	_card.visible = false
	_card.z_index = 20
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.size = Vector2(300, 72)
	_card.pivot_offset = _card.size * 0.5

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.91, 0.92, 0.97)
	style.border_color = Color("d9788f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.content_margin_left = 22.0
	style.content_margin_top = 10.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.35, 0.16, 0.18, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	_card.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.text = "♡  なでなで  ♡"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 25)
	_label.add_theme_color_override("font_color", Color("a94761"))
	_label.add_theme_color_override("font_outline_color", Color("fff7f0"))
	_label.add_theme_constant_override("outline_size", 3)
	_card.add_child(_label)
	host.add_child(_card)


func is_active() -> bool:
	return _active


func play(sprite: Control, viewport_size: Vector2) -> void:
	if _active:
		return

	_active = true
	_card.position = Vector2(
		viewport_size.x * 0.5 - (_card.size.x * 0.5),
		viewport_size.y * 0.39
	)
	_card.modulate = Color(1, 1, 1, 0)
	_card.scale = Vector2(0.82, 0.82)
	_card.show()

	# TextureRect(Control) の回転を軽く揺らして、なでられている反応を表現する。
	var original_rotation: float = sprite.rotation
	var start_y := _card.position.y

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_card, "modulate:a", 1.0, 0.16)
	tween.parallel().tween_property(_card, "scale", Vector2.ONE, 0.24)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "rotation", original_rotation - 0.08, 0.12)
	tween.tween_property(sprite, "rotation", original_rotation + 0.08, 0.18)
	tween.tween_property(sprite, "rotation", original_rotation - 0.05, 0.18)
	tween.tween_property(sprite, "rotation", original_rotation, 0.12)
	tween.parallel().tween_property(_card, "position:y", start_y - 28.0, 0.35)
	tween.parallel().tween_property(_card, "modulate:a", 0.0, 0.35)
	tween.tween_callback(_finish)


func _finish() -> void:
	_card.hide()
	_active = false
	finished.emit()
