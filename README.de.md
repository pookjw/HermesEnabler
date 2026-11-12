# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Nur mit watchOS 27.0 bis watchOS 27.3 Beta 1 kompatibel.

## Installation

### IPA installieren

1. Lade die IPA-Datei unter [Releases](https://github.com/pookjw/HermesEnabler/releases) herunter.
2. Installiere sie mit [Sideloadly](https://sideloadly.io).
3. Öffne auf dem iPhone die **Watch-App → Meine Watch → Apps** und installiere **HermesEnabler2**.
4. Öffne **HermesEnabler2** auf der Apple Watch und folge den Schritten in der App.

Unter Windows kannst du auch [WatchBridge](https://github.com/AdminZachary/iloader-for-windows/tags) verwenden, um den Entwicklermodus auf deiner Apple Watch schnell zu aktivieren und die IPA-Datei zu installieren.

### Mit Xcode erstellen

1. Öffne [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) in Xcode.
2. Wähle die Apple Watch als Run-Ziel aus und klicke auf **Run**.
3. Öffne **HermesEnabler2** auf der Apple Watch und folge den Schritten in der App.

## Hinweise

- Deaktiviere in Sideloadly **Use automatic bundle ID** und verwende einen festen Bundle Identifier. Verwende bei jedem Update denselben Bundle Identifier und dieselbe Apple ID, damit vorhandene App-Daten und Backups erhalten bleiben.
- Stelle vor dem Löschen der App unbedingt dein MobileGestalt-Backup über die HermesEnabler2-App wieder her.

## Danksagung

Dieses Projekt enthält Code aus [Gester](https://github.com/sasobhabha/Gester).

Die Nutzung erfolgt auf eigene Gefahr.
