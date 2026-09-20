class_name PetEffect
extends Node

## 「なでる」のリアクション演出を担当するコンポーネント。
## 手の画像をピヨコの頭上で往復させ、やさしく撫でる動きを表現する。

signal finished

const HAND_IMAGE_PATH := "res://assets/effects/pet_hand.png"

var _hand: TextureRect
var _active := false


func setup(host: Control) -> void:
	_hand = TextureRect.new()
	_hand.visible = false
	_hand.z_index = 20
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand.size = Vector2(190, 119)
	_hand.pivot_offset = _hand.size * 0.5
	_hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.add_child(_hand)


func is_active() -> bool:
	return _active


func play(sprite: Control, viewport_size: Vector2) -> void:
	if _active:
		return

	var hand_texture := _load_hand_texture()
	if hand_texture == null:
		push_warning("なでる用の手画像を読み込めません")
		_play_sprite_only(sprite)
		return

	_active = true
	AudioManager.play_se("pet")
	_hand.texture = hand_texture
	_hand.position = Vector2(
		viewport_size.x * 0.5 - 35.0,
		viewport_size.y * 0.38
	)
	_hand.modulate = Color(1, 1, 1, 0)
	_hand.rotation = -0.10
	_hand.scale = Vector2(0.9, 0.9)
	_hand.show()

	var original_rotation: float = sprite.rotation
	var start_position := _hand.position
	var left_position := start_position + Vector2(-72.0, 10.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hand, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(_hand, "scale", Vector2.ONE, 0.18)

	# 頭の右側から左側へ、ゆっくり3回なでる。
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in 3:
		tween.tween_property(_hand, "position", left_position, 0.22)
		tween.parallel().tween_property(_hand, "rotation", 0.06, 0.22)
		tween.parallel().tween_property(sprite, "rotation", original_rotation - 0.055, 0.22)
		tween.tween_property(_hand, "position", start_position, 0.22)
		tween.parallel().tween_property(_hand, "rotation", -0.10, 0.22)
		tween.parallel().tween_property(sprite, "rotation", original_rotation + 0.035, 0.22)

	tween.tween_property(sprite, "rotation", original_rotation, 0.12)
	tween.parallel().tween_property(_hand, "position:y", start_position.y - 24.0, 0.24)
	tween.parallel().tween_property(_hand, "modulate:a", 0.0, 0.24)
	tween.tween_callback(_finish)


func _load_hand_texture() -> Texture2D:
	# エクスポート後はPCK内のインポート済みリソースを読む。
	if not ResourceLoader.exists(HAND_IMAGE_PATH):
		return null
	return ResourceLoader.load(HAND_IMAGE_PATH) as Texture2D


func _play_sprite_only(sprite: Control) -> void:
	# 万一画像が読めなくても、操作を止めず最低限のリアクションを完了させる。
	_active = true
	AudioManager.play_se("pet")
	var original_rotation := sprite.rotation
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "rotation", original_rotation - 0.08, 0.18)
	tween.tween_property(sprite, "rotation", original_rotation + 0.08, 0.22)
	tween.tween_property(sprite, "rotation", original_rotation, 0.18)
	tween.tween_callback(_finish)


func _finish() -> void:
	_hand.hide()
	_active = false
	finished.emit()
