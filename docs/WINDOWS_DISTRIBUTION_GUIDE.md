# Windows版 配布・更新確認手順

## 配布物の作成

`main` ブランチへ反映すると、GitHub Actionsの「Build Piyoko for Windows」が実行されます。

完了後、Actionsの実行結果から `Piyoko-Windows-x64-v1.1.0` をダウンロードします。ダウンロードされるZIPには、次の配布フォルダが含まれます。

```text
Piyoko/
├─ Piyoko.exe
├─ README.txt
├─ VERSION.txt
├─ LICENSE.txt
└─ licenses/
   ├─ THIRD_PARTY_NOTICES.md
   └─ audio_sources.md
```

## 別PC・クリーン環境での確認

開発に使用していないWindows 11 x64環境で確認します。

1. ダウンロードしたZIPを展開する。
2. `Piyoko.exe` が存在することを確認する。
3. `README.txt` とライセンス資料を開けることを確認する。
4. `Piyoko.exe` を起動する。
5. タイトル画面で「最初から」を選ぶ。
6. たまごをタッチし、ピヨコが生まれることを確認する。
7. お世話を1回行い、ゲームを終了する。
8. 再起動し、「続きから」で状態が復元されることを確認する。
9. 音量変更とウィンドウ／フルスクリーン切替を確認する。
10. 図鑑・おもいで・ショップが開けることを確認する。

確認後は、使用したコミットSHA、配布バージョン、確認PC、結果を記録します。

## 更新版の作成

1. `main` の自動テストが成功していることを確認する。
2. `export_presets.cfg` の `application/file_version` と `application/product_version` を更新する。
3. Android版も更新する場合は `version/code` と `version/name` を更新する。
4. `README_DISTRIBUTION.txt` と `VERSION.txt` のバージョンを合わせる。
5. セーブ形式を変更した場合は、旧版からの移行テストを追加する。
6. Windowsビルドを実行し、別PC確認を行う。

既存のセーブデータは `%APPDATA%\Godot\app_userdata\Piyoko` に残るため、配布フォルダを差し替えても通常は引き継がれます。セーブ項目や形式を変更した場合は、互換処理と移行テストが必要です。

## リリース前チェック

- [ ] 自動テスト成功
- [ ] Windowsビルド成功
- [ ] 配布物構成が上記一覧と一致
- [ ] ZIP展開後に起動可能
- [ ] 新規育成可能
- [ ] セーブ・再起動・続きからが正常
- [ ] 図鑑・おもいで・ショップが正常
- [ ] READMEの説明が実際の画面と一致
- [ ] ライセンス資料を同梱
- [ ] バージョン番号が全ファイルで一致
