extends SceneTree

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	print("\n=== Piyoko automated full test ===")
	await process_frame
	_test_definition_catalog()
	_test_cursor_assets()
	_test_exported_effect_textures()
	_test_item_catalog()
	_test_food_catalog()
	_test_child_evolutions()
	_test_all_adult_evolutions()
	_test_status_and_work()
	_test_save_round_trip()
	_test_legacy_save_migration()
	_test_economy()
	_test_collection()
	await _test_scene_smoke()
	_cleanup_user_data()
	print("=== result: %d checks / %d failures ===" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)


func _test_cursor_assets() -> void:
	var cursor_paths := [
		"res://assets/ui/cursor_piyoko_normal.png",
		"res://assets/ui/cursor_piyoko_hover.png",
	]
	for cursor_path in cursor_paths:
		_expect(ResourceLoader.exists(cursor_path), "カーソル画像あり: " + cursor_path)
		var cursor_texture := load(cursor_path) as Texture2D
		_expect(cursor_texture != null, "カーソル画像読込成功: " + cursor_path)
		if cursor_texture != null:
			_expect(cursor_texture.get_size() == Vector2(64, 64), "カーソル画像は64px: " + cursor_path)
	_expect(get_root().has_node("PiyokoCursorManager"), "カーソル管理が自動読込済み")


func _test_exported_effect_textures() -> void:
	var food_effect = load("res://scripts/game/food_effect.gd").new()
	var cake_path := str(PiyokoFoodCatalog.get_food("shortcake").get("image", ""))
	_expect(food_effect.call("_load_food_texture", cake_path) is Texture2D, "DL版で食べ物画像を読込可能")
	food_effect.free()

	var pet_effect = load("res://scripts/game/pet_effect.gd").new()
	_expect(pet_effect.call("_load_hand_texture") is Texture2D, "DL版でなでる手画像を読込可能")
	pet_effect.free()

	var reaction_effect = load("res://scripts/game/reaction_effect.gd").new()
	_expect(reaction_effect.call("_load_texture", "res://assets/effects/happy_heart.png") is Texture2D, "DL版でリアクション画像を読込可能")
	reaction_effect.free()


func _test_definition_catalog() -> void:
	_expect(PiyokoDefinitionCatalog.validate(), "ピヨコ定義が妥当")
	var forms := PiyokoDefinitionCatalog.get_forms()
	_expect(forms.size() == 21, "図鑑対象が21形態")
	_expect(PiyokoDefinitionCatalog.get_stage_forms("chibi").size() == 1, "ちび1形態")
	_expect(PiyokoDefinitionCatalog.get_stage_forms("child").size() == 5, "子5形態")
	_expect(PiyokoDefinitionCatalog.get_stage_forms("adult").size() == 15, "大人15形態")

	var ids := {}
	var visual_keys := {}
	for form in forms:
		var form_id := str(form.get("id", ""))
		_expect(not ids.has(form_id), "図鑑ID重複なし: " + form_id)
		ids[form_id] = true
		var texture_path := str(form.get("texture", ""))
		_expect(ResourceLoader.exists(texture_path), "画像ファイルあり: " + form_id)
		_expect(PiyokoDefinitionCatalog.get_texture(form_id) != null, "画像読込成功: " + form_id)
		for reaction_name in ["happy", "sad", "eat"]:
			var reaction_path := str(form.get("reaction_%s" % reaction_name, ""))
			if not reaction_path.is_empty():
				_expect(ResourceLoader.exists(reaction_path), "表情差分あり: %s/%s" % [form_id, reaction_name])
				_expect(PiyokoDefinitionCatalog.get_reaction_texture(form_id, reaction_name) != null, "表情差分読込成功: %s/%s" % [form_id, reaction_name])
		var region_key := JSON.stringify(form.get("region", []))
		var visual_key := texture_path + "|" + region_key
		_expect(not visual_keys.has(visual_key), "全身画像・切出し領域が固有: " + form_id)
		visual_keys[visual_key] = form_id


