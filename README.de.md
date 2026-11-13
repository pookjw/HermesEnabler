# HermesEnabler 2

[English](README.md) · [Nederlands](README.nl.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Nur mit watchOS 27.0 bis watchOS 27.3 Beta 1 kompatibel.

## Installation

### macOS

Unter macOS kannst du die fertige IPA mit Sideloadly installieren oder die App direkt mit Xcode erstellen. In beiden Fällen muss das iPhone mit der Ziel-Apple Watch gekoppelt sein und die Watch eine unterstützte watchOS-Version ausführen.

#### IPA installieren

1. Lade die IPA unter [Releases](https://github.com/pookjw/HermesEnabler/releases) herunter.
2. Installiere [Sideloadly](https://sideloadly.io) auf dem Mac, verbinde das iPhone per Kabel und wähle es in Sideloadly aus.
3. Ziehe die IPA in Sideloadly und gib deine Apple ID ein. Deaktiviere **Use automatic bundle ID**, lege einen festen Bundle Identifier fest und starte die Signierung.
4. Öffne auf dem iPhone **Einstellungen → Allgemein → VPN & Geräteverwaltung** und vertraue deinem Entwicklerzertifikat.
5. Öffne auf dem iPhone **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus**, aktiviere ihn, starte neu und bestätige.
6. Öffne auf dem iPhone die **Watch-App**, gehe zu **Meine Watch → Apps** und installiere **HermesEnabler2** auf der Watch.
7. Öffne auf der Apple Watch **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus**, aktiviere ihn, starte neu und bestätige. Wenn die Option nicht angezeigt wird, installiere zuerst die Watch-App und prüfe erneut.
8. Öffne **HermesEnabler2** auf der Apple Watch und folge den Schritten in der App.

#### Mit Xcode erstellen

Du benötigst einen Mac mit einer Xcode-Version, die die iOS- und watchOS-Versionen deiner Geräte unterstützt, sowie eine mit deinem iPhone gekoppelte Apple Watch.

1. Lade den Quellcode über **Code → Download ZIP** herunter und entpacke ihn oder klone dieses Repository. Öffne [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) in Xcode.
2. Füge deinen Apple Account unter **Xcode → Settings → Accounts** (oder **Apple Accounts**) hinzu. Öffne unter **TARGETS** für **HermesEnabler2** und **HermesCompanion** jeweils **Signing & Capabilities**, aktiviere **Automatically manage signing** und wähle für beide dein eigenes Team.
3. Wähle das blaue Projektsymbol und dann **PROJECT → HermesEnabler2 → Build Settings → All**. Suche nach `COMPANION_BUNDLE_IDENTIFIER` und ersetze `com.example.HermesEnabler` für **Debug** und **Release** durch denselben eigenen, eindeutigen Bezeichner. Lass die vorhandenen Bundle-Identifier-Ausdrücke der Targets unverändert.
4. Verbinde und entsperre dein iPhone, bestätige Vertrauensabfragen und lass Xcode die Watch über **Device Hub** oder **Window → Devices and Simulators** erkennen. Aktiviere auf beiden Geräten **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus**, starte neu und bestätige. Fehlt die Einstellung, lass Xcode zuerst eine Verbindung versuchen und prüfe erneut.
5. Wähle das Scheme **HermesEnabler2** und deine physische **Apple Watch** als Ausführungsziel, dann klicke auf **▶ Run**. Warte auf den Abschluss der Installation, öffne **HermesEnabler2** auf der Watch und folge den Schritten in der App. **Build Succeeded** bedeutet, dass die Kompilierung abgeschlossen ist; die Installation kann noch laufen.

> Wenn Device Hub keine Verbindung zur Watch herstellen kann, hat es manchen Nutzern geholfen, das gekoppelte iPhone vorübergehend auszuschalten und es erneut zu versuchen. Halte die Watch entsperrt und WLAN und Bluetooth aktiviert. Schalte das iPhone nach dem Verbinden wieder ein. Dieser Workaround hilft möglicherweise nicht bei jeder Konfiguration.
>
> Informationen zum Ablauf von Personal-Team-Profilen und zu App-Groups-Einschränkungen findest du unter **Hinweise** weiter unten. Verwende bei Updates denselben Apple Account und Bundle Identifier.

### Windows

Unter Windows verwendest du [WatchBridge](https://github.com/AdminZachary/iloader-for-windows), ein Community-Tool, das den Entwicklermodus vorbereitet und eine IPA installiert, die sowohl die iPhone-Host-App als auch die Watch-App enthält. Es steht weder mit Apple noch mit diesem Projekt in offizieller Verbindung.

1. Installiere **Apple Mobile Device Service**, indem du [iTunes](https://www.apple.com/itunes/) oder die **Apple Devices**-App aus dem Microsoft Store installierst. WatchBridge benötigt den Dienst für USB- und Wi-Fi-Kommunikation. WebView2 ist in Windows 11 enthalten.
2. Stelle sicher, dass dein iPhone mit der Ziel-Apple Watch gekoppelt ist. WatchBridge unterstützt jeweils nur eine gekoppelte Watch; sind mehrere gekoppelt, bricht der Vorbereitungsschritt ab, statt zu raten.
3. Lade `watchbridge-windows.zip` von [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest) herunter, entpacke es und starte `WatchBridge.exe`. Die ausführbare Datei ist nicht signiert, daher kann Windows SmartScreen beim ersten Start warnen.
4. Lade die IPA unter [Releases](https://github.com/pookjw/HermesEnabler/releases) herunter. Verwende die Original-IPA, die sowohl die iPhone-Host-App als auch `Watch/*.app` enthält; reine Watch-Pakete werden nicht unterstützt.
5. Verbinde das gekoppelte iPhone per USB und wähle es in WatchBridge aus.
6. Koppele die Watch und bestätige die Vertrauensabfrage auf der Watch. Fordere den Schalter **Entwicklermodus** an, öffne dann auf der Watch **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus**, aktiviere ihn, starte neu und bestätige. Kehre zu WatchBridge zurück und klicke auf **Check again**. WatchBridge aktiviert den Entwicklermodus nicht selbst und startet die Watch nicht neu.
7. Melde dich mit deiner Apple ID an, wähle die HermesEnabler2-IPA und starte Signierung und Installation. WatchBridge installiert zuerst die iPhone-Host-App und danach die Watch-App.
8. Öffne **HermesEnabler2** auf der Apple Watch und folge den Schritten in der App.

> Die Vorbereitung des Entwicklermodus erfordert eine USB-Verbindung. Nach einer einmaligen USB-Kopplung können Installation und Erneuerung über Wi-Fi erfolgen.

## Hinweise

- Deaktiviere in Sideloadly **Use automatic bundle ID** und verwende einen festen Bundle Identifier. Verwende bei jedem Update denselben Bundle Identifier und dieselbe Apple ID, damit vorhandene App-Daten und Backups erhalten bleiben.
- Aufgrund der **App Groups**-Berechtigung ist ein kostenpflichtiger Apple Developer Account erforderlich.
- Wird die iPhone-App installiert, aber die Watch-App nicht angezeigt, suche im Sideloadly-Protokoll nach `Watch apps will be stripped from the IPA`. Das bedeutet, dass die eingebettete Watch-App entfernt wurde; installiere sie mit Xcode.
- Stelle vor dem Löschen der App unbedingt dein MobileGestalt-Backup über die HermesEnabler2-App wieder her.

## Danksagung

Dieses Projekt enthält Code aus [Gester](https://github.com/sasobhabha/Gester).

Die Nutzung erfolgt auf eigene Gefahr.
