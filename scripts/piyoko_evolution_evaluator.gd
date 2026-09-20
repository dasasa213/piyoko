class_name PiyokoEvolutionEvaluator
extends RefCounted


static func determine_adult_type(lineage: String, piyoko: Piyoko) -> String:
	var candidates := PiyokoDefinitionCatalog.get_adults_for_lineage(lineage)
	var fallback_type := ""
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int((a.get("evolution", {}) as Dictionary).get("priority", 0)) > int((b.get("evolution", {}) as Dictionary).get("priority", 0))
	)
	for form in candidates:
		var evolution: Dictionary = form.get("evolution", {})
		if bool(evolution.get("fallback", false)):
			fallback_type = str(form.get("type", ""))
		if _matches_all(evolution.get("conditions", []), piyoko):
			return str(form.get("type", ""))
	if not fallback_type.is_empty():
		return fallback_type
	return "rainbow"


static func _matches_all(conditions: Array, piyoko: Piyoko) -> bool:
	for condition in conditions:
		if not _matches(condition as Dictionary, piyoko):
			return false
	return true


static func _matches(condition: Dictionary, piyoko: Piyoko) -> bool:
	match str(condition.get("type", "")):
		"default":
			return true
		"field_min":
			return int(piyoko.get(str(condition.get("field", "")))) >= int(condition.get("value", 0))
		"field_true":
			return bool(piyoko.get(str(condition.get("field", ""))))
		"economy_coin_min":
			var economy := PiyokoEconomyManager.load_data()
			return int(economy.get("coins", 0)) >= int(condition.get("value", 0))
		"field_compare":
			var left := int(piyoko.get(str(condition.get("left", ""))))
			var right := int(piyoko.get(str(condition.get("right", ""))))
			match str(condition.get("operator", "")):
				">": return left > right
				">=": return left >= right
				"<": return left < right
				"<=": return left <= right
				"==": return left == right
		"strict_max":
			var value := int(piyoko.get(str(condition.get("field", ""))))
			for other_field in condition.get("others", []):
				if value <= int(piyoko.get(str(other_field))):
					return false
			return true
	return false
