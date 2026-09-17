class_name PetEffect
extends Node

## 「なでる」演出を担当するコンポーネント。
## 操作はボタンを押すだけで、ピヨコへの直接ドラッグ操作は行わない。

signal finished

var _label: Label
var _active := false


func setup(host: Control) -> void:
	_label = Label.new()
	_label.visible = false
	_label.z_index = 20
	_label.text = "♡  なでなで  ♡"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(0.88, 0.30, 0.46, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.95))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.size = Vector2(240, 60)
	host.add_child(_label)


func is_active() -> bool:
	return _active


func play(sprite: Node2D, viewport_size: Vector2) -> void:
	if _active:
		return

	_active = true
	_label.position = Vector2(viewport_size.x * 0.5 - 120.0, viewport_size.y * 0.42)
	_label.modulate = Color(1, 1, 1, 0)
	_label.scale = Vector2(0.8, 0.8)
	_label.show()

	# 型を明示し、Godotの型推論エラーを避ける。
	var original_rotation: float = float(sprite.rotation)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_label, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(_label, "scale", Vector2.ONE, 0.15)
	tween.tween_property(sprite, "rotation", original_rotation - 0.08, 0.12)
	tween.tween_property(sprite, "rotation", original_rotation + 0.08, 0.18)
	tween.tween_property(sprite, "rotation", original_rotation - 0.05, 0.18)
	tween.tween_property(sprite, "rotation", original_rotation, 0.12)
	tween.parallel().tween_property(_label, "position:y", _label.position.y - 28.0, 0.35)
	tween.parallel().tween_property(_label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(_finish)


func _finish() -> void:
	_label.hide()
	_active = false
	finished.emit()
