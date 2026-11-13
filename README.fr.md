# HermesEnabler 2

[English](README.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Compatible uniquement avec watchOS 27.0 à watchOS 27.3 beta 1.

## Installation

### macOS

Sous macOS, vous pouvez installer l’IPA déjà compilé avec Sideloadly ou compiler l’app directement avec Xcode. Dans les deux cas, l’iPhone doit être associé à l’Apple Watch cible et la Watch doit exécuter une version de watchOS prise en charge.

#### Installer l’IPA

> **Problème connu avec Sideloadly 0.72 :** l’[issue #43](https://github.com/pookjw/HermesEnabler/issues/43) indique que cette version peut supprimer l’app Watch intégrée à l’IPA lors de la signature. Si l’app iPhone est installée mais que HermesEnabler2 n’apparaît pas sur la Watch, utilisez Xcode. Ce signalement concerne la version 0.72 ; la compatibilité des autres versions n’a pas été confirmée.

1. Téléchargez l’IPA depuis [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Installez [Sideloadly](https://sideloadly.io) sur le Mac, connectez l’iPhone avec un câble et sélectionnez-le dans Sideloadly.
3. Faites glisser l’IPA dans Sideloadly et saisissez votre Apple ID. Désactivez **Use automatic bundle ID**, indiquez un Bundle Identifier fixe, puis lancez la signature.
4. Sur l’iPhone, ouvrez **Réglages → Général → VPN et gestion de l’appareil** et faites confiance à votre certificat de développeur.
5. Sur l’iPhone, ouvrez **Réglages → Confidentialité et sécurité → Mode développeur**, activez-le, redémarrez et confirmez.
6. Dans l’app **Watch** de l’iPhone, allez dans **Ma montre → Apps** et installez **HermesEnabler2** sur la Watch.
7. Sur l’Apple Watch, ouvrez **Réglages → Confidentialité et sécurité → Mode développeur**, activez-le, redémarrez et confirmez. Si l’option n’apparaît pas, installez d’abord l’app Watch puis vérifiez à nouveau.
8. Ouvrez **HermesEnabler2** sur l’Apple Watch et suivez les étapes indiquées dans l’app.

#### Compiler avec Xcode

1. Ouvrez [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) dans Xcode.
2. Sélectionnez l’Apple Watch comme destination d’exécution, puis cliquez sur **Run**.
3. Ouvrez **HermesEnabler2** sur l’Apple Watch et suivez les étapes indiquées dans l’app.

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
- Les profils de provisionnement Apple Personal Team gratuits expirent au bout de sept jours. Dans ce cas, reconstruisez et réinstallez l’app avec le même Apple ID et le même Bundle Identifier.
- Ce projet utilise la capacité **App Groups**, qu’une Personal Team gratuite ne peut pas provisionner. Une équipe de développement payante peut être nécessaire ; modifier le Bundle Identifier ne supprime pas cette limitation. Ne considérez pas la suppression de cette capacité comme une solution complète : le fonctionnement principal de l’app sans elle n’a pas été confirmé.
- Si l’app iPhone est installée mais que l’app Watch n’apparaît pas, recherchez `Watch apps will be stripped from the IPA` dans le journal Sideloadly. Cela signifie que l’app Watch intégrée a été supprimée ; installez-la avec Xcode.
- Avant de supprimer l’app, restaurez impérativement votre sauvegarde MobileGestalt depuis l’app HermesEnabler2.

## Crédits

Ce projet intègre du code de [Gester](https://github.com/sasobhabha/Gester).

Utilisez ce projet à vos propres risques.