func _test_item_catalog() -> void:
	_expect(PiyokoItemCatalog.validate(), "ショップ定義が妥当")
	var ids := PiyokoItemCatalog.get_ordered_ids()
	_expect(ids.size() == 11, "ショップ商品が11種類")
	for item_id in ids:
		var item := PiyokoItemCatalog.get_item(item_id)
		_expect(not item.is_empty(), "商品を取得可能: " + item_id)
		_expect(int(item.get("price", -1)) >= 0, "商品価格が妥当: " + item_id)
		_expect(ResourceLoader.exists(str(item.get("icon", ""))), "商品アイコンあり: " + item_id)
	var memory_detail_script = load("res://scripts/memory_detail.gd")
	_expect(memory_detail_script.should_show_item_use_count("full_cookie"), "通常アイテムはおもいでに使用回数を表示")
	_expect(not memory_detail_script.should_show_item_use_count("pc_parts"), "進化アイテムはおもいでの使用回数表示から除外")


func _test_food_catalog() -> void:
	_expect(PiyokoFoodCatalog.validate(), "食べ物定義が妥当")
	var ids := PiyokoFoodCatalog.get_ordered_ids()
	_expect(ids.size() == 3, "食べ物が3種類")
	for food_id in ids:
		var food := PiyokoFoodCatalog.get_food(food_id)
		_expect(not food.is_empty(), "食べ物を取得可能: " + food_id)
		_expect(ResourceLoader.exists(str(food.get("image", ""))), "食べ物画像あり: " + food_id)
	var piyoko := Piyoko.new()
	piyoko.feed("shortcake")
	_expect(piyoko.hunger == 7 and piyoko.friendship == 6 and piyoko.mood == 7, "JSONのケーキ効果を反映")
	_expect(piyoko.shortcake_count == 1, "JSONのケーキ回数項目を反映")


func _test_child_evolutions() -> void:
	var food := Piyoko.new()
	for i in 5:
		food.feed("shortcake")
	_expect(food.check_growth() and food.child_type == "food", "ごはん最多→ごはんぴよこ")

	var play := Piyoko.new()
	for i in 5:
		play.play(true)
	_expect(play.check_growth() and play.child_type == "play", "あそぶ最多→やんちゃぴよこ")

	var pet := Piyoko.new()
	for i in 5:
		pet.pet()
	_expect(pet.check_growth() and pet.child_type == "pet", "なでる最多→あまえぴよこ")

	var work := Piyoko.new()
	for i in 5:
		_expect(work.work(), "ちび期のおてつだい実行 %d" % (i + 1))
	_expect(work.check_growth() and work.child_type == "work", "おてつだい最多→おてつだいぴよこ")

	var balance := Piyoko.new()
	balance.feed("onigiri")
	balance.play(true)
	balance.pet()
	balance.work()
	balance.feed("onigiri")
	_expect(balance.check_growth() and balance.child_type == "balance", "2・1・1・1→へいきんぴよこ")


func _adult_case(lineage: String, expected: String, values: Dictionary, label: String) -> void:
	var piyoko := Piyoko.new()
	piyoko.growth_stage = 1
	piyoko.child_type = lineage
	for key in values:
		piyoko.set(str(key), values[key])
	var actual := PiyokoEvolutionEvaluator.determine_adult_type(lineage, piyoko)
	_expect(actual == expected, "%s (%s)" % [label, actual])


