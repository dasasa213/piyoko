# ピヨコ・ショップ定義の追加方法

ピヨコとショップ商品は、画面や判定スクリプトへ個別に追記せず、次のJSONを編集します。

- `piyoko_forms.json`: 形態、表示、画像、進化条件
- `shop_items.json`: 商品、価格、効果、使用可能な成長段階

ゲーム起動時にID重複、画像パス、未対応の条件・効果を検査します。不正な定義はGodotの「出力」にエラーとして表示されます。

## ピヨコを追加する

`piyoko_forms.json` の `forms` に1件追加します。

```json
{
  "id": "adult_example",
  "type": "example",
  "name": "れいぴよこ",
  "stage": "adult",
  "lineage": "food",
  "order": 3,
  "previous_id": "child_food",
  "texture": "res://assets/characters/piyoko/forms/17_adult_example.png",
  "description": "図鑑とおもいでに表示する紹介文。",
  "condition": "図鑑に表示する進化条件。",
  "hint": "未発見時に表示するヒント。",
  "evolution": {
    "priority": 250,
    "conditions": [
      {"type": "field_min", "field": "adult_food_count", "value": 8}
    ]
  }
}
```

`stage` は `chibi` / `child` / `adult`、`lineage` は進化元の系統です。同じ系統内で `order` の小さい順に図鑑へ並びます。`priority` の大きい進化先から判定され、通常形態は `default` を使います。

対応する進化条件:

- `default`: ほかの候補に該当しなかった場合
- `field_min`: 指定カウンターが `value` 以上
- `field_true`: 指定フラグが `true`
- `field_compare`: 2つのカウンターを `>`, `>=`, `<`, `<=`, `==` で比較
- `strict_max`: 指定カウンターが `others` の全カウンターより多い

スプライトシートを使う場合は `texture` に共通画像を指定し、`region` を `[x, y, width, height]` で追加します。通常画像なら `region` は不要です。

## ショップ商品を追加する

`shop_items.json` の `items` に1件追加します。

```json
{
  "id": "example_item",
  "name": "れいのクッキー",
  "category": "care",
  "price": 30,
  "effect_text": "おなか +1 / きげん +1",
  "effects": [
    {"type": "status_change", "status": "hunger", "value": 1},
    {"type": "status_change", "status": "mood", "value": 1}
  ],
  "use_stages": ["chibi", "child", "adult"],
  "consumable": true
}
```

進化アイテムは `special_flag` と `allowed_lineages` を設定します。フラグは現在の `Piyoko` が保持するプロパティ名を指定してください。新しい種類の効果や新しい進化判定方式を増やす場合だけ、対応するカタログ／評価クラスへの実装追加が必要です。

## 追加後の確認

1. Godotを再起動し、出力に定義エラーがないことを確認する。
2. 図鑑の総数、カード、矢印、詳細画面を確認する。
3. 該当条件で進化し、通常進化の優先順位が変わっていないことを確認する。
4. 商品の購入、所持数、使用可能段階、効果、セーブ／ロードを確認する。
5. 育成終了後のおもいで一覧・詳細で名称と画像を確認する。
