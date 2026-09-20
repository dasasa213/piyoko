class_name FoodEffect
extends Node

## 「ごはん」の演出を担当するコンポーネント。
## 選んだ食べ物を画面下からピヨコの口元へ運び、縮小して食べたように見せる。

signal finished(food_key: String)

const FOOD_TEXTURES := {
	"res://assets/items/food/01_shortcake.png": preload("res://assets/items/food/01_shortcake.png"),
	"res://assets/items/food/02_onigiri.png": preload("res://assets/items/food/02_onigiri.png"),
	"res://assets/items/food/03_broccoli.png": preload("res://assets/items/food/03_broccoli.png"),
}

var _food_image: TextureRect
var _reaction_label: Label
var _active := false


func setup(host: Control) -> void:
	_food_image = TextureRect.new()
	_food_image.visible = false
	_food_image.z_index = 20
	_food_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_food_image.size = Vector2(150, 150)
	_food_image.pivot_offset = _food_image.size * 0.5
	_food_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_food_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.add_child(_food_image)

	_reaction_label = Label.new()
	_reaction_label.visible = false
	_reaction_label.z_index = 21
	_reaction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reaction_label.size = Vector2(320, 48)
	_reaction_label.text = "いただきます♪"
	_reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reaction_label.add_theme_font_size_override("font_size", 23)
	_reaction_label.add_theme_color_override("font_color", Color("492d16"))
	_reaction_label.add_theme_color_override("font_outline_color", Color("fff7d5"))
	_reaction_label.add_theme_constant_override("outline_size", 7)
	host.add_child(_reaction_label)


func is_active() -> bool:
	return _active


func play(food_key: String, _display_name: String, viewport_size: Vector2) -> void:
	if _active:
		return
	var food := PiyokoFoodCatalog.get_food(food_key)
	if food.is_empty():
		push_warning("食べ物画像が見つかりません: %s" % food_key)
		finished.emit(food_key)
		return

	var texture := _load_food_texture(str(food.get("image", "")))
	if texture == null:
		push_warning("食べ物画像を読み込めません: %s" % food_key)
		finished.emit(food_key)
		return

	_active = true
	_food_image.texture = texture
	_food_image.position = Vector2(
		viewport_size.x * 0.5 - (_food_image.size.x * 0.5),
		viewport_size.y * 0.74
	)
	_food_image.scale = Vector2(0.78, 0.78)
	_food_image.modulate = Color.WHITE
	_food_image.show()

	_reaction_label.position = Vector2(
		viewport_size.x * 0.5 - (_reaction_label.size.x * 0.5),
		viewport_size.y * 0.39
	)
	_reaction_label.modulate = Color(1, 1, 1, 0)
	_reaction_label.show()

	# ピヨコの口元へ運び、最後に小さくして「食べた」動きにする。
	var mouth_position := Vector2(
		viewport_size.x * 0.5 - (_food_image.size.x * 0.5),
		viewport_size.y * 0.52
	)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_food_image, "position", mouth_position, 0.48)
	tween.parallel().tween_property(_food_image, "scale", Vector2.ONE, 0.34)
	tween.parallel().tween_property(_reaction_label, "modulate:a", 1.0, 0.22)
	tween.tween_interval(0.25)
	tween.tween_callback(AudioManager.play_se.bind("eat"))
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_food_image, "scale", Vector2(0.12, 0.12), 0.30)
	tween.parallel().tween_property(_food_image, "modulate:a", 0.0, 0.24)
	tween.parallel().tween_property(_reaction_label, "position:y", _reaction_label.position.y - 18.0, 0.30)
	tween.parallel().tween_property(_reaction_label, "modulate:a", 0.0, 0.30)
	tween.tween_callback(_finish.bind(food_key))


func _load_food_texture(path: String) -> Texture2D:
	return FOOD_TEXTURES.get(path) as Texture2D


func _finish(food_key: String) -> void:
	_food_image.hide()
	_reaction_label.hide()
	_active = false
	finished.emit(food_key)