func _test_all_adult_evolutions() -> void:
	_adult_case("food", "sweets", {
		"adult_shortcake_count": 5, "adult_onigiri_count": 1, "adult_broccoli_count": 1
	}, "すいーつぴよこ")
	_adult_case("food", "gourmet", {
		"adult_shortcake_count": 2, "adult_onigiri_count": 2, "adult_broccoli_count": 1
	}, "ぐるめぴよこ")
	_adult_case("food", "unpiyo", {
		"full_hunger_feed_count": 5, "adult_shortcake_count": 9
	}, "うんぴよ")

	_adult_case("play", "champion", {
		"adult_play_success_count": 5, "adult_play_failure_count": 1
	}, "ちゃんぷぴよこ")
	_adult_case("play", "challenger", {
		"adult_play_success_count": 1, "adult_play_failure_count": 2
	}, "ふぁいとぴよこ")
	_adult_case("play", "umakowa", {
		"horse_ticket_used": true, "play_streak_achieved": true
	}, "うまこわぴよこ")

	_adult_case("work", "shop", {
		"pc_parts_used": false, "mood": 5, "child_shop_purchase_count": 3
	}, "3個購入→おみせぴよこ")
	_adult_case("work", "break", {
		"pc_parts_used": false, "mood": 8, "child_shop_purchase_count": 0
	}, "3個未満・きげん8→きゅうけいぴよこ")
	_adult_case("work", "shop", {
		"pc_parts_used": false, "mood": 8, "child_shop_purchase_count": 3
	}, "3個購入をきゅうけいより優先→おみせぴよこ")
	_adult_case("work", "shop", {
		"pc_parts_used": false, "mood": 5, "child_shop_purchase_count": 0
	}, "全条件未達→おみせぴよこ")
	PiyokoEconomyManager.save_data({"coins": 100, "inventory": {}, "unlocks": {}})
	_adult_case("work", "dasa", {
		"pc_parts_used": true, "mood": 8, "child_shop_purchase_count": 3
	}, "PC＋100Cを最優先→ださぴよこ")
	PiyokoEconomyManager.save_data(PiyokoEconomyManager.default_data())

	_adult_case("pet", "love", {
		"flower_item_used": false, "mood": 8
	}, "らぶぴよこ")
	_adult_case("pet", "nap", {
		"flower_item_used": false, "mood": 7
	}, "おひるねぴよこ")
	_adult_case("pet", "hana", {
		"flower_item_used": true, "mood": 8
	}, "はなぴよこ")

	_adult_case("balance", "rainbow", {
		"rainbow_item_used": false, "moon_fragment_used": false
	}, "にじいろぴよこ")
	_adult_case("balance", "oshimotif", {
		"rainbow_item_used": true
	}, "みこぴよこ")
	_adult_case("balance", "haru", {
		"rainbow_item_used": false, "moon_fragment_used": true, "friendship": 10
	}, "はるぴよこ")


func _test_status_and_work() -> void:
	var piyoko := Piyoko.new()
	piyoko.hunger = 10
	piyoko.friendship = 10
	piyoko.mood = 10
	piyoko.feed("shortcake")
	_expect(piyoko.hunger == 10 and piyoko.friendship == 10 and piyoko.mood == 10, "ステータス上限10")
	piyoko.hunger = 0
	piyoko.friendship = 0
	piyoko.mood = 0
	piyoko.feed("broccoli")
	_expect(piyoko.friendship == 0 and piyoko.mood == 0, "ステータス下限0")
	_expect(not piyoko.work(), "おなか0・きげん0では仕事不可")


func _test_save_round_trip() -> void:
	PiyokoSaveManager.delete_save()
	var original := Piyoko.new()
	original.growth_stage = 1
	original.growth_count = 9
	original.child_type = "play"
	original.hunger = 7
	original.friendship = 9
	original.mood = 8
	original.earned_coins = 120
	original.child_shop_purchase_count = 3
	original.horse_ticket_used = true
	original.pc_parts_used = true
	original.play_streak_achieved = true
	original.item_use_counts = {"horse_ticket": 1}
	_expect(PiyokoSaveManager.save(original), "育成データ保存")

	var restored := Piyoko.new()
	_expect(PiyokoSaveManager.load_save(restored), "育成データ読込")
	_expect(restored.growth_stage == 1 and restored.growth_count == 9, "成長段階・回数を復元")
	_expect(restored.child_type == "play", "子系統を復元")
	_expect(restored.hunger == 7 and restored.friendship == 9 and restored.mood == 8, "全ステータスを復元")
	_expect(restored.earned_coins == 120 and restored.child_shop_purchase_count == 3, "仕事・購入履歴を復元")
	_expect(restored.horse_ticket_used and restored.pc_parts_used and restored.play_streak_achieved, "特殊進化条件を復元")
	_expect(int(restored.item_use_counts.get("horse_ticket", 0)) == 1, "アイテム使用数を復元")


