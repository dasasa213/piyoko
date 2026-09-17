class_name ReactionEffect
extends Node

## 育成値を変更せず、ピヨコの状態に合わせた画面演出だけを担当する。

const LOW_MOOD_THRESHOLD := 1
const RAIN_TEXTURE_PATH := "res://assets/effects/07_rain.png"
const GROWTH_TEXTURE_PATH := "res://assets/effects/09_growth.png"

var _rain: TextureRect
var _growth: TextureRect
var _growth_tween: Tween


func setup(host: Control) -> void:
	_rain = _create_effect_rect(host, Vector2(320, 280))
	_rain.texture = _load_texture(RAIN_TEXTURE_PATH)
	_rain.modulate = Color(1, 1, 1, 0.82)
	_rain.hide()

	_growth = _create_effect_rect(host, Vector2(440, 440))
	_growth.texture = _load_texture(GROWTH_TEXTURE_PATH)
	_growth.hide()


func update_mood(mood: int, growth_stage: int, viewport_size: Vector2) -> void:
	if not is_instance_valid(_rain):
		return

	_position_centered(_rain, viewport_size, Vector2(0, 55))
	_rain.visible = growth_stage >= 0 and mood <= LOW_MOOD_THRESHOLD


func play_growth(viewport_size: Vector2) -> void:
	if not is_instance_valid(_growth) or _growth.texture == null:
		return

	_position_centered(_growth, viewport_size, Vector2(0, 55))
	_growth.show()
	_growth.modulate = Color(1, 1, 1, 0)
	_growth.scale = Vector2(0.62, 0.62)

	if is_instance_valid(_growth_tween):
		_growth_tween.kill()

	_growth_tween = create_tween()
	_growth_tween.set_parallel(true)
	_growth_tween.tween_property(_growth, "modulate:a", 1.0, 0.24)
	_growth_tween.tween_property(_growth, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_growth_tween.chain().tween_interval(0.42)
	_growth_tween.chain().tween_property(_growth, "modulate:a", 0.0, 0.34)
	_growth_tween.chain().tween_callback(_growth.hide)


func _create_effect_rect(host: Control, effect_size: Vector2) -> TextureRect:
	var effect := TextureRect.new()
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	effect.size = effect_size
	effect.pivot_offset = effect_size * 0.5
	host.add_child(effect)
	return effect


func _position_centered(effect: TextureRect, viewport_size: Vector2, offset: Vector2) -> void:
	effect.position = (viewport_size - effect.size) * 0.5 + offset


func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("リアクション画像を読み込めませんでした: %s" % path)
		return null
	return ImageTexture.create_from_image(image)
