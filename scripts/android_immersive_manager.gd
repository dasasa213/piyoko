extends Node


func _ready() -> void:
	if not OS.has_feature("android"):
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_reapply_immersive_mode")


func _notification(what: int) -> void:
	if not OS.has_feature("android"):
		return
	if what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		call_deferred("_reapply_immersive_mode")


func _reapply_immersive_mode() -> void:
	# 起動時とアプリ復帰時だけ没入型表示を再適用する。
	# 定期実行するとAndroidのシステムバーが点滅し、
	# 通知パネルや戻る・ホーム操作を妨げるため行わない。
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
