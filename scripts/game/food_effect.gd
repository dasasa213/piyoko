class_name FoodEffect
extends Node

## ごはん演出を担当するコンポーネント。
## 食べ物素材が完成するまでは文字を表示し、後から画像表示へ差し替えられる構成にする。

signal finished(food_key: String)

var _label: Label
var _active := false


func setup(host: Control) -> void:
	_label = Label.new()
	_label.visible = false
	_label.z_index = 20
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", Color(0.36, 0.20, 0.12, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.95))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.size = Vector2(180, 60)
	host.add_child(_label)


func is_active() -> bool:
	return _active


func play(food_key: String, display_name: String, viewport_size: Vector2) -> void:
	if _active:
		return

	_active = true
	_label.text = display_name
	_label.modulate = Color.WHITE
	_label.scale = Vector2(0.8, 0.8)
	_label.position = Vector2(viewport_size.x * 0.5 - 90.0, viewport_size.y * 0.72)
	_label.show()

	var target_position := Vector2(
		viewport_size.x * 0.5 - 90.0,
		viewport_size.y * 0.50 + 65.0
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_label, "position", target_position, 0.45)
	tween.parallel().tween_property(_label, "scale", Vector2.ONE, 0.45)
	tween.tween_interval(0.25)
	tween.tween_property(_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(_finish.bind(food_key))


func _finish(food_key: String) -> void:
	_label.hide()
	_active = false
	finished.emit(food_key)
