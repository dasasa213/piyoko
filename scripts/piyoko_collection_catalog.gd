class_name PiyokoCollectionCatalog
extends RefCounted

## 図鑑の系統図と詳細画面で共有する、全21形態の表示情報。
## 進化条件は scripts/piyoko.gd の判定と同じ内容にそろえる。

const FORMS := [
	{"id": "chibi", "name": "ちびぴよこ", "stage": "ちびぴよこ", "texture": PiyokoTextureManager.CHIBI_TEXTURE,
		"description": "たまごから生まれたばかりの、元気で小さなピヨコ。",
		"previous": "なし", "next": "5種類の子ぴよこ"},
	{"id": "child_food", "name": "ごはんぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["food"],
		"description": "おいしいものが大好き。食事の時間をいつも楽しみにしている。",
		"previous": "ちびぴよこ", "next": "すいーつぴよこ／ぐるめぴよこ"},
	{"id": "child_play", "name": "やんちゃぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["play"],
		"description": "遊ぶことが大好きで、毎日元気いっぱいに動き回る。",
		"previous": "ちびぴよこ", "next": "ちゃんぷぴよこ／ふぁいとぴよこ"},
	{"id": "child_pet", "name": "あまえぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["pet"],
		"description": "なでてもらうのが大好きな、甘え上手のピヨコ。",
		"previous": "ちびぴよこ", "next": "らぶぴよこ／おひるねぴよこ／はなぴよこ"},
	{"id": "child_balance", "name": "へいきんぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["balance"],
		"description": "食事も遊びもふれあいも、バランスよく楽しむピヨコ。",
		"previous": "ちびぴよこ", "next": "にじいろぴよこ／みこぴよこ／はるぴよこ"},
	{"id": "child_work", "name": "おてつだいぴよこ", "stage": "子ぴよこ", "texture": PiyokoTextureManager.CHILD_TEXTURES["work"],
		"description": "だれかの役に立つことが大好き。まだ少し不器用だけど、今日も一生懸命おてつだいしている。",
		"previous": "ちびぴよこ", "next": "すーつぴよこ／おみせぴよこ／きゅうけいぴよこ"},
	{"id": "adult_sweets", "name": "すいーつぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["sweets"],
		"description": "甘い幸せをたくさん知って成長した、ふんわり華やかなピヨコ。",
		"previous": "ごはんぴよこ", "next": "なし"},
	{"id": "adult_gourmet", "name": "ぐるめぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["gourmet"],
		"description": "いろいろな味を楽しみながら成長した、食通のピヨコ。",
		"previous": "ごはんぴよこ", "next": "なし"},
	{"id": "adult_unpiyo", "name": "うんぴよ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["unpiyo"],
		"description": "たくさん食べて、ちょっぴり不思議な姿に成長したピヨコ。見た目によらずきれい好きで、どこか憎めない人気者。",
		"previous": "ごはんぴよこ", "next": "なし"},
	{"id": "adult_champion", "name": "ちゃんぷぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["champion"],
		"description": "たくさんの成功を重ね、自信に満ちたチャンピオンになった。",
		"previous": "やんちゃぴよこ", "next": "なし"},
	{"id": "adult_challenger", "name": "ふぁいとぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["challenger"],
		"description": "失敗してもくじけず、何度でも挑戦を続ける勇敢なピヨコ。",
		"previous": "やんちゃぴよこ", "next": "なし"},
	{"id": "adult_umakowa", "name": "うまこわぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["umakowa"],
		"description": "勝負になると誰よりも熱くなる、勇ましいピヨコ。自慢の速さと負けん気で、どんな遊びにも全力で挑む。",
		"previous": "やんちゃぴよこ", "next": "なし"},
	{"id": "adult_love", "name": "らぶぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["love"],
		"description": "たくさんの愛情を受け、やさしさにあふれて成長した。",
		"previous": "あまえぴよこ", "next": "なし"},
	{"id": "adult_nap", "name": "おひるねぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["nap"],
		"description": "静かな時間とお昼寝を愛する、のんびり屋のピヨコ。",
		"previous": "あまえぴよこ", "next": "なし"},
	{"id": "adult_hana", "name": "はなぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["hana"],
		"description": "ちょっとやんちゃな世紀末ピヨコ。ぴよこ界のｵｼｬﾚ番長。",
		"previous": "あまえぴよこ", "next": "なし"},
	{"id": "adult_rainbow", "name": "にじいろぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["rainbow"],
		"description": "さまざまなお世話を受けて、色とりどりの個性が花開いた。",
		"previous": "へいきんぴよこ", "next": "なし"},
	{"id": "adult_oshimotif", "name": "みこぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["oshimotif"],
		"description": "深淵から突如現れたピヨコ。今日もみんなの幸せを作っている。",
		"previous": "へいきんぴよこ", "next": "なし"},
	{"id": "adult_haru", "name": "はるぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["haru"],
		"description": "月のかけらに導かれて成長した、穏やかなピヨコ。夜空を眺めながら、大切な人のそばを優しく照らしている。", "previous": "へいきんぴよこ", "next": "なし"},
	{"id": "adult_suit", "name": "すーつぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["suit"],
		"description": "まじめに働く、しっかり者のピヨコ。身だしなみを整え、今日も自分の仕事にこつこつ取り組んでいる。", "previous": "おてつだいぴよこ", "next": "なし"},
	{"id": "adult_shop", "name": "おみせぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["shop"],
		"description": "お客さんの笑顔がいちばんのごほうび。元気なあいさつと丁寧なおもてなしで、今日もお店をにぎやかにする。", "previous": "おてつだいぴよこ", "next": "なし"},
	{"id": "adult_break", "name": "きゅうけいぴよこ", "stage": "大人ぴよこ", "texture": PiyokoTextureManager.ADULT_TEXTURES["break"],
		"description": "がんばる時間と休む時間、どちらも大切にするピヨコ。温かい飲み物を片手に、ほっとひと息ついている。", "previous": "おてつだいぴよこ", "next": "なし"},
]


