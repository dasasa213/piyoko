class_name PiyokoTextureManager
extends RefCounted


# ========================================
# たまご
# ========================================

const EGG_TEXTURE := preload(
	"res://assets/characters/piyoko/forms/00_egg.png"
)


# ========================================
# ちびぴよこ
# ========================================

const CHIBI_TEXTURE := preload(
	"res://assets/characters/piyoko/forms/01_chibi_piyoko.png"
)

const CHIBI_REACTION_TEXTURES := {
	"happy": preload(
		"res://assets/characters/piyoko/reactions/chibi_happy.png"
	),
	"sad": preload(
		"res://assets/characters/piyoko/reactions/chibi_sad.png"
	),
	"eat": preload(
		"res://assets/characters/piyoko/reactions/chibi_eat.png"
	),
}


const CHILD_REACTION_TEXTURES := {
	"food": {
		"happy": preload("res://assets/characters/piyoko/reactions/child_food_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/child_food_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/child_food_eat.png"),
	},
	"play": {
		"happy": preload("res://assets/characters/piyoko/reactions/child_play_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/child_play_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/child_play_eat.png"),
	},
	"pet": {
		"happy": preload("res://assets/characters/piyoko/reactions/child_pet_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/child_pet_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/child_pet_eat.png"),
	},
	"balance": {
		"happy": preload("res://assets/characters/piyoko/reactions/child_balance_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/child_balance_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/child_balance_eat.png"),
	},
}



const ADULT_REACTION_TEXTURES := {
	"sweets": {
		"happy": preload("res://assets/characters/piyoko/reactions/adult_sweets_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/adult_sweets_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/adult_sweets_eat.png"),
	},
	"gourmet": {
		"happy": preload("res://assets/characters/piyoko/reactions/adult_gourmet_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/adult_gourmet_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/adult_gourmet_eat.png"),
	},
	"champion": {
		"happy": preload("res://assets/characters/piyoko/reactions/adult_champion_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/adult_champion_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/adult_champion_eat.png"),
	},
	"challenger": {
		"happy": preload("res://assets/characters/piyoko/reactions/adult_challenger_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/adult_challenger_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/adult_challenger_eat.png"),
	},
	"love": {
		"happy": preload("res://assets/characters/piyoko/reactions/adult_love_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/adult_love_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/adult_love_eat.png"),
	},
	"nap": {
		"happy": preload("res://assets/characters/piyoko/reactions/adult_nap_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/adult_nap_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/adult_nap_eat.png"),
	},
	"rainbow": {
		"happy": preload("res://assets/characters/piyoko/reactions/adult_rainbow_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/adult_rainbow_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/adult_rainbow_eat.png"),
	},
	"oshimotif": {
		"happy": preload("res://assets/characters/piyoko/reactions/adult_oshimotif_happy.png"),
		"sad": preload("res://assets/characters/piyoko/reactions/adult_oshimotif_sad.png"),
		"eat": preload("res://assets/characters/piyoko/reactions/adult_oshimotif_eat.png"),
	},
}


# ========================================
# 子ぴよこ
# ========================================

const CHILD_TEXTURES := {
	"food": preload(
		"res://assets/characters/piyoko/forms/02_child_food.png"
	),

	"play": preload(
		"res://assets/characters/piyoko/forms/03_child_play.png"
	),

	"pet": preload(
		"res://assets/characters/piyoko/forms/04_child_pet.png"
	),

	"balance": preload(
		"res://assets/characters/piyoko/forms/05_child_balance.png"
	)
}


# ========================================
# 大人ぴよこ
# ========================================

const ADULT_TEXTURES := {
	"sweets": preload(
		"res://assets/characters/piyoko/forms/06_adult_sweets.png"
	),

	"gourmet": preload(
		"res://assets/characters/piyoko/forms/07_adult_gourmet.png"
	),

	"champion": preload(
		"res://assets/characters/piyoko/forms/08_adult_champion.png"
	),

	"challenger": preload(
		"res://assets/characters/piyoko/forms/09_adult_challenger.png"
	),

	"love": preload(
		"res://assets/characters/piyoko/forms/10_adult_love.png"
	),

	"nap": preload(
		"res://assets/characters/piyoko/forms/11_adult_nap.png"
	),

	"rainbow": preload(
		"res://assets/characters/piyoko/forms/12_adult_rainbow.png"
	),

	"oshimotif": preload(
		"res://assets/characters/piyoko/forms/13_adult_oshimotif.png"
	)
}


# ========================================
# 特殊・予備
# ========================================

const EXTRA_TEXTURES := {
	"pooppiyo": preload(
		"res://assets/characters/piyoko/forms/14_extra_pooppiyo.png"
	)
}


static func get_reaction_texture(
	reaction_name: String,
	growth_stage: int,
	child_type: String = "",
	adult_type: String = ""
) -> Texture2D:
	var form_id := _form_id(growth_stage, child_type, adult_type)
	var form := PiyokoDefinitionCatalog.get_form(form_id)
	var reaction_path := str(form.get("reaction_%s" % reaction_name, ""))
	if not reaction_path.is_empty():
		return load(reaction_path) as Texture2D
	if (
		form.has("region")
		or child_type == "work"
		or adult_type in ["hana", "unpiyo", "umakowa", "haru", "suit", "shop", "break"]
	):
		return PiyokoDefinitionCatalog.get_texture(form_id)
	match growth_stage:
		0:
			return CHIBI_REACTION_TEXTURES.get(reaction_name)
		1:
			var child_reactions: Dictionary = CHILD_REACTION_TEXTURES.get(child_type, {})
			return child_reactions.get(reaction_name)
		2:
			var adult_reactions: Dictionary = ADULT_REACTION_TEXTURES.get(adult_type, {})
			return adult_reactions.get(reaction_name)
	return null


static func get_texture(
	growth_stage: int,
	child_type: String,
	adult_type: String
) -> Texture2D:

	if growth_stage >= 0:
		var definition_texture := PiyokoDefinitionCatalog.get_texture(
			_form_id(growth_stage, child_type, adult_type)
		)
		if definition_texture != null:
			return definition_texture

	match growth_stage:
		-1:
			return EGG_TEXTURE

		0:
			return CHIBI_TEXTURE

		1:
			return CHILD_TEXTURES.get(
				child_type,
				CHIBI_TEXTURE
			)

		2:
			return ADULT_TEXTURES.get(
				adult_type,
				CHIBI_TEXTURE
			)

	return CHIBI_TEXTURE


static func _form_id(growth_stage: int, child_type: String, adult_type: String) -> String:
	match growth_stage:
		0: return "chibi"
		1: return "child_" + child_type
		2: return "adult_" + adult_type
	return ""
