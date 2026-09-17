extends Control


@onready var count_label: Label = $MainMargin/CollectionLayout/Countlabel
@onready var back_button: Button = $MainMargin/CollectionLayout/BackButton


func _ready() -> void:
	update_collection_count()

	back_button.pressed.connect(
		_on_back_button_pressed
	)


func update_collection_count() -> void:
	var discovered_count := PiyokoCollectionManager.discovered.size()
	var total_count := 9

	count_label.text = "発見数：%d / %d" % [
		discovered_count,
		total_count
	]


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
