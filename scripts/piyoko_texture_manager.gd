class_name PiyokoTextureManager
extends RefCounted


# ========================================
# たまご
# ========================================

const EGG_TEXTURE := preload(
	"res://assets/characters/piyoko/00_egg.png"
)


# ========================================
# ちびぴよこ
# ========================================

const CHIBI_TEXTURE := preload(
	"res://assets/characters/piyoko/01_chibi_piyoko.png"
)


# ========================================
# 子ぴよこ
# ========================================

const CHILD_TEXTURES := {
	"food": preload(
		"res://assets/characters/piyoko/02_child_food.png"
	),

	"play": preload(
		"res://assets/characters/piyoko/03_child_play.png"
	),

	"pet": preload(
		"res://assets/characters/piyoko/04_child_pet.png"
	),

	"balance": preload(
		"res://assets/characters/piyoko/05_child_balance.png"
	)
}


# ========================================
# 大人ぴよこ
# ========================================

const ADULT_TEXTURES := {
	"sweets": preload(
		"res://assets/characters/piyoko/06_adult_sweets.png"
	),

	"gourmet": preload(
		"res://assets/characters/piyoko/07_adult_gourmet.png"
	),

	"champion": preload(
		"res://assets/characters/piyoko/08_adult_champion.png"
	),

	"challenger": preload(
		"res://assets/characters/piyoko/09_adult_challenger.png"
	),

	"love": preload(
		"res://assets/characters/piyoko/10_adult_love.png"
	),

	"nap": preload(
		"res://assets/characters/piyoko/11_adult_nap.png"
	),

	"rainbow": preload(
		"res://assets/characters/piyoko/12_adult_rainbow.png"
	),

	"oshimotif": preload(
		"res://assets/characters/piyoko/13_adult_oshimotif.png"
	)
}


# ========================================
# 特殊・予備
# ========================================

const EXTRA_TEXTURES := {
	"pooppiyo": preload(
		"res://assets/characters/piyoko/14_extra_pooppiyo.png"
	)
}


static func get_texture(
	growth_stage: int,
	child_type: String,
	adult_type: String
) -> Texture2D:

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
