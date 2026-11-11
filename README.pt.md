# HermesEnabler 2
[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnabler é um app para Apple Watch que altera recursos e propriedades do dispositivo informados pelo MobileGestalt. O app complementar no iPhone ajuda a instalar o app do relógio. Sinalizadores de recurso não adicionam hardware nem dão acesso a serviços indisponíveis.

> Compatível somente com watchOS 27.0 até watchOS 27.3 beta 1.

![Apple Watch](image.png)

## Compilar e instalar com o Xcode

1. Instale o Xcode com os SDKs de iOS e watchOS. Conecte o iPhone emparelhado ao Apple Watch, confie nos dispositivos e ative o Modo de Desenvolvedor se o Xcode solicitar.
2. Clone o repositório e abra `HermesEnabler2.xcodeproj` no Xcode.
3. Em **Signing & Capabilities**, escolha sua equipe Apple Development para **HermesCompanion** e **HermesEnabler2**. Defina `COMPANION_BUNDLE_IDENTIFIER` como um Bundle ID exclusivo de iPhone sob seu controle. O ID do app Watch acrescenta `.watchkitapp`.
4. Configure um App Group correspondente para os alvos e perfis de provisionamento. O entitlement do Watch usa `group.$(COMPANION_BUNDLE_IDENTIFIER)`; sem ele, o acesso ao MobileGestalt e os backups podem falhar.
5. Selecione o esquema **HermesCompanion** e o iPhone emparelhado; execute **Product → Run**. Se necessário, instale o app Watch em **Meu Relógio → Apps / Apps Disponíveis** no app Watch do iPhone.
6. Abra o HermesEnabler no Apple Watch e crie primeiro o backup inicial do MobileGestalt. Guarde um backup conhecido antes de testar várias opções.

Para conferir apenas a compilação, sem assinatura:

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh` gera um IPA de iPhone **sem assinatura** com o app Watch incluído. Assine os dois apps com certificados e perfis adequados antes de instalar.

## Instalar um IPA publicado

Baixe o IPA em [Releases](https://github.com/pookjw/HermesEnabler/releases), instale-o conforme sua configuração de assinatura e, se preciso, instale o app Watch pelo iPhone.

## Recursos

| Item | Menu | Ação e limites |
|---|---|---|
| Hermès | Mostradores de relógio | Altera o recurso informado “Hermès”. |
| Mostradores Ultra | Mostradores de relógio | Alterna os mostradores Ultra. Quando ativados, o mostrador Hermès Faubourg Party fica indisponível. Reinicie o relógio. |
| Sempre Ativo | Tela e controles | Altera o recurso informado “Sempre Ativo”. |
| Sempre Ativo a 1 Hz | Tela e controles | Altera o recurso informado “Sempre Ativo a 1 Hz”. |
| Intensidade de cor do Sempre Ativo | Tela e controles | Altera o recurso informado “Intensidade de cor do Sempre Ativo”. |
| Atualizações periódicas da luz ambiente | Tela e controles | Altera o recurso informado “Atualizações periódicas da luz ambiente”. |
| Resolução da tela | Tela e controles | Seleciona ou restaura o tamanho de tela informado; não altera os pixels físicos e pode cortar a interface. Reinicie o relógio. |
| Botão de Ação | Tela e controles | Altera o recurso informado “Botão de Ação”. |
| Toque duplo | Tela e controles | Altera o recurso informado “Toque duplo”. |
| Teclado na tela | Tela e controles | Altera o recurso informado “Teclado na tela”. |
| Despertar ao levantar o pulso | Tela e controles | Altera o recurso informado “Despertar ao levantar o pulso”. |
| Levantar para Falar | Tela e controles | Altera o recurso informado “Levantar para Falar”. |
| Capacidade de escuta da Siri | Tela e controles | Altera o recurso informado “Capacidade de escuta da Siri”. |
| Sensor de profundidade | Sensores e exercícios | Altera o recurso informado “Sensor de profundidade”. |
| Altímetro absoluto | Sensores e exercícios | Altera o recurso informado “Altímetro absoluto”. |
| Bússola sempre ativa | Sensores e exercícios | Altera o recurso informado “Bússola sempre ativa”. |
| Orientação pela bússola | Sensores e exercícios | Altera o recurso informado “Orientação pela bússola”. |
| Frequência cardíaca contínua | Sensores e exercícios | Altera o recurso informado “Frequência cardíaca contínua”. |
| Exposição ao ruído | Sensores e exercícios | Altera o recurso informado “Exposição ao ruído”. |
| Informações da bateria | Sensores e exercícios | Altera o recurso informado “Informações da bateria”. |
| Treinos de natação | Sensores e exercícios | Altera o recurso informado “Treinos de natação”. |
| Código da região | Siri e Inteligência | Altera apenas RegionCode, preservando o sufixo da região de vendas. |
| Região de vendas | Siri e Inteligência | Altera apenas o sufixo da região de vendas; ferramentas de fábrica podem indicar divergência. |
| Apple Intelligence / Siri AI | Siri e Inteligência | Altera o recurso; Siri AI exige watchOS 27, um Watch compatível e um iPhone emparelhado com Apple Intelligence. |
| Siri no dispositivo | Siri e Inteligência | Altera o recurso informado “Siri no dispositivo”. |
| Inteligência de áudio | Siri e Inteligência | Altera o recurso de inteligência de áudio; o app indica a necessidade de hardware Series 12 / Ultra 4. |
| Backup inicial | Backups MG | Cria o backup inicial protegido, que não pode ser sobrescrito no app. |
| Backup manual | Backups MG | Faz backup manual do MobileGestalt atual. |
| Backup Automático | Backups MG | Cria backup automático antes de gravar ou restaurar o MG. |
| Restaurar MG | Backups MG | Faz backup do MG atual antes de restaurar o backup selecionado. Reinicie o relógio. |
| Reinicie Carousel | Utilitários | Reinicia o processo de interface do Watch para recarregar as alterações. |

Os sinalizadores não adicionam tela, sensores ou hardware de áudio nem ignoram restrições de serviço. Os menus de região e resolução oferecem opções predefinidas; erros de gravação aparecem no app.

## Créditos

Este projeto incorpora código do [Gester](https://github.com/sasobhabha/Gester). Use por sua conta e risco.
