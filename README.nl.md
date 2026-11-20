# HermesEnabler 2

[English](README.md) · [Nederlands](README.nl.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Alleen ondersteund op watchOS 27.0 tot en met 27.3 beta 1.

## Installatie

### macOS

Op macOS kun je de vooraf gebouwde IPA met Sideloadly installeren of de app rechtstreeks met Xcode bouwen. Bij beide methoden moet de iPhone met de beoogde Apple Watch zijn gekoppeld en moet de Watch een ondersteunde watchOS-versie gebruiken.

#### De IPA installeren

> **Bekend probleem met Sideloadly 0.72:** Volgens [issue #43](https://github.com/pookjw/HermesEnabler/issues/43) kan deze versie de ingebedde Watch-app tijdens het signeren verwijderen. Als de iPhone-app wordt geïnstalleerd maar HermesEnabler2 niet op de Watch verschijnt, gebruik dan Xcode. Deze melding betreft versie 0.72; de compatibiliteit van andere versies is niet bevestigd.

1. Download de IPA via [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Installeer [Sideloadly](https://sideloadly.io) op je Mac, sluit de iPhone met een kabel aan en selecteer het apparaat in Sideloadly.
3. Sleep de IPA naar Sideloadly en voer je Apple ID in. Schakel **Use automatic bundle ID** uit, stel een vaste Bundle Identifier in en start het signeren.
4. Open op de iPhone **Instellingen → Algemeen → VPN- en apparaatbeheer** en vertrouw je ontwikkelaarscertificaat.
5. Open op de iPhone **Instellingen → Privacy en beveiliging → Ontwikkelaarsmodus**, schakel deze in, herstart en bevestig.
6. Open op de iPhone de **Watch-app → Mijn Watch → Apps** en installeer **HermesEnabler2** op de Watch.
7. Open op de Apple Watch **Instellingen → Privacy en beveiliging → Ontwikkelaarsmodus**, schakel deze in, herstart en bevestig. Als de optie ontbreekt, installeer dan eerst de Watch-app en controleer opnieuw.
8. Open **HermesEnabler2** op je Apple Watch en volg de stappen in de app.

#### Bouwen met Xcode

Je hebt een Mac nodig met een Xcode-versie die de iOS- en watchOS-versies van je apparaten ondersteunt, en een Apple Watch die aan je iPhone is gekoppeld.

1. Download en pak de broncode uit via **Code → Download ZIP**, of kloon deze repository. Open [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) in Xcode.
2. Voeg je Apple Account toe via **Xcode → Settings → Accounts** (of **Apple Accounts**). Open onder **TARGETS** voor zowel **HermesEnabler2** als **HermesCompanion** de tab **Signing & Capabilities**, schakel **Automatically manage signing** in en selecteer voor beide je eigen team.
3. Selecteer het blauwe projecticoon en vervolgens **PROJECT → HermesEnabler2 → Build Settings → All**. Zoek naar `COMPANION_BUNDLE_IDENTIFIER` en vervang `com.example.HermesEnabler` door een eigen unieke identifier, met dezelfde waarde voor **Debug** en **Release**. Laat de bestaande Bundle Identifier-expressies van de targets ongewijzigd.
4. Sluit je iPhone aan, ontgrendel deze en accepteer eventuele vertrouwensverzoeken. Laat Xcode je Watch detecteren via **Device Hub** of **Window → Devices and Simulators**. Schakel op beide apparaten **Instellingen → Privacy en beveiliging → Ontwikkelaarsmodus** in, herstart en bevestig. Ontbreekt de instelling, laat Xcode dan eerst verbinding proberen te maken en controleer opnieuw.
5. Selecteer het scheme **HermesEnabler2** en je fysieke **Apple Watch** als uitvoerdoel en klik op **▶ Run**. Wacht tot de installatie klaar is, open **HermesEnabler2** op de Watch en volg de stappen in de app. **Build Succeeded** betekent dat het compileren is afgerond; de installatie kan nog bezig zijn.

> Als Device Hub geen verbinding met de Watch kan maken, heeft het sommige gebruikers geholpen om de gekoppelde iPhone tijdelijk uit te schakelen en opnieuw te proberen. Houd de Watch ontgrendeld met wifi en Bluetooth ingeschakeld en zet de iPhone na het verbinden weer aan. Deze workaround helpt mogelijk niet bij elke configuratie.
>
> Zie **Aandachtspunten** hieronder voor het verlopen van Personal Team-profielen en de signingbeperkingen van App Groups. Gebruik bij toekomstige updates hetzelfde Apple Account en dezelfde Bundle Identifier.

### Windows

Op Windows gebruik je [WatchBridge](https://github.com/AdminZachary/iloader-for-windows), een communitytool die de ontwikkelaarsmodus voorbereidt en een IPA met zowel de iPhone-hostapp als de Watch-app installeert. De tool is niet verbonden aan Apple of dit project.

1. Installeer **Apple Mobile Device Service** door [iTunes](https://www.apple.com/itunes/) of de app **Apple Devices** uit de Microsoft Store te installeren. WatchBridge heeft deze service nodig voor communicatie via USB en wifi. WebView2 is standaard aanwezig in Windows 11.
2. Controleer of je iPhone met de beoogde Apple Watch is gekoppeld. WatchBridge ondersteunt één gekoppelde Watch tegelijk; bij meerdere gekoppelde Watches stopt de voorbereiding in plaats van zelf een apparaat te kiezen.
3. Download `watchbridge-windows.zip` via [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest), pak het bestand uit en start `WatchBridge.exe`. Het programma is niet ondertekend, waardoor Windows SmartScreen bij de eerste start een waarschuwing kan tonen.
4. Download de IPA via [Releases](https://github.com/pookjw/HermesEnabler/releases). Gebruik de oorspronkelijke IPA met zowel de iPhone-hostapp als `Watch/*.app`; pakketten met alleen de Watch-app worden niet ondersteund.
5. Sluit de gekoppelde iPhone via USB aan en selecteer deze in WatchBridge.
6. Koppel de Watch en bevestig het vertrouwensverzoek op de Watch. Vraag de schakelaar voor **Ontwikkelaarsmodus** aan en open vervolgens op de Watch **Instellingen → Privacy en beveiliging → Ontwikkelaarsmodus**. Schakel deze in, herstart en bevestig. Ga terug naar WatchBridge en klik op **Check again**. WatchBridge schakelt de ontwikkelaarsmodus niet voor je in en herstart de Watch niet.
7. Log in met je Apple ID, selecteer de HermesEnabler2-IPA en start het signeren en installeren. WatchBridge installeert eerst de iPhone-hostapp en daarna de Watch-app.
8. Open **HermesEnabler2** op je Apple Watch en volg de stappen in de app.

> Voor het voorbereiden van de ontwikkelaarsmodus is een USB-verbinding nodig. Na een eerste koppeling via USB kunnen installaties en verlengingen via wifi plaatsvinden.

## Aandachtspunten

- Schakel in Sideloadly **Use automatic bundle ID** uit en gebruik een vaste Bundle Identifier. Gebruik bij elke update dezelfde Bundle Identifier en hetzelfde Apple ID, zodat bestaande appgegevens en de back-up behouden kunnen blijven.
- Gratis Apple Personal Team-provisioningprofielen verlopen na zeven dagen. Bouw en installeer de app daarna opnieuw met hetzelfde Apple ID en dezelfde Bundle Identifier.
- Dit project gebruikt een **App Groups**-entitlement, waarvoor een gratis Personal Team geen provisioning kan verzorgen. Mogelijk is een betaald ontwikkelaarsteam nodig; het wijzigen van de Bundle Identifier heft deze beperking niet op. Ga er niet van uit dat het verwijderen van de entitlement een volledige oplossing is: de werking van de hoofdfunctie van de app zonder deze entitlement is niet bevestigd.
- Als de iPhone-app wordt geïnstalleerd maar de Watch-app ontbreekt, zoek dan in het Sideloadly-log naar `Watch apps will be stripped from the IPA`. Dit betekent dat de ingebedde Watch-app is verwijderd; alleen de iPhone-app installeren brengt deze niet terug. Installeer de Watch-app met Xcode.
- Herstel altijd je MobileGestalt-back-up via HermesEnabler2 voordat je de app verwijdert.

## Credits

Dit project bevat code uit [Gester](https://github.com/sasobhabha/Gester).

Gebruik op eigen risico.
