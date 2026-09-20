extends Node

const REAPPLY_INTERVAL_SECONDS := 1.0

var _elapsed := 0.0


func _ready() -> void:
	if not OS.has_feature("android"):
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_reapply_immersive_mode")


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < REAPPLY_INTERVAL_SECONDS:
		return
	_elapsed = 0.0
	_reapply_immersive_mode()


func _notification(what: int) -> void:
	if not OS.has_feature("android"):
		return
	if what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		call_deferred("_reapply_immersive_mode")


func _reapply_immersive_mode() -> void:
	# Androidではシステムバー表示後もGodot側の状態がFULLSCREENのままになり、
	# 同じモードを再指定するだけでは非表示処理が走らない。
	# 一度MAXIMIZEDへ切り替えてからFULLSCREENへ戻し、没入型表示を確実に再適用する。
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
