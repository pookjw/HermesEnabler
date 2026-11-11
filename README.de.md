# HermesEnabler 2
[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnabler ist eine Apple-Watch-App, die von MobileGestalt gemeldete Gerätefunktionen und Eigenschaften ändert. Die iPhone-Begleit-App hilft bei der Installation der Watch-App. Funktionskennzeichen ergänzen weder fehlende Hardware noch einen fehlenden Anspruch auf Dienste.

> Nur mit watchOS 27.0 bis watchOS 27.3 Beta 1 kompatibel.

![Apple Watch](image.png)

## Mit Xcode erstellen und installieren

1. Installiere Xcode mit iOS- und watchOS-SDK. Verbinde das mit der Apple Watch gekoppelte iPhone, bestätige das Vertrauen und aktiviere den Entwicklermodus, falls Xcode dazu auffordert.
2. Klone das Repository und öffne [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) in Xcode.
3. Wähle unter **Signing & Capabilities** dein Apple-Development-Team für **HermesCompanion** und **HermesEnabler2**. Setze `COMPANION_BUNDLE_IDENTIFIER` auf eine eindeutige iPhone-Bundle-ID, die dir gehört. Die Watch-ID erhält den Zusatz `.watchkitapp`.
4. Konfiguriere eine übereinstimmende App Group für Targets und Provisioning-Profile. Das Watch-Entitlement verwendet `group.$(COMPANION_BUNDLE_IDENTIFIER)`; ohne App Group können MobileGestalt-Zugriff und Backups scheitern.
5. Wähle das Scheme **HermesCompanion** und das gekoppelte iPhone aus und starte **Product → Run**. Falls nötig, installiere die Watch-App über **Meine Watch → Apps / Verfügbare Apps** in der iPhone-Watch-App.
6. Öffne HermesEnabler auf der Apple Watch und erstelle zuerst das anfängliche MobileGestalt-Backup. Bewahre vor weiteren Änderungen ein funktionsfähiges Backup auf.

Nur die Kompilierung ohne Signatur prüfen:

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh` erstellt eine **unsignierte** iPhone-IPA mit eingebetteter Watch-App. Vor der Installation müssen beide Apps mit geeigneten Zertifikaten und Profilen signiert werden.

## Release-IPA installieren

Lade die IPA unter [Releases](https://github.com/pookjw/HermesEnabler/releases) herunter und installiere sie passend zu deiner Signaturkonfiguration. Installiere die Watch-App bei Bedarf über die iPhone-Watch-App.

## Funktionen

| Element | Menü | Wirkung und Grenzen |
|---|---|---|
| Hermès | Zifferblätter | Ändert die gemeldete Funktion „Hermès“. |
| Ultra-Zifferblätter | Zifferblätter | Schaltet Ultra-Zifferblätter um. Dadurch wird das Hermès-Faubourg-Party-Zifferblatt unbenutzbar. Starte die Watch neu. |
| Immer eingeschaltet | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Immer eingeschaltet“. |
| Immer eingeschaltet mit 1 Hz | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Immer eingeschaltet mit 1 Hz“. |
| Farbintensität bei „Immer eingeschaltet“ | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Farbintensität bei „Immer eingeschaltet““. |
| Regelmäßige Umgebungslichtaktualisierung | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Regelmäßige Umgebungslichtaktualisierung“. |
| Bildschirmauflösung | Anzeige und Bedienelemente | Wählt die gemeldete Displaygröße oder stellt sie wieder her; physische Pixel bleiben gleich, Inhalte können abgeschnitten werden. Starte die Watch neu. |
| Aktionstaste | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Aktionstaste“. |
| Doppeltipp | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Doppeltipp“. |
| Bildschirmtastatur | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Bildschirmtastatur“. |
| Beim Anheben aktivieren | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Beim Anheben aktivieren“. |
| Zum Sprechen anheben | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Zum Sprechen anheben“. |
| Siri-Hörfunktion | Anzeige und Bedienelemente | Ändert die gemeldete Funktion „Siri-Hörfunktion“. |
| Tiefensensor | Sensoren und Workouts | Ändert die gemeldete Funktion „Tiefensensor“. |
| Absoluter Höhenmesser | Sensoren und Workouts | Ändert die gemeldete Funktion „Absoluter Höhenmesser“. |
| Dauerhaft aktiver Kompass | Sensoren und Workouts | Ändert die gemeldete Funktion „Dauerhaft aktiver Kompass“. |
| Kompassorientierung | Sensoren und Workouts | Ändert die gemeldete Funktion „Kompassorientierung“. |
| Kontinuierliche Herzfrequenz | Sensoren und Workouts | Ändert die gemeldete Funktion „Kontinuierliche Herzfrequenz“. |
| Lärmbelastung | Sensoren und Workouts | Ändert die gemeldete Funktion „Lärmbelastung“. |
| Batterieinformationen | Sensoren und Workouts | Ändert die gemeldete Funktion „Batterieinformationen“. |
| Schwimmtrainings | Sensoren und Workouts | Ändert die gemeldete Funktion „Schwimmtrainings“. |
| Regionalcode | Siri & Intelligenz | Ändert nur RegionCode; das Verkaufsregionssuffix bleibt unverändert. |
| Vertriebsregion | Siri & Intelligenz | Ändert nur das Verkaufsregionssuffix; Werksinformationstools können eine Abweichung anzeigen. |
| Apple Intelligence / Siri AI | Siri & Intelligenz | Ändert die Funktion; Siri AI benötigt watchOS 27, eine unterstützte Watch und ein gekoppeltes Apple-Intelligence-iPhone. |
| Siri auf dem Gerät | Siri & Intelligenz | Ändert die gemeldete Funktion „Siri auf dem Gerät“. |
| Audio-Intelligenz | Siri & Intelligenz | Ändert die Audio-Intelligence-Funktion; laut App ist Series-12-/Ultra-4-Hardware erforderlich. |
| Erstbackup | MG-Backups | Erstellt das geschützte Erstbackup, das in der App nicht überschrieben werden kann. |
| Manuelles Backup | MG-Backups | Sichert das aktuelle MobileGestalt manuell. |
| Automatisches Backup | MG-Backups | Erstellt vor MG-Schreib- und Wiederherstellungsvorgängen automatisch ein Backup. |
| MG wiederherstellen | MG-Backups | Sichert zuerst das aktuelle MG und stellt dann ein gewähltes Backup wieder her. Starte die Watch neu. |
| Starten Sie Carousel neu | Dienstprogramme | Startet den Watch-Oberflächenprozess neu, um Änderungen zu laden. |

Funktionskennzeichen ergänzen keine fehlenden Displays, Sensoren oder Audiokomponenten und umgehen keine Dienstbeschränkungen. Region und Auflösung bieten Vorgaben; Schreibfehler werden in der App angezeigt.

## Danksagung

Dieses Projekt enthält Code aus [Gester](https://github.com/sasobhabha/Gester). Die Nutzung erfolgt auf eigene Gefahr.
