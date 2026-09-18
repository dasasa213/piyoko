class_name PiyokoMotionEffect
extends Node

## ピヨコ本体の一時的なリアクションを担当する。
## 通常の idle / happy アニメーションとは別に位置だけを動かすことで、
## 既存の AnimationPlayer と競合せず「浮く・震える」を追加する。

var _sprite: Control
var _base_position := Vector2.ZERO
var _motion_tween: Tween


func setup(sprite: Control) -> void:
	_sprite = sprite
	_base_position = sprite.position


func play_happy() -> void:
	if not is_instance_valid(_sprite):
		return

	_reset_running_motion()
	_sprite.position = _base_position

	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(_sprite, "position:y", _base_position.y - 18.0, 0.16)
	_motion_tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(_sprite, "position:y", _base_position.y, 0.30)
	_motion_tween.tween_interval(0.10)
	_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(_sprite, "position:y", _base_position.y - 9.0, 0.12)
	_motion_tween.tween_property(_sprite, "position:y", _base_position.y, 0.20)
	_motion_tween.tween_callback(_finish_motion)


func play_sad() -> void:
	if not is_instance_valid(_sprite):
		return

	_reset_running_motion()
	_sprite.position = _base_position

	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_property(_sprite, "position", _base_position + Vector2(-5.0, 7.0), 0.16)
	_motion_tween.tween_property(_sprite, "position", _base_position + Vector2(4.0, 7.0), 0.18)
	_motion_tween.tween_property(_sprite, "position", _base_position + Vector2(-3.0, 5.0), 0.16)
	_motion_tween.tween_interval(0.28)
	_motion_tween.tween_property(_sprite, "position", _base_position, 0.26)
	_motion_tween.tween_callback(_finish_motion)


func reset() -> void:
	_reset_running_motion()
	if is_instance_valid(_sprite):
		_sprite.position = _base_position


func _reset_running_motion() -> void:
	if is_instance_valid(_motion_tween):
		_motion_tween.kill()


func _finish_motion() -> void:
	if is_instance_valid(_sprite):
		_sprite.position = _base_position
	_motion_tween = null
