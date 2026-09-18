extends Node

## ゲーム全体のBGM・効果音を一元管理する。
## シーン変更時のBGM切替と、通常Buttonの操作音もここで扱う。

const SETTINGS_PATH := "user://piyoko_settings.cfg"

const TITLE_BGM := preload("res://audio/bgm/title_bgm.mp3")
const CARE_BGM := preload("res://audio/bgm/care_bgm.mp3")

const SE_STREAMS := {
	"button_confirm": preload("res://audio/se/button_confirm.mp3"),
	"button_cancel": preload("res://audio/se/button_cancel.mp3"),
	"menu_open": preload("res://audio/se/menu_open.mp3"),
	"eat": preload("res://audio/se/eat.mp3"),
	"pet": preload("res://audio/se/pet.mp3"),
	"play_touch": preload("res://audio/se/play_touch.mp3"),
	"play_success": preload("res://audio/se/play_success.mp3"),
	"play_failure": preload("res://audio/se/play_failure.mp3"),
	"hatch": preload("res://audio/se/hatch.mp3"),
	"growth": preload("res://audio/se/growth.mp3"),
	"care_complete": preload("res://audio/se/care_complete.mp3"),
}

var _bgm_player: AudioStreamPlayer
var _se_players: Array[AudioStreamPlayer] = []
var _next_se_player := 0
var _current_bgm := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_players()
	_load_saved_volume()

	get_tree().scene_changed.connect(_on_scene_changed)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_connect_existing_buttons")
	call_deferred("_refresh_bgm")


func _create_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	add_child(_bgm_player)

	# 同時に鳴る操作音を途切れさせないよう、小さな再生プールを用意する。
	for index in 6:
		var player := AudioStreamPlayer.new()
		player.name = "SEPlayer%d" % (index + 1)
		add_child(player)
		_se_players.append(player)


func _load_saved_volume() -> void:
	var config := ConfigFile.new()
	var volume := 80.0
	if config.load(SETTINGS_PATH) == OK:
		volume = float(config.get_value("audio", "master_volume", 80.0))

	volume = clamp(volume, 0.0, 100.0)
	AudioServer.set_bus_mute(0, volume <= 0.0)
	if volume > 0.0:
		AudioServer.set_bus_volume_db(0, linear_to_db(volume / 100.0))


func _on_scene_changed(_scene: Node) -> void:
	call_deferred("_refresh_bgm")
	call_deferred("_connect_existing_buttons")


func _refresh_bgm() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var scene_path := scene.scene_file_path
	if scene_path == "res://scenes/game.tscn":
		_play_bgm("care", CARE_BGM)
	else:
		_play_bgm("title", TITLE_BGM)


func _play_bgm(key: String, stream: AudioStreamMP3) -> void:
	if _current_bgm == key and _bgm_player.playing:
		return

	stream.loop = true
	_current_bgm = key
	_bgm_player.stream = stream
	_bgm_player.play()


func play_se(key: String) -> void:
	var stream: AudioStream = SE_STREAMS.get(key)
	if stream == null or _se_players.is_empty():
		return

	var player := _se_players[_next_se_player]
	_next_se_player = (_next_se_player + 1) % _se_players.size()
	player.stream = stream
	player.play()


func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("_connect_button", node)


func _connect_existing_buttons() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	_connect_buttons_recursive(scene)


func _connect_buttons_recursive(node: Node) -> void:
	if node is Button:
		_connect_button(node)
	for child in node.get_children():
		_connect_buttons_recursive(child)


func _connect_button(button: Button) -> void:
	var callback := _on_button_pressed.bind(button)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_button_pressed(button: Button) -> void:
	var label := (str(button.name) + " " + button.text).to_lower()
	var cancel_words := ["back", "close", "cancel", "quit", "もど", "とじ", "やめる", "終了"]
	for word in cancel_words:
		if label.contains(word):
			play_se("button_cancel")
			return

	var menu_words := ["menu", "options", "メニュー", "設定"]
	for word in menu_words:
		if label.contains(word):
			play_se("menu_open")
			return

	play_se("button_confirm")
