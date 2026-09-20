extends Node

const NORMAL_CURSOR := preload("res://assets/ui/cursor_piyoko_normal.png")
const HOVER_CURSOR := preload("res://assets/ui/cursor_piyoko_hover.png")
const CURSOR_HOTSPOT := Vector2(15, 12)


func _ready() -> void:
	Input.set_custom_mouse_cursor(NORMAL_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	Input.set_custom_mouse_cursor(HOVER_CURSOR, Input.CURSOR_POINTING_HAND, CURSOR_HOTSPOT)
	get_tree().node_added.connect(_on_node_added)
	_apply_pointing_cursor(get_tree().root)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _apply_pointing_cursor(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_apply_pointing_cursor(child)
