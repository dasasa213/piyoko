# Android固定署名の設定

Android版を上書き更新できるようにするため、v1.1.0以降は同じリリース署名鍵を使用します。署名鍵やパスワードはGitへ追加しません。

## 1. 署名鍵を一度だけ作る

WindowsのPowerShellで、保管用フォルダへ移動して実行します。

```powershell
keytool -genkeypair -v -keystore piyoko-release.keystore -alias piyoko -keyalg RSA -keysize 2048 -validity 10000
```

keystoreと鍵には同じパスワードを設定してください。設定したパスワードと、生成された `piyoko-release.keystore` は失うと今後の上書き更新ができなくなるため、別の安全な場所にもバックアップします。

## 2. GitHub Secretsへ登録する

リポジトリの `Settings` → `Secrets and variables` → `Actions` → `New repository secret` から、次の3つを登録します。

| Secret名 | 内容 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | keystoreをBase64化した文字列 |
| `ANDROID_KEYSTORE_ALIAS` | `piyoko` |
| `ANDROID_KEYSTORE_PASSWORD` | 作成時に設定したパスワード |

PowerShellでBase64文字列を作る例：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("piyoko-release.keystore")) | Set-Clipboard
```

## 3. リリースする

mainのテスト完了後に、GitHubで `v1.1.0` タグを作成してpushします。タグと `VERSION.txt` の値が一致すると、Releaseワークフローが以下を自動生成します。

- Windows ZIP
- 固定署名済みAndroid APK
- SHA-256チェックサム
- GitHub Release

## 既存のv1.0.1について

最初に、v1.0.1を削除せずv1.1.0 APKを開いて上書き更新を試します。署名違いで失敗した端末は、v1.0.1をアンインストールしてv1.1.0を新規インストールします。この場合、旧版の端末内セーブデータは削除されます。
