Piyoko UI素材パック v1

格納先: res://assets/ui/

icons/: 256x256 透過PNG
- action_*: ごはん・なでる・あそぶ・メニュー
- status_*: 空腹・なかよし・きげん
- nav_*: 図鑑・育成記録・設定・タイトル
- misc_*: 未発見・ロック

panels/: 文字なし透過PNG
- button_*: ボタン各状態
- panel_*: メニュー・ポップアップ・内容枠
- frame_*: カード・選択枠

GodotではアイコンのTexture FilterをNearestにしてください。
ボタンやパネルへ文字はGodot側のLabel/Buttonで重ねます。
パネルを大きく伸ばす場合はNinePatchRectを使い、Patch Marginを32前後から調整してください。
