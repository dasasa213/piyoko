class_name PiyokoCollectionCatalog
extends RefCounted

## 図鑑の系統図と詳細画面で共有する、全14形態の表示情報。
## 進化条件は scripts/piyoko.gd の判定と同じ内容にそろえる。

const FORMS := [
	{"id": "egg", "name": "たまご", "stage": "たまご", "texture": PiyokoTextureManager.EGG_TEXTURE,
		"description": "小さなピヨコの物語が始まる、あたたかなたまご。",
		"previous": "なし", "next": "ちびぴよこ"},
	{"id": "chibi", "name": "ちびぴよこ", "stage": "ちびぴよこ", "texture": PiyokoTextureManager.CHIBI_TEXTURE,
		"description": "たまごから生まれたばかりの、元気で小さなピヨコ。",
		"previous": "たまご", "next": "4種類の子ぴよこ"},
	{"id": "child_food", "name": "ごはんぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["food"],
		"description": "おいしいものが大好き。食事の時間をいつも楽しみにしている。",
		"previous": "ちびぴよこ", "next": "すいーつぴよこ／ぐるめぴよこ"},
	{"id": "child_play", "name": "やんちゃぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["play"],
		"description": "遊ぶことが大好きで、毎日元気いっぱいに動き回る。",
		"previous": "ちびぴよこ", "next": "ちゃんぷぴよこ／ふぁいとぴよこ"},
	{"id": "child_pet", "name": "あまえぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["pet"],
		"description": "なでてもらうのが大好きな、甘え上手のピヨコ。",
		"previous": "ちびぴよこ", "next": "らぶぴよこ／おひるねぴよこ"},
	{"id": "child_balance", "name": "へいきんぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["balance"],
		"description": "食事も遊びもふれあいも、バランスよく楽しむピヨコ。",
		"previous": "ちびぴよこ", "next": "にじいろぴよこ／みこぴよこ"},
	{"id": "adult_sweets", "name": "すいーつぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["sweets"],
		"description": "甘い幸せをたくさん知って成長した、ふんわり華やかなピヨコ。",
		"previous": "ごはんぴよこ", "next": "なし"},
	{"id": "adult_gourmet", "name": "ぐるめぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["gourmet"],
		"description": "いろいろな味を楽しみながら成長した、食通のピヨコ。",
		"previous": "ごはんぴよこ", "next": "なし"},
	{"id": "adult_champion", "name": "ちゃんぷぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["champion"],
		"description": "たくさんの成功を重ね、自信に満ちたチャンピオンになった。",
		"previous": "やんちゃぴよこ", "next": "なし"},
	{"id": "adult_challenger", "name": "ふぁいとぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["challenger"],
		"description": "失敗してもくじけず、何度でも挑戦を続ける勇敢なピヨコ。",
		"previous": "やんちゃぴよこ", "next": "なし"},
	{"id": "adult_love", "name": "らぶぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["love"],
		"description": "たくさんの愛情を受け、やさしさにあふれて成長した。",
		"previous": "あまえぴよこ", "next": "なし"},
	{"id": "adult_nap", "name": "おひるねぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["nap"],
		"description": "静かな時間とお昼寝を愛する、のんびり屋のピヨコ。",
		"previous": "あまえぴよこ", "next": "なし"},
	{"id": "adult_rainbow", "name": "にじいろぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["rainbow"],
		"description": "さまざまなお世話を受けて、色とりどりの個性が花開いた。",
		"previous": "へいきんぴよこ", "next": "なし"},
	{"id": "adult_oshimotif", "name": "みこぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["oshimotif"],
		"description": "特別なお世話のリズムから生まれた、推しモチーフのピヨコ。",
		"previous": "へいきんぴよこ", "next": "なし"},
]


static func get_form(piyoko_id: String) -> Dictionary:
	for form in FORMS:
		if str(form["id"]) == piyoko_id:
			return form
	return {}


static func get_condition(piyoko_id: String) -> String:
	match piyoko_id:
		"egg":
			return "新しく育て始める。"
		"chibi":
			return "たまごをタッチして孵化させる。"
		"child_food":
			return "ちびぴよこ期にごはんが最多。最多が同数なら、最後のお世話がごはん。"
		"child_play":
			return "ちびぴよこ期に遊ぶが最多。最多が同数なら、最後のお世話が遊ぶ。"
		"child_pet":
			return "ちびぴよこ期になでるが最多。最多が同数なら、最後のお世話がなでる。"
		"child_balance":
			return "ちびぴよこ期に3種類のお世話をほぼ同じ回数行う。"
		"adult_sweets":
			return "ごはんぴよこ期に、ショートケーキを単独で最も多く与える。"
		"adult_gourmet":
			return "ごはんぴよこ期に、ショートケーキが単独最多にならない。"
		"adult_champion":
			return "やんちゃぴよこ期に、遊びの成功回数を失敗回数より多くする。"
		"adult_challenger":
			return "やんちゃぴよこ期に、遊びの失敗回数を成功回数以上にする。"
		"adult_love":
			return "あまえぴよこ期の成長時に、きげんを4～5にする。"
		"adult_nap":
			return "あまえぴよこ期の成長時に、きげんを0～3にする。"
		"adult_rainbow":
			return "へいきんぴよこ期に、通常のお世話を続ける。"
		"adult_oshimotif":
			return "へいきんぴよこ期に「ごはん→遊ぶ成功→なでる」を連続で3周する。"
		_:
			return "条件を確認できません。"


static func get_hint(piyoko_id: String) -> String:
	match piyoko_id:
		"egg":
			return "新しい物語の始まり。"
		"chibi":
			return "たまごをやさしく見守ってみよう。"
		"child_food", "adult_sweets", "adult_gourmet":
			return "食べ物との過ごし方が成長の鍵になりそう。"
		"child_play", "adult_champion", "adult_challenger":
			return "たくさん遊んだ思い出が成長につながりそう。"
		"child_pet", "adult_love", "adult_nap":
			return "ふれあいと、きげんを大切にしてみよう。"
		"child_balance", "adult_rainbow":
			return "いろいろなお世話を偏らず試してみよう。"
		"adult_oshimotif":
			return "決まった順番のお世話に、特別な秘密がありそう。"
		_:
			return "いろいろなお世話を試してみよう。"
