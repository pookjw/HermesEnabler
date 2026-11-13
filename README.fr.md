# HermesEnabler 2

[English](README.md) · [Nederlands](README.nl.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Compatible uniquement avec watchOS 27.0 à watchOS 27.3 beta 1.

## Installation

### macOS

Sous macOS, vous pouvez installer l’IPA déjà compilé avec Sideloadly ou compiler l’app directement avec Xcode. Dans les deux cas, l’iPhone doit être associé à l’Apple Watch cible et la Watch doit exécuter une version de watchOS prise en charge.

#### Installer l’IPA

1. Téléchargez l’IPA depuis [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Installez [Sideloadly](https://sideloadly.io) sur le Mac, connectez l’iPhone avec un câble et sélectionnez-le dans Sideloadly.
3. Faites glisser l’IPA dans Sideloadly et saisissez votre Apple ID. Désactivez **Use automatic bundle ID**, indiquez un Bundle Identifier fixe, puis lancez la signature.
4. Sur l’iPhone, ouvrez **Réglages → Général → VPN et gestion de l’appareil** et faites confiance à votre certificat de développeur.
5. Sur l’iPhone, ouvrez **Réglages → Confidentialité et sécurité → Mode développeur**, activez-le, redémarrez et confirmez.
6. Dans l’app **Watch** de l’iPhone, allez dans **Ma montre → Apps** et installez **HermesEnabler2** sur la Watch.
7. Sur l’Apple Watch, ouvrez **Réglages → Confidentialité et sécurité → Mode développeur**, activez-le, redémarrez et confirmez. Si l’option n’apparaît pas, installez d’abord l’app Watch puis vérifiez à nouveau.
8. Ouvrez **HermesEnabler2** sur l’Apple Watch et suivez les étapes indiquées dans l’app.

#### Compiler avec Xcode

Vous avez besoin d’un Mac avec une version de Xcode compatible avec les versions d’iOS et de watchOS de vos appareils, et d’une Apple Watch associée à votre iPhone.

1. Téléchargez et extrayez le code source via **Code → Download ZIP**, ou clonez ce dépôt. Ouvrez [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) dans Xcode.
2. Ajoutez votre compte Apple dans **Xcode → Settings → Accounts** (ou **Apple Accounts**). Sous **TARGETS**, ouvrez **Signing & Capabilities** pour **HermesEnabler2** et **HermesCompanion**, activez **Automatically manage signing** et sélectionnez votre propre équipe pour les deux.
3. Sélectionnez l’icône bleue du projet, puis **PROJECT → HermesEnabler2 → Build Settings → All**. Recherchez `COMPANION_BUNDLE_IDENTIFIER` et remplacez `com.example.HermesEnabler` par un identifiant unique de votre choix, identique pour **Debug** et **Release**. Conservez les expressions de Bundle Identifier existantes des targets.
4. Connectez et déverrouillez l’iPhone, acceptez les invites de confiance et laissez Xcode détecter la Watch via **Device Hub** ou **Window → Devices and Simulators**. Sur les deux appareils, activez **Réglages → Confidentialité et sécurité → Mode développeur**, redémarrez et confirmez. Si l’option manque, laissez d’abord Xcode tenter une connexion, puis vérifiez à nouveau.
5. Sélectionnez le schéma **HermesEnabler2** et votre **Apple Watch physique** comme destination d’exécution, puis cliquez sur **▶ Run**. Attendez la fin de l’installation, ouvrez **HermesEnabler2** sur la Watch et suivez les étapes de l’app. **Build Succeeded** signifie que la compilation est terminée ; l’installation peut encore être en cours.

> Si Device Hub ne peut pas se connecter à la Watch, certains utilisateurs ont pu résoudre le problème en éteignant temporairement l’iPhone associé avant de réessayer. Gardez la Watch déverrouillée, avec le Wi-Fi et le Bluetooth activés, et rallumez l’iPhone après la connexion. Cette solution peut ne pas fonctionner dans toutes les configurations.
>
> Consultez **Précautions** ci-dessous pour l’expiration des profils Personal Team et les limites de signature App Groups. Conservez le même compte Apple et le même Bundle Identifier pour les mises à jour.

### Windows

Sous Windows, utilisez [WatchBridge](https://github.com/AdminZachary/iloader-for-windows), un outil communautaire qui prépare le mode développeur et installe un IPA contenant à la fois l’app hôte iPhone et l’app Watch. Il n’est affilié ni à Apple ni à ce projet.

1. Installez **Apple Mobile Device Service** en installant [iTunes](https://www.apple.com/itunes/) ou l’app **Apple Devices** du Microsoft Store. WatchBridge en a besoin pour la communication USB et Wi-Fi. WebView2 est inclus dans Windows 11.
2. Vérifiez que l’iPhone est associé à l’Apple Watch cible. WatchBridge ne prend en charge qu’une seule Watch associée à la fois ; si plusieurs le sont, l’étape de préparation s’arrête au lieu de deviner.
3. Téléchargez `watchbridge-windows.zip` depuis [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest), extrayez-le et lancez `WatchBridge.exe`. L’exécutable n’est pas signé ; Windows SmartScreen peut afficher un avertissement au premier lancement.
4. Téléchargez l’IPA depuis [Releases](https://github.com/pookjw/HermesEnabler/releases). Utilisez l’IPA d’origine contenant à la fois l’app hôte iPhone et `Watch/*.app` ; les paquets Watch uniquement ne sont pas pris en charge.
5. Connectez l’iPhone associé en USB et sélectionnez-le dans WatchBridge.
6. Associez la Watch et confirmez l’invite de confiance sur la Watch. Demandez l’interrupteur **Mode développeur**, puis sur la Watch ouvrez **Réglages → Confidentialité et sécurité → Mode développeur**, activez-le, redémarrez et confirmez. Revenez à WatchBridge et cliquez sur **Check again**. WatchBridge n’active pas le mode développeur et ne redémarre pas la Watch à votre place.
7. Connectez-vous avec votre Apple ID, sélectionnez l’IPA HermesEnabler2, puis lancez la signature et l’installation. WatchBridge installe d’abord l’app hôte iPhone, puis l’app Watch.
8. Ouvrez **HermesEnabler2** sur l’Apple Watch et suivez les étapes indiquées dans l’app.

> La préparation du mode développeur nécessite une connexion USB. Après un premier appairage en USB, les installations et renouvellements peuvent se faire en Wi-Fi.

## Précautions

- Dans Sideloadly, désactivez **Use automatic bundle ID** et utilisez un Bundle Identifier fixe. Utilisez le même Bundle Identifier et le même Apple ID à chaque mise à jour pour conserver les données et la sauvegarde existantes.
- Un compte Apple Developer payant est requis en raison de la capacité **App Groups**.
- Si l’app iPhone est installée mais que l’app Watch n’apparaît pas, recherchez `Watch apps will be stripped from the IPA` dans le journal Sideloadly. Cela signifie que l’app Watch intégrée a été supprimée ; installez-la avec Xcode.
- Avant de supprimer l’app, restaurez impérativement votre sauvegarde MobileGestalt depuis l’app HermesEnabler2.

## Crédits

Ce projet intègre du code de [Gester](https://github.com/sasobhabha/Gester).

Utilisez ce projet à vos propres risques.
