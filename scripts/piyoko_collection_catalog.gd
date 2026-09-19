class_name PiyokoCollectionCatalog
extends RefCounted

## 図鑑表示向けの互換窓口。情報本体は data/piyoko_forms.json で管理する。


static func get_forms() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in PiyokoDefinitionCatalog.get_forms():
		var form := definition.duplicate(true)
		form["stage"] = _stage_display_name(str(form.get("stage", "")))
		form["texture"] = PiyokoDefinitionCatalog.get_texture(str(form.get("id", "")))
		form["previous"] = _previous_name(str(definition.get("previous_id", "")))
		form["next"] = _next_names(str(definition.get("id", "")))
		result.append(form)
	return result


static func get_form(piyoko_id: String) -> Dictionary:
	for form in get_forms():
		if str(form.get("id", "")) == piyoko_id:
			return form
	return {}


static func get_condition(piyoko_id: String) -> String:
	return str(PiyokoDefinitionCatalog.get_form(piyoko_id).get(
		"condition", "条件を確認できません。"
	))


static func get_hint(piyoko_id: String) -> String:
	return str(PiyokoDefinitionCatalog.get_form(piyoko_id).get(
		"hint", "いろいろなお世話を試してみよう。"
	))


static func _stage_display_name(stage: String) -> String:
	match stage:
		"chibi": return "ちびぴよこ"
		"child": return "子ぴよこ"
		"adult": return "大人ぴよこ"
	return stage


static func _previous_name(previous_id: String) -> String:
	if previous_id.is_empty():
		return "なし"
	return PiyokoDefinitionCatalog.get_display_name(previous_id, "なし")


static func _next_names(form_id: String) -> String:
	var names: Array[String] = []
	for form in PiyokoDefinitionCatalog.get_forms():
		if str(form.get("previous_id", "")) == form_id:
			names.append(str(form.get("name", "")))
	return "／".join(names) if not names.is_empty() else "なし"
