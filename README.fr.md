# HermesEnabler 2
[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnabler est une app Apple Watch qui modifie les capacités et propriétés de l’appareil signalées par MobileGestalt. L’app compagnon sur iPhone permet d’installer l’app Watch. Les indicateurs de capacité n’ajoutent pas de matériel ni de droits d’accès à des services indisponibles.

> Compatible uniquement avec watchOS 27.0 à watchOS 27.3 beta 1.

![Apple Watch](image.png)

## Compiler et installer avec Xcode

1. Installez Xcode avec les SDK iOS et watchOS. Connectez l’iPhone jumelé à l’Apple Watch cible, approuvez les appareils et activez le mode développeur si Xcode le demande.
2. Clonez le dépôt et ouvrez `HermesEnabler2.xcodeproj` dans Xcode.
3. Dans **Signing & Capabilities**, sélectionnez votre équipe Apple Development pour **HermesCompanion** et **HermesEnabler2**. Remplacez `COMPANION_BUNDLE_IDENTIFIER` par un identifiant iPhone unique que vous contrôlez. L’identifiant Watch ajoute `.watchkitapp`.
4. Configurez un App Group identique pour les cibles et leurs profils. L’entitlement Watch utilise `group.$(COMPANION_BUNDLE_IDENTIFIER)` ; sans cet App Group, l’accès à MobileGestalt et les sauvegardes peuvent échouer.
5. Sélectionnez le schéma **HermesCompanion** et l’iPhone jumelé, puis lancez **Product → Run**. Si nécessaire, installez l’app Watch depuis **Ma montre → Apps / Apps disponibles** dans l’app Watch de l’iPhone.
6. Ouvrez HermesEnabler sur l’Apple Watch et créez d’abord la sauvegarde initiale de MobileGestalt. Conservez une sauvegarde fiable avant d’essayer plusieurs réglages.

Pour vérifier la compilation sans signature :

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh` produit un IPA iPhone **non signé** contenant l’app Watch. Signez les deux apps avec les certificats et profils appropriés avant installation.

## Installer un IPA publié

Téléchargez l’IPA depuis [Releases](https://github.com/pookjw/HermesEnabler/releases), installez-le selon votre configuration de signature, puis installez l’app Watch depuis l’iPhone si nécessaire.

## Fonctionnalités

| Élément | Menu | Action et limites |
|---|---|---|
| Hermès | Cadrans de montre | Modifie la capacité déclarée « Hermès ». |
| Cadrans Ultra | Cadrans de montre | Active ou désactive les cadrans Ultra. Leur activation empêche l’utilisation du cadran Hermès Faubourg Party. Redémarrez la montre. |
| Toujours activé | Affichage et commandes | Modifie la capacité déclarée « Toujours activé ». |
| Toujours activé à 1 Hz | Affichage et commandes | Modifie la capacité déclarée « Toujours activé à 1 Hz ». |
| Intensité des couleurs de Toujours activé | Affichage et commandes | Modifie la capacité déclarée « Intensité des couleurs de Toujours activé ». |
| Mise à jour périodique de la lumière ambiante | Affichage et commandes | Modifie la capacité déclarée « Mise à jour périodique de la lumière ambiante ». |
| Résolution d'écran | Affichage et commandes | Sélectionne ou restaure la taille d’écran déclarée ; les pixels physiques ne changent pas et l’interface peut être rognée. Redémarrez la montre. |
| Bouton Action | Affichage et commandes | Modifie la capacité déclarée « Bouton Action ». |
| Toucher deux fois | Affichage et commandes | Modifie la capacité déclarée « Toucher deux fois ». |
| Clavier à l’écran | Affichage et commandes | Modifie la capacité déclarée « Clavier à l’écran ». |
| Activer au lever du poignet | Affichage et commandes | Modifie la capacité déclarée « Activer au lever du poignet ». |
| Lever pour parler | Affichage et commandes | Modifie la capacité déclarée « Lever pour parler ». |
| Capacité d’écoute de Siri | Affichage et commandes | Modifie la capacité déclarée « Capacité d’écoute de Siri ». |
| Capteur de profondeur | Capteurs et entraînements | Modifie la capacité déclarée « Capteur de profondeur ». |
| Altimètre absolu | Capteurs et entraînements | Modifie la capacité déclarée « Altimètre absolu ». |
| Boussole toujours active | Capteurs et entraînements | Modifie la capacité déclarée « Boussole toujours active ». |
| Orientation à la boussole | Capteurs et entraînements | Modifie la capacité déclarée « Orientation à la boussole ». |
| Fréquence cardiaque continue | Capteurs et entraînements | Modifie la capacité déclarée « Fréquence cardiaque continue ». |
| Exposition au bruit | Capteurs et entraînements | Modifie la capacité déclarée « Exposition au bruit ». |
| Informations sur la batterie | Capteurs et entraînements | Modifie la capacité déclarée « Informations sur la batterie ». |
| Entraînements de natation | Capteurs et entraînements | Modifie la capacité déclarée « Entraînements de natation ». |
| Code de région | Siri et renseignements | Modifie uniquement RegionCode, sans changer le suffixe de région de vente. |
| Région de vente | Siri et renseignements | Modifie uniquement le suffixe de région de vente ; les outils d’usine peuvent signaler un écart. |
| Apple Intelligence / Siri AI | Siri et renseignements | Modifie la capacité ; Siri AI exige watchOS 27, une montre compatible et un iPhone jumelé avec Apple Intelligence. |
| Siri sur l’appareil | Siri et renseignements | Modifie la capacité déclarée « Siri sur l’appareil ». |
| Intelligence audio | Siri et renseignements | Modifie la capacité d’intelligence audio ; l’app indique qu’un matériel Series 12 / Ultra 4 est nécessaire. |
| Sauvegarde initiale | Sauvegardes MG | Crée la sauvegarde initiale protégée, non remplaçable depuis l’app. |
| Sauvegarde manuelle | Sauvegardes MG | Sauvegarde manuellement le MobileGestalt actuel. |
| Sauvegarde automatique | Sauvegardes MG | Crée une sauvegarde avant chaque écriture ou restauration de MG. |
| Restaurer MG | Sauvegardes MG | Sauvegarde d’abord le MG actuel puis restaure la sauvegarde choisie. Redémarrez la montre. |
| Redémarrer Carousel | Utilitaires | Redémarre le processus d’interface de la montre pour recharger les changements. |

Les indicateurs ne créent pas de matériel d’affichage, de capteurs ou audio et ne donnent pas accès aux services indisponibles. Les menus de région et de résolution proposent des préréglages. Les erreurs d’écriture sont affichées dans l’app.

## Crédits

Ce projet intègre du code de [Gester](https://github.com/sasobhabha/Gester). Utilisez ce projet à vos propres risques.
