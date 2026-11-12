# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> watchOS 27.0から27.3 beta 1までのみ対応しています。

## インストール方法

### Xcodeでビルド

#### 準備

以下が必要です。

- デバイスのiOSとwatchOSのバージョンに対応したXcodeを搭載するMac。
- iPhoneとペアリング済みのApple Watch。
- Xcodeに追加したApple Account。
- このプロジェクトのソースコード。**Code → Download ZIP**からダウンロードして展開するか、リポジトリをクローンしてください。

[Issue #43](https://github.com/pookjw/HermesEnabler/issues/43)でSideloadly 0.72によるWatchアプリのインストールに問題が報告されているため、ここではXcodeでのインストールを推奨します。IPAを使う代替手順も後述しています。

#### 1. Apple AccountをXcodeに追加する

1. Xcodeのバージョンに応じて、**Xcode → Settings → Accounts**または**Apple Accounts**を開きます。
2. **+**をクリックし、Apple Accountでサインインします。
3. 有料のApple Developer Programに加入していない場合、アカウントは**自分の名前 (Personal Team)**と表示されます。

「Team」はアプリの署名に使用するAppleの開発者アカウントを指します。プロジェクト作者のチームに参加する必要はありません。

Personal Teamでは開発用アプリをインストールできますが、プロファイルの有効期限や利用できない機能などの制限があります。後述の**署名の制限とトラブルシューティング**を参照してください。

#### 2. iPhoneを接続してデベロッパモードを有効にする

1. iPhoneをMacに接続します。
2. ロックを解除し、表示された場合は**このコンピュータを信頼**を承認します。
3. Xcodeのデバイス管理画面を開きます。新しいバージョンでは**Device Hub**、以前のバージョンでは**Window → Devices and Simulators**を使用します。
4. XcodeがiPhoneを認識するまで待ちます。
5. iPhoneで**設定 → プライバシーとセキュリティ → デベロッパモード**を開きます。
6. デベロッパモードを有効にし、再起動を承認します。
7. 再起動後、iPhoneのロックを解除して有効化を確認します。

設定が表示されない場合は、先にXcodeとの接続を確立してから、設定を再確認してください。

#### 3. Apple Watchを接続してデベロッパモードを有効にする

1. Watchのロックを解除し、MacとiPhoneの近くに置きます。
2. XcodeにWatchを検出させます。必要に応じて、Device Hubの近くのデバイスを追加またはペアリングするオプションを使用してください。
3. デバイスに表示される接続や信頼の確認を承認します。
4. Watch本体で**設定 → プライバシーとセキュリティ → デベロッパモード**を開きます。
5. デベロッパモードを有効にし、再起動を承認します。
6. 再起動後、Watchのロックを解除し、有効化の確認が表示された場合は承認します。
7. 必要に応じてWatchをXcodeに再接続します。

Watchのデベロッパモード設定は、Xcodeが接続を試みるまで表示されない場合があります。表示されないときは、最初の接続を行ってからWatchの設定を再確認してください。

詳しくはAppleの[デベロッパモードの手順](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)を参照してください。

##### Device HubでWatchをペアリングできない場合

ペアリング済みiPhoneの電源が入っている状態でペアリングや接続に失敗する場合は、次の回避策を試してください。

1. 先に上記のiPhoneの設定を完了します。
2. **iPhoneの電源を一時的に切ります。**
3. Watchは電源を入れてロックを解除したままにし、Wi-FiとBluetoothを有効にしておきます。
4. **Device Hub/Xcode**でWatchのペアリングまたは接続を再試行します。
5. Watchに表示される接続確認を承認します。
6. Watchが接続されたら、iPhoneの電源を入れ直します。

この回避策が一部の環境で役立ったという報告があります。ただし、iPhoneの電源が入っていることがすべてのペアリング問題の原因と確認されたわけではなく、すべての接続問題が解決するとは限りません。

#### 4. 署名と固有のBundle Identifierを設定する

1. `HermesEnabler2.xcodeproj`を開きます。
2. Xcodeのプロジェクトナビゲータで青いプロジェクトアイコンを選択します。
3. **PROJECT**の下で**HermesEnabler2**を選択します。
4. **Build Settings**を開いて**All**を選択し、次を検索します。
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. `com.example.HermesEnabler`を、自分専用の固有の識別子に変更します。例：
   ```
   com.yourname.HermesEnabler12345
   ```
6. **Debug**と**Release**に同じ値を設定します。
7. **TARGETS**の下で**HermesEnabler2**を選択し、**Signing & Capabilities**を開きます。
8. **Automatically manage signing**を有効にして自分のチームを選択します。
9. **HermesCompanion**でも署名設定を行い、同じチームを選択します。

各ターゲットの既存のBundle Identifierの式は変更しないでください。

| ターゲット | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

この共通設定により、iPhoneアプリとWatchアプリの識別子の整合性が保たれます。

Xcodeに**Failed Registering Bundle Identifier**や識別子が使用できない旨が表示された場合は、より固有性の高い`COMPANION_BUNDLE_IDENTIFIER`を指定してください。**Signing & Capabilities**に戻り、**Try Again**が表示されていればクリックします。

App Groupsのエラーが残る場合は、後述の**App Groupsのエラー**を参照してください。

#### 5. Watchでビルドして実行する

1. **HermesEnabler2**スキームを選択します。
2. 実行先に実機の**Apple Watch**を選択します。
3. **▶ Run**をクリックします。
4. Xcodeによるデバイスの準備とアプリのインストールが完了するまで待ちます。
5. WatchでHermesEnabler2が開いたら、アプリ内の手順に従います。

**Build Succeeded**はコンパイルが成功したことを示します。インストールはまだ進行中の場合があります。

**Installing built products**と表示されている場合は、インストールの完了を待ってください。デバイスを近くに置き、接続を維持します。

アプリの実行中にデバッグセッションが継続するのは正常です。Watchの画面でアプリが開いたか確認してください。

### 代替方法：SideloadlyでIPAをインストールする

> **Sideloadly 0.72の既知の問題：** [Issue #43](https://github.com/pookjw/HermesEnabler/issues/43)によると、このバージョンは署名中に埋め込みのwatchOSアプリを削除します。iPhoneアプリはインストールされますが、HermesEnabler2はApple WatchにもiPhoneのWatchアプリにも表示されません。この問題が発生した場合は、上記の**Xcodeでビルド**の手順を使用してください。
>
> この報告はバージョン0.72に関するものです。他のSideloadlyバージョンの互換性は、ここでは確認されていません。

1. [Releases](https://github.com/pookjw/HermesEnabler/releases)から`HermesEnabler.ipa`をダウンロードします。
2. [Sideloadly](https://sideloadly.io)を開きます。
3. **Use automatic bundle ID**をオフにし、固定の固有のBundle Identifierを指定します。
4. IPAをiPhoneにインストールします。
5. iPhoneで**Watch → マイウォッチ → アプリ**を開き、**利用可能なアプリ**の下で**HermesEnabler2**を探します。
6. 表示された場合はWatchにインストールし、開いてアプリ内の手順に従います。
7. 表示されない場合は、XcodeでWatchアプリをインストールします。

既存データとバックアップを引き継げるよう、以後のアップデートでも同じBundle IdentifierとApple Accountを使用してください。

## 署名の制限とトラブルシューティング

### Personal Teamの有効期限

無料Personal Teamのプロビジョニングプロファイルは7日後に期限切れになります。その際はXcodeでアプリを再ビルドして再インストールしてください。

アップデートには引き続き同じApple AccountとBundle Identifierを使用してください。

### App Groupsのエラー

このプロジェクトには**App Groups**のエンタイトルメントが含まれています。無料のPersonal Teamではこの機能のプロビジョニングがサポートされていません。

XcodeでApp Groupが使用できないと表示された場合：

- `COMPANION_BUNDLE_IDENTIFIER`を固有の値に変更したか確認します。
- 有料の開発者メンバーシップがある場合はそのチームを選択し、対応するApp Groupを登録できることを確認します。
- 識別子を変更してもPersonal Teamの機能制限は解除されません。

App Groupsの削除が完全な解決策になるとは限りません。Issue #43ではXcodeによるインストール成功が報告されていますが、watchOS 27.2.1でApp GroupsなしにMobileGestaltの操作が機能するかは確認されていません。

ビルドやインストールの成功だけでは、アプリの主要機能の動作は確認できません。

### iPhoneアプリはインストールされるがWatchアプリがない

Sideloadly 0.72を使用した場合は、ログに次の行がないか確認してください。

```
Watch apps will be stripped from the IPA
```

これは埋め込みのWatchアプリが削除されたことを示します。iPhoneアプリだけをインストールしても、欠落したWatchアプリは利用できません。上記のXcodeによるインストール手順に従ってください。

## 注意事項

- 既存のアプリデータとバックアップを引き継げるよう、アップデート時も同じBundle IdentifierとApple Accountを使用してください。
- アプリを削除する前に、必ずHermesEnabler2からMobileGestaltのバックアップを復元してください。

## クレジット

このプロジェクトには[Gester](https://github.com/sasobhabha/Gester)のコードが含まれています。

ご自身の責任でご使用ください。
