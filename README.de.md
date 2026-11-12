# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Nur mit watchOS 27.0 bis watchOS 27.3 Beta 1 kompatibel.

## Installation

### Mit Xcode erstellen

#### Voraussetzungen

Du benötigst:

- Einen Mac mit einer Xcode-Version, die die iOS- und watchOS-Versionen deiner Geräte unterstützt.
- Eine mit deinem iPhone gekoppelte Apple Watch.
- Einen in Xcode hinzugefügten Apple Account.
- Den Quellcode dieses Projekts. Lade ihn über **Code → Download ZIP** herunter und entpacke ihn oder klone dieses Repository.

Xcode wird hier als Installationsmethode empfohlen, da in [Issue #43](https://github.com/pookjw/HermesEnabler/issues/43) ein Problem bei der Installation der Watch-App mit Sideloadly 0.72 gemeldet wurde. Die alternative IPA-Anleitung bleibt weiter unten erhalten.

#### 1. Apple Account zu Xcode hinzufügen

1. Öffne je nach Xcode-Version **Xcode → Settings → Accounts** oder **Apple Accounts**.
2. Klicke auf **+** und melde dich mit deinem Apple Account an.
3. Ohne kostenpflichtige Mitgliedschaft im Apple Developer Program erscheint dein Account als **Dein Name (Personal Team)**.

„Team“ bezeichnet den Apple-Entwickleraccount, mit dem die App signiert wird. Du musst nicht dem Team des Projektautors beitreten.

Mit einem Personal Team lassen sich Entwicklungs-Apps installieren. Es gelten jedoch Einschränkungen, darunter ablaufende Profile und nicht unterstützte Funktionen. Siehe **Signierung: Einschränkungen und Fehlerbehebung** weiter unten.

#### 2. iPhone verbinden und Entwicklermodus aktivieren

1. Verbinde dein iPhone mit deinem Mac.
2. Entsperre es und bestätige gegebenenfalls **Diesem Computer vertrauen**.
3. Öffne die Geräteverwaltung von Xcode: **Device Hub** in neueren Versionen oder **Window → Devices and Simulators** in älteren Versionen.
4. Warte, bis Xcode dein iPhone erkennt.
5. Öffne auf dem iPhone **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus**.
6. Aktiviere den Entwicklermodus und bestätige den Neustart.
7. Entsperre das iPhone nach dem Neustart und bestätige die Aktivierung.

Fehlt die Einstellung, stelle zuerst die Verbindung mit Xcode her und prüfe die Einstellungen erneut.

#### 3. Apple Watch verbinden und Entwicklermodus aktivieren

1. Halte die Watch entsperrt und in der Nähe von Mac und iPhone.
2. Lass Xcode die Watch erkennen. Verwende bei Bedarf in Device Hub die Option zum Hinzufügen oder Koppeln eines Geräts in der Nähe.
3. Bestätige Verbindungs- oder Vertrauensabfragen auf deinen Geräten.
4. Öffne auf der Watch selbst **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus**.
5. Aktiviere den Entwicklermodus und bestätige den Neustart.
6. Entsperre die Watch nach dem Neustart und bestätige gegebenenfalls die Aktivierung.
7. Verbinde die Watch bei Bedarf erneut mit Xcode.

Die Einstellung auf der Watch erscheint möglicherweise erst, nachdem Xcode versucht hat, eine Verbindung herzustellen. Fehlt sie, stelle die erste Verbindung her und prüfe die Watch-Einstellungen erneut.

Weitere Informationen findest du in Apples [Anleitung zum Entwicklermodus](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

##### Wenn Device Hub die Watch nicht koppeln kann

Schlägt das Koppeln oder Verbinden fehl, während das gekoppelte iPhone eingeschaltet ist, versuche Folgendes:

1. Schließe zuerst die oben beschriebene iPhone-Einrichtung ab.
2. **Schalte das iPhone vorübergehend vollständig aus.**
3. Lass die Watch eingeschaltet und entsperrt; WLAN und Bluetooth müssen aktiviert bleiben.
4. Versuche erneut, die Watch in **Device Hub/Xcode** zu koppeln oder zu verbinden.
5. Bestätige Verbindungsabfragen auf der Watch.
6. Schalte das iPhone wieder ein, sobald die Watch verbunden ist.

Dieser Workaround hat Berichten zufolge bei manchen Konfigurationen geholfen. Ein eingeschaltetes iPhone ist keine bestätigte Ursache aller Kopplungsprobleme; das Verfahren behebt möglicherweise nicht jedes Verbindungsproblem.

#### 4. Signierung und eindeutigen Bundle Identifier konfigurieren

1. Öffne `HermesEnabler2.xcodeproj`.
2. Wähle das blaue Projektsymbol im Projektnavigator von Xcode.
3. Wähle unter **PROJECT** den Eintrag **HermesEnabler2**.
4. Öffne **Build Settings**, wähle **All** und suche nach:
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. Ersetze `com.example.HermesEnabler` durch einen eigenen eindeutigen Bezeichner, zum Beispiel:
   ```
   com.yourname.HermesEnabler12345
   ```
6. Verwende denselben Wert für **Debug** und **Release**.
7. Wähle unter **TARGETS** den Eintrag **HermesEnabler2** und öffne **Signing & Capabilities**.
8. Aktiviere **Automatically manage signing** und wähle dein Team.
9. Wiederhole die Signierungseinstellungen für **HermesCompanion** mit demselben Team.

Lass die vorhandenen Ausdrücke der Bundle Identifier in den Targets unverändert:

| Target | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

Die gemeinsame Einstellung hält die Bezeichner der iPhone- und Watch-App konsistent.

Meldet Xcode **Failed Registering Bundle Identifier** oder einen nicht verfügbaren Bezeichner, wähle einen unverwechselbareren `COMPANION_BUNDLE_IDENTIFIER`. Kehre zu **Signing & Capabilities** zurück und klicke auf **Try Again**, falls die Schaltfläche erscheint.

Bleibt ein App-Groups-Fehler bestehen, siehe **App-Groups-Fehler** weiter unten.

#### 5. Auf der Watch erstellen und ausführen

1. Wähle das Scheme **HermesEnabler2**.
2. Wähle deine physische **Apple Watch** als Ausführungsziel.
3. Klicke auf **▶ Run**.
4. Warte, bis Xcode das Gerät vorbereitet und die App installiert hat.
5. Sobald HermesEnabler2 auf der Watch geöffnet wird, folge den Anweisungen in der App.

**Build Succeeded** bedeutet, dass die Kompilierung erfolgreich war. Die Installation kann noch laufen.

Zeigt Xcode **Installing built products**, warte auf den Abschluss der Installation. Halte die Geräte in der Nähe und verbunden.

Eine Debugging-Sitzung kann während der Ausführung aktiv bleiben; das ist normal. Prüfe auf dem Watch-Display, ob die App geöffnet wurde.

### Alternative: IPA mit Sideloadly installieren

> **Bekanntes Problem mit Sideloadly 0.72:** Laut [Issue #43](https://github.com/pookjw/HermesEnabler/issues/43) entfernt diese Version die eingebettete watchOS-App beim Signieren. Die iPhone-App wird installiert, aber HermesEnabler2 erscheint weder auf der Apple Watch noch in der Watch-App des iPhones. Verwende in diesem Fall die obige Anleitung **Mit Xcode erstellen**.
>
> Der Bericht betrifft Version 0.72. Die Kompatibilität anderer Sideloadly-Versionen wurde hier nicht bestätigt.

1. Lade `HermesEnabler.ipa` unter [Releases](https://github.com/pookjw/HermesEnabler/releases) herunter.
2. Öffne [Sideloadly](https://sideloadly.io).
3. Deaktiviere **Use automatic bundle ID** und wähle einen festen, eindeutigen Bundle Identifier.
4. Installiere die IPA auf deinem iPhone.
5. Öffne auf dem iPhone **Watch → Meine Watch → Apps** und suche unter **Verfügbare Apps** nach **HermesEnabler2**.
6. Falls die App erscheint, installiere sie auf der Watch, öffne sie und folge ihren Anweisungen.
7. Falls sie nicht erscheint, installiere die Watch-App mit Xcode.

Verwende bei späteren Updates denselben Bundle Identifier und Apple Account, damit vorhandene Daten und Backups erhalten bleiben können.

## Signierung: Einschränkungen und Fehlerbehebung

### Ablauf von Personal-Team-Profilen

Kostenlose Personal-Team-Bereitstellungsprofile laufen nach sieben Tagen ab. Erstelle und installiere die App danach erneut mit Xcode.

Verwende für Updates weiterhin denselben Apple Account und Bundle Identifier.

### App-Groups-Fehler

Dieses Projekt enthält eine **App Groups**-Berechtigung. Ein kostenloses Personal Team unterstützt die Bereitstellung dieser Funktion nicht.

Meldet Xcode eine nicht verfügbare App Group:

- Prüfe, ob `COMPANION_BUNDLE_IDENTIFIER` auf einen eindeutigen Wert geändert wurde.
- Wähle bei einer kostenpflichtigen Entwicklermitgliedschaft das entsprechende Team und stelle sicher, dass die zugehörige App Group registriert werden kann.
- Ein anderer Bezeichner hebt die Funktionseinschränkungen eines Personal Teams nicht auf.

Das Entfernen von App Groups ist keine bestätigte vollständige Lösung. Issue #43 berichtet über eine erfolgreiche Installation mit Xcode, bestätigt aber nicht, dass der MobileGestalt-Vorgang auf watchOS 27.2.1 ohne App Groups funktioniert.

Ein erfolgreicher Build oder eine erfolgreiche Installation allein bestätigt nicht, dass die Hauptfunktion der App funktioniert.

### iPhone-App installiert, Watch-App fehlt

Suche bei Sideloadly 0.72 im Protokoll nach:

```
Watch apps will be stripped from the IPA
```

Dies bedeutet, dass die eingebettete Watch-App entfernt wurde. Die Installation der iPhone-App allein stellt die fehlende Watch-App nicht bereit. Folge der obigen Xcode-Installationsanleitung.

## Hinweise

- Verwende bei Updates denselben Bundle Identifier und Apple Account, damit vorhandene App-Daten und Backups erhalten bleiben können.
- Stelle vor dem Löschen der App unbedingt dein MobileGestalt-Backup über HermesEnabler2 wieder her.

## Danksagung

Dieses Projekt enthält Code aus [Gester](https://github.com/sasobhabha/Gester).

Die Nutzung erfolgt auf eigene Gefahr.