func _test_legacy_save_migration() -> void:
	var file := FileAccess.open(PiyokoSaveManager.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"save_version": 3,
		"growth_stage": 2,
		"adult_type": "yankee",
		"hunger": 3,
		"friendship": 4,
		"mood": 5
	}))
	file.close()
	var restored := Piyoko.new()
	_expect(PiyokoSaveManager.load_save(restored), "旧セーブ読込")
	_expect(restored.adult_type == "hana", "旧やんきーをはなぴよこへ移行")
	_expect(restored.hunger == 6 and restored.friendship == 8 and restored.mood == 10, "旧0～5値を0～10へ一度だけ移行")


func _test_economy() -> void:
	PiyokoEconomyManager.delete_all()
	var initial := PiyokoEconomyManager.load_data()
	_expect(int(initial.get("coins", -1)) == 50, "初期所持金50C")
	_expect(PiyokoEconomyManager.add_coins(100) == 100, "仕事報酬を加算")
	_expect(PiyokoEconomyManager.buy("full_cookie"), "商品購入")
	_expect(PiyokoEconomyManager.get_count("full_cookie") == 1, "購入品を所持")
	_expect(PiyokoEconomyManager.consume("full_cookie"), "購入品を使用")
	_expect(PiyokoEconomyManager.get_count("full_cookie") == 0, "使用後に所持数減少")
	_expect(not PiyokoEconomyManager.buy("missing_item"), "未定義商品を購入不可")


func _test_collection() -> void:
	var collection_manager := root.get_node("/root/PiyokoCollectionManager")
	collection_manager.delete_collection()
	for form in PiyokoDefinitionCatalog.get_forms():
		collection_manager.discover(str(form.get("id", "")))
	_expect(collection_manager.discovered.size() == 21, "全21形態を図鑑登録")
	for form in PiyokoDefinitionCatalog.get_forms():
		var form_id := str(form.get("id", ""))
		_expect(collection_manager.is_discovered(form_id), "図鑑発見済み: " + form_id)
		_expect(not collection_manager.get_discovered_date(form_id).is_empty(), "図鑑発見日あり: " + form_id)


func _test_scene_smoke() -> void:
	var paths := [
		"res://scenes/main.tscn",
		"res://scenes/game.tscn",
		"res://scenes/collection.tscn",
		"res://scenes/collection_detail.tscn",
		"res://scenes/memories.tscn",
		"res://scenes/memory_detail.tscn"
	]
	for path in paths:
		var packed := load(path) as PackedScene
		_expect(packed != null, "シーン読込: " + path)
		if packed == null:
			continue
		var instance := packed.instantiate()
		_expect(instance != null, "シーン生成: " + path)
		if instance != null:
			root.add_child(instance)
			await process_frame
			if path == "res://scenes/game.tscn":
				instance.set("is_growing", true)
				instance.call("_update_work_and_shop_display")
				var work_button := instance.get("work_button") as Button
				_expect(work_button != null and work_button.disabled, "成長演出中はおしごとを再入力不可")
				var game_piyoko := instance.get("piyoko") as Piyoko
				game_piyoko.growth_stage = 2
				instance.call("_update_finish_care_button")
				var finish_button := instance.get("finish_care_button") as Button
				_expect(finish_button != null and finish_button.visible, "大人進化後に育成をおえるを表示")
			instance.queue_free()
			await process_frame


func _cleanup_user_data() -> void:
	PiyokoSaveManager.delete_save()
	PiyokoEconomyManager.delete_all()
	root.get_node("/root/PiyokoCollectionManager").delete_collection()
