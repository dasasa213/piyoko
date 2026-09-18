class_name ReactionEffect
extends Node

## 育成値を変更せず、ピヨコの状態に合わせた画面演出だけを担当する。

const LOW_MOOD_THRESHOLD := 1
const HIGH_MOOD_THRESHOLD := 4
const RAIN_X_OFFSETS := [-58.0, -29.0, 0.0, 29.0, 58.0]
const RAIN_PHASE_OFFSETS := [0.0, 17.0, 35.0, 8.0, 27.0]
const GROWTH_TEXTURE_PATH := "res://assets/effects/09_growth.png"
const HAPPY_HEART_PATH := "res://assets/effects/happy_heart.png"
const SAD_SWEAT_PATH := "res://assets/effects/sad_sweat.png"

var _rain_drops: Array[TextureRect] = []
var _rain_center := Vector2.ZERO
var _rain_elapsed := 0.0
var _rain_active := false
var _mood_heart: TextureRect
var _mood_happy_active := false
var _growth: TextureRect
var _growth_tween: Tween
var _emotion_icon: TextureRect
var _emotion_tween: Tween


func setup(host: Control) -> void:
	var rain_texture := _load_texture(SAD_SWEAT_PATH)
	for index in RAIN_X_OFFSETS.size():
		var drop := _create_effect_rect(host, Vector2(24, 24))
		drop.texture = rain_texture
		drop.modulate = Color(0.78, 0.90, 1.0, 0.52)
		drop.hide()
		_rain_drops.append(drop)

	_mood_heart = _create_effect_rect(host, Vector2(42, 42))
	_mood_heart.texture = _load_texture(HAPPY_HEART_PATH)
	_mood_heart.modulate = Color(1, 1, 1, 0.58)
	_mood_heart.hide()

	_growth = _create_effect_rect(host, Vector2(320, 320))
	_growth.texture = _load_texture(GROWTH_TEXTURE_PATH)
	_growth.hide()

	_emotion_icon = _create_effect_rect(host, Vector2(72, 72))
	_emotion_icon.hide()


func update_mood(mood: int, growth_stage: int, piyoko_center: Vector2) -> void:
	var has_piyoko := growth_stage >= 0
	update_anchor(piyoko_center)
	_rain_active = has_piyoko and mood <= LOW_MOOD_THRESHOLD

	for drop in _rain_drops:
		drop.visible = _rain_active

	_mood_happy_active = has_piyoko and mood >= HIGH_MOOD_THRESHOLD
	if is_instance_valid(_mood_heart):
		_position_on_piyoko(_mood_heart, piyoko_center, Vector2(-60, -78))
		_mood_heart.visible = _mood_happy_active and not _emotion_icon.visible


func update_anchor(piyoko_center: Vector2) -> void:
	_rain_center = piyoko_center

	if is_instance_valid(_mood_heart):
		_position_on_piyoko(_mood_heart, piyoko_center, Vector2(-60, -78))


func _process(delta: float) -> void:
	if _rain_active:
		_rain_elapsed += delta
		for index in _rain_drops.size():
			var fall_y := fposmod(_rain_elapsed * 34.0 + RAIN_PHASE_OFFSETS[index], 48.0)
			_rain_drops[index].position = Vector2(
				_rain_center.x + RAIN_X_OFFSETS[index] - 12.0,
				_rain_center.y - 112.0 + fall_y
			)

	if _mood_happy_active and is_instance_valid(_mood_heart) and not _emotion_icon.visible:
		_mood_heart.modulate.a = 0.55 + sin(Time.get_ticks_msec() * 0.003) * 0.08


func play_happy(piyoko_center: Vector2) -> void:
	_play_emotion(HAPPY_HEART_PATH, piyoko_center, Vector2(-66, -82))


func play_sad(piyoko_center: Vector2) -> void:
	_play_emotion(SAD_SWEAT_PATH, piyoko_center, Vector2(68, -66))


func _play_emotion(texture_path: String, piyoko_center: Vector2, offset: Vector2) -> void:
	if not is_instance_valid(_emotion_icon):
		return

	var texture := _load_texture(texture_path)
	if texture == null:
		return

	if is_instance_valid(_emotion_tween):
		_emotion_tween.kill()

	if is_instance_valid(_mood_heart):
		_mood_heart.hide()

	_emotion_icon.texture = texture
	_position_on_piyoko(_emotion_icon, piyoko_center, offset)
	var start_position := _emotion_icon.position
	_emotion_icon.modulate = Color(1, 1, 1, 0)
	_emotion_icon.scale = Vector2(0.78, 0.78)
	_emotion_icon.show()

	_emotion_tween = create_tween()
	_emotion_tween.tween_property(_emotion_icon, "modulate:a", 0.92, 0.18)
	_emotion_tween.parallel().tween_property(_emotion_icon, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_emotion_tween.parallel().tween_property(_emotion_icon, "position", start_position + Vector2(0, -7), 0.22)
	_emotion_tween.tween_interval(0.42)
	_emotion_tween.tween_property(_emotion_icon, "modulate:a", 0.0, 0.28)
	_emotion_tween.parallel().tween_property(_emotion_icon, "position", start_position + Vector2(0, -13), 0.28)
	_emotion_tween.tween_callback(_finish_emotion)


func _finish_emotion() -> void:
	_emotion_icon.hide()
	if is_instance_valid(_mood_heart):
		_mood_heart.visible = _mood_happy_active


func play_growth(piyoko_center: Vector2) -> void:
	if not is_instance_valid(_growth) or _growth.texture == null:
		return

	_position_on_piyoko(_growth, piyoko_center, Vector2.ZERO)
	_growth.show()
	_growth.modulate = Color(1, 1, 1, 0)
	_growth.scale = Vector2(0.92, 0.92)

	if is_instance_valid(_growth_tween):
		_growth_tween.kill()

	_growth_tween = create_tween()
	_growth_tween.set_parallel(true)
	# 小さな光が静かに浮かぶ程度に抑える。
	_growth_tween.tween_property(_growth, "modulate:a", 0.55, 0.38)
	_growth_tween.tween_property(_growth, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_growth_tween.chain().tween_interval(0.36)
	_growth_tween.chain().tween_property(_growth, "modulate:a", 0.0, 0.48)
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


func _position_on_piyoko(effect: TextureRect, piyoko_center: Vector2, offset: Vector2) -> void:
	effect.position = piyoko_center - effect.size * 0.5 + offset


func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("リアクション画像を読み込めませんでした: %s" % path)
		return null
	return ImageTexture.create_from_image(image)
