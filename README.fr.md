# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Compatible uniquement avec watchOS 27.0 à watchOS 27.3 beta 1.

## Installation

### Compiler avec Xcode

#### Avant de commencer

Vous aurez besoin :

- D’un Mac avec une version de Xcode compatible avec les versions d’iOS et de watchOS de vos appareils.
- D’une Apple Watch jumelée à votre iPhone.
- D’un compte Apple ajouté à Xcode.
- Du code source du projet. Téléchargez et décompressez **Code → Download ZIP**, ou clonez ce dépôt.

Xcode est la méthode recommandée ici, car un problème d’installation de l’app Watch avec Sideloadly 0.72 a été signalé dans [l’issue nº 43](https://github.com/pookjw/HermesEnabler/issues/43). Les instructions alternatives pour l’IPA sont conservées ci-dessous.

#### 1. Ajouter votre compte Apple à Xcode

1. Ouvrez **Xcode → Settings → Accounts** ou **Apple Accounts**, selon la version de Xcode.
2. Cliquez sur **+** et connectez-vous avec votre compte Apple.
3. Sans abonnement payant à l’Apple Developer Program, votre compte apparaît comme **Votre nom (Personal Team)**.

« Team » désigne le compte développeur Apple utilisé pour signer l’app. Vous n’avez pas à rejoindre l’équipe de l’auteur du projet.

Une Personal Team permet d’installer des apps de développement, mais comporte des limites : expiration des profils et fonctionnalités non prises en charge. Consultez **Limites de signature et dépannage** ci-dessous.

#### 2. Connecter l’iPhone et activer le mode développeur

1. Connectez votre iPhone à votre Mac.
2. Déverrouillez-le et acceptez **Faire confiance à cet ordinateur** si nécessaire.
3. Ouvrez le gestionnaire d’appareils de Xcode : **Device Hub** dans les versions récentes, ou **Window → Devices and Simulators** dans les anciennes.
4. Laissez Xcode reconnaître votre iPhone.
5. Sur l’iPhone, ouvrez **Réglages → Confidentialité et sécurité → Mode développeur**.
6. Activez le mode développeur et acceptez le redémarrage.
7. Après le redémarrage, déverrouillez l’iPhone et confirmez l’activation du mode développeur.

Si le réglage est absent, établissez d’abord la connexion avec Xcode, puis vérifiez à nouveau les Réglages.

#### 3. Connecter l’Apple Watch et activer le mode développeur

1. Gardez la Watch déverrouillée et à proximité du Mac et de l’iPhone.
2. Laissez Xcode détecter la Watch. Dans Device Hub, utilisez si nécessaire l’option d’ajout ou de jumelage d’un appareil à proximité.
3. Acceptez les demandes de connexion ou de confiance sur vos appareils.
4. Sur la Watch elle-même, ouvrez **Réglages → Confidentialité et sécurité → Mode développeur**.
5. Activez le mode développeur et acceptez le redémarrage.
6. Après le redémarrage, déverrouillez la Watch et confirmez toute demande d’activation.
7. Reconnectez la Watch à Xcode si nécessaire.

Le réglage peut n’apparaître sur la Watch qu’après une tentative de connexion de Xcode. S’il est absent, établissez cette première connexion, puis vérifiez à nouveau les Réglages de la Watch.

Consultez les [instructions d’Apple sur le mode développeur](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) pour plus d’informations.

##### Si Device Hub ne parvient pas à jumeler la Watch

Si le jumelage ou la connexion échoue alors que l’iPhone jumelé est allumé, essayez cette solution de contournement :

1. Terminez d’abord la configuration de l’iPhone décrite ci-dessus.
2. **Éteignez temporairement l’iPhone.**
3. Laissez la Watch allumée et déverrouillée, avec le Wi-Fi et le Bluetooth activés.
4. Réessayez le jumelage ou la connexion de la Watch dans **Device Hub/Xcode**.
5. Acceptez les demandes de connexion sur la Watch.
6. Une fois la Watch connectée, rallumez l’iPhone.

Cette solution a été signalée comme utile dans certaines configurations. Un iPhone allumé n’est pas une cause confirmée de tous les problèmes de jumelage ; cette procédure peut ne pas résoudre chaque problème de connexion.

#### 4. Configurer la signature et un identifiant de bundle unique

1. Ouvrez `HermesEnabler2.xcodeproj`.
2. Sélectionnez l’icône bleue du projet dans le navigateur de projets de Xcode.
3. Sous **PROJECT**, sélectionnez **HermesEnabler2**.
4. Ouvrez **Build Settings**, sélectionnez **All**, puis recherchez :
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. Remplacez `com.example.HermesEnabler` par votre propre identifiant unique, par exemple :
   ```
   com.yourname.HermesEnabler12345
   ```
6. Appliquez la même valeur à **Debug** et **Release**.
7. Sous **TARGETS**, sélectionnez **HermesEnabler2** et ouvrez **Signing & Capabilities**.
8. Cochez **Automatically manage signing** et sélectionnez votre équipe.
9. Répétez ces réglages pour **HermesCompanion**, avec la même équipe.

Conservez les expressions existantes des identifiants de bundle des cibles :

| Cible | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

Le réglage commun maintient la cohérence entre les identifiants des apps iPhone et Watch.

Si Xcode affiche **Failed Registering Bundle Identifier** ou indique que l’identifiant n’est pas disponible, choisissez un `COMPANION_BUNDLE_IDENTIFIER` plus distinctif. Revenez à **Signing & Capabilities** et cliquez sur **Try Again** si ce bouton apparaît.

Si une erreur App Groups persiste, consultez **Erreurs App Groups** ci-dessous.

#### 5. Compiler et exécuter sur la Watch

1. Sélectionnez le schéma **HermesEnabler2**.
2. Choisissez votre **Apple Watch physique** comme destination d’exécution.
3. Cliquez sur **▶ Run**.
4. Laissez Xcode terminer la préparation de l’appareil et l’installation de l’app.
5. Une fois HermesEnabler2 ouvert sur la Watch, suivez les instructions dans l’app.

**Build Succeeded** signifie que la compilation a réussi. L’installation peut encore être en cours.

Si Xcode affiche **Installing built products**, attendez la fin de l’installation. Gardez vos appareils à proximité et connectés.

Une session de débogage peut rester active pendant l’exécution de l’app ; c’est normal. Vérifiez sur l’écran de la Watch si l’app s’est ouverte.

### Alternative : installer l’IPA avec Sideloadly

> **Problème connu avec Sideloadly 0.72 :** [L’issue nº 43](https://github.com/pookjw/HermesEnabler/issues/43) rapporte que cette version supprime l’app watchOS intégrée pendant la signature. L’app iPhone s’installe, mais HermesEnabler2 n’apparaît ni sur l’Apple Watch ni dans l’app Watch de l’iPhone. Dans ce cas, utilisez les instructions **Compiler avec Xcode** ci-dessus.
>
> Ce signalement concerne la version 0.72. La compatibilité des autres versions de Sideloadly n’a pas été confirmée ici.

1. Téléchargez `HermesEnabler.ipa` depuis [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Ouvrez [Sideloadly](https://sideloadly.io).
3. Désactivez **Use automatic bundle ID** et choisissez un Bundle Identifier fixe et unique.
4. Installez l’IPA sur votre iPhone.
5. Sur l’iPhone, ouvrez **Watch → Ma montre → Apps** et cherchez **HermesEnabler2** sous **Apps disponibles**.
6. Si l’app apparaît, installez-la sur la Watch, puis ouvrez-la et suivez ses instructions.
7. Si elle n’apparaît pas, utilisez Xcode pour installer l’app Watch.

Conservez le même Bundle Identifier et le même compte Apple pour les mises à jour afin de préserver les données et la sauvegarde existantes.

## Limites de signature et dépannage

### Expiration des profils Personal Team

Les profils de provisionnement d’une Personal Team gratuite expirent après sept jours. Recompilez et réinstallez l’app avec Xcode à leur expiration.

Continuez à utiliser le même compte Apple et le même identifiant de bundle pour les mises à jour.

### Erreurs App Groups

Ce projet inclut une autorisation **App Groups**. Une Personal Team gratuite ne permet pas de provisionner cette fonctionnalité.

Si Xcode indique qu’un App Group est indisponible :

- Vérifiez que `COMPANION_BUNDLE_IDENTIFIER` a été remplacé par une valeur unique.
- Si vous avez un abonnement développeur payant, sélectionnez l’équipe correspondante et vérifiez que l’App Group associé peut être enregistré.
- Changer l’identifiant ne supprime pas les limites de fonctionnalités d’une Personal Team.

Ne considérez pas la suppression d’App Groups comme une solution complète. L’issue nº 43 rapporte une installation réussie avec Xcode, mais ne confirme pas que l’opération MobileGestalt fonctionne sans App Groups sur watchOS 27.2.1.

Une compilation ou une installation réussie ne suffit pas à confirmer le fonctionnement de la fonctionnalité principale de l’app.

### L’app iPhone s’installe, mais l’app Watch est absente

Si vous avez utilisé Sideloadly 0.72, cherchez cette ligne dans son journal :

```
Watch apps will be stripped from the IPA
```

Elle indique que l’app Watch intégrée a été supprimée. Installer uniquement l’app iPhone ne rendra pas l’app Watch manquante disponible. Suivez les instructions d’installation avec Xcode ci-dessus.

## Précautions

- Conservez le même identifiant de bundle et le même compte Apple pour les mises à jour afin de préserver les données et la sauvegarde existantes.
- Avant de supprimer l’app, restaurez toujours votre sauvegarde MobileGestalt depuis HermesEnabler2.

## Crédits

Ce projet intègre du code de [Gester](https://github.com/sasobhabha/Gester).

Utilisez ce projet à vos propres risques.
