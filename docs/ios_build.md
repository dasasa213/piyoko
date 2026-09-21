# iOS版のビルド手順

## 現在生成できるもの

GitHub Actionsの `Piyoko iOS Xcode Project` から、iOS用Xcodeプロジェクト
`Piyoko-iOS-Xcode-v1.0.1` を生成します。

この成果物は署名前のXcodeプロジェクトです。WindowsやAndroidの配布ファイルのように、
そのままiPhoneへインストールすることはできません。

## 実機用IPAを作るために必要なもの

- macOS環境
- Xcode
- Apple Developerアカウント
- 10文字のApple Team ID
- `com.dasasa213.piyoko` に対応する署名証明書
- プロビジョニングプロファイル

Godotの公式仕様上、iOSへの書き出しにはmacOSとXcodeが必要です。
Team IDを取得したら、`export_presets.cfg` の
`application/app_store_team_id="XXXXXXXXXX"` を実際の値へ変更します。

## Xcodeでの実機確認

1. GitHub Actionsから `Piyoko-iOS-Xcode-v1.0.1` をダウンロードします。
2. ZIPを展開し、`Piyoko.xcodeproj` をXcodeで開きます。
3. Signing & Capabilitiesで自分のTeamを選択します。
4. 接続したiPhoneを実行先として選び、Runします。

## iOS実機で確認する項目

- 横画面でタイトル・育成画面が画面内に収まる
- ノッチおよびDynamic Islandとメニューが重ならない
- ホームインジケータと下部ボタンが重ならない
- タッチ操作、図鑑スクロール、音声、保存・復元が動作する
- Piyokoアイコンがホーム画面とタスク画面に表示される