static func get_form(piyoko_id: String) -> Dictionary:
	for form in FORMS:
		if str(form["id"]) == piyoko_id:
			return form
	return {}


static func get_condition(piyoko_id: String) -> String:
	match piyoko_id:
		"chibi":
			return "たまごをタッチして孵化させる。"
		"child_food":
			return "ちびぴよこ期にごはんが最多。最多が同数なら、最後のお世話がごはん。"
		"child_play":
			return "ちびぴよこ期に遊ぶが最多。最多が同数なら、最後のお世話が遊ぶ。"
		"child_pet":
			return "ちびぴよこ期になでるが最多。最多が同数なら、最後のお世話がなでる。"
		"child_balance":
			return "ちびぴよこ期に4種類のお世話をバランスよく行う。"
		"child_work":
			return "ちびぴよこ期に、おてつだいを最も多く行う。"
		"adult_sweets":
			return "ごはんぴよこ期に、ショートケーキを単独で最も多く与える。"
		"adult_gourmet":
			return "ごはんぴよこ期に、ショートケーキが単独最多にならない。"
		"adult_unpiyo":
			return "ごはんぴよこ期に、おなか10の状態でごはんを5回与える。"
		"adult_champion":
			return "やんちゃぴよこ期に、遊びの成功回数を失敗回数より多くする。"
		"adult_challenger":
			return "やんちゃぴよこ期に、遊びの失敗回数を成功回数以上にする。"
		"adult_umakowa":
			return "やんちゃぴよこ期に馬券を使い、遊びを5回連続で成功させる。"
		"adult_love":
			return "あまえぴよこ期の成長時に、きげんを8以上にする。"
		"adult_nap":
			return "はな・らぶの条件を満たさずに成長する。"
		"adult_hana":
			return "あまえぴよこ期に「はな」を使い、成長時のきげんを8以上にする。"
		"adult_rainbow":
			return "へいきんぴよこ期に、通常のお世話を続ける。"
		"adult_oshimotif":
			return "へいきんぴよこ期に「にじ」を使う。"
		"adult_haru":
			return "へいきんぴよこ期に月のかけらを使い、なかよしを10にする。"
		"adult_shop":
			return "おてつだいぴよこ期に、商品を合計3個以上購入する。"
		"adult_break":
			return "商品を3個購入せず、成長時のきげんを8以上にする。"
		"adult_suit":
			return "おみせ・きゅうけいの条件を満たさずに成長する。"
		_:
			return "条件を確認できません。"


static func get_hint(piyoko_id: String) -> String:
	match piyoko_id:
		"chibi":
			return "たまごをやさしく見守ってみよう。"
		"child_food", "adult_sweets", "adult_gourmet", "adult_unpiyo":
			return "食べ物との過ごし方が成長の鍵になりそう。"
		"child_play", "adult_champion", "adult_challenger", "adult_umakowa":
			return "たくさん遊んだ思い出が成長につながりそう。"
		"child_pet", "adult_love", "adult_nap", "adult_hana":
			return "ふれあいと、きげんを大切にしてみよう。"
		"child_balance", "adult_rainbow", "adult_haru":
			return "いろいろなお世話を偏らず試してみよう。"
		"adult_oshimotif":
			return "特別なにじに、秘密がありそう。"
		"child_work", "adult_suit", "adult_shop", "adult_break":
			return "おてつだいとお店での過ごし方が成長の鍵になりそう。"
		_:
			return "いろいろなお世話を試してみよう。"
