# HermesEnabler 2

[English](README.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Compatível somente com watchOS 27.0 até watchOS 27.3 beta 1.

## Instalação

### macOS

No macOS, você pode instalar o IPA já compilado com o Sideloadly ou compilar o app diretamente com o Xcode. Nos dois casos, o iPhone precisa estar emparelhado com o Apple Watch de destino e o Watch precisa executar uma versão compatível do watchOS.

#### Instalar o IPA

1. Baixe o IPA em [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Instale o [Sideloadly](https://sideloadly.io) no Mac, conecte o iPhone com um cabo e selecione-o no Sideloadly.
3. Arraste o IPA para o Sideloadly e informe seu Apple ID. Desative **Use automatic bundle ID**, defina um Bundle Identifier fixo e inicie a assinatura.
4. No iPhone, abra **Ajustes → Geral → VPN e Gerenciamento de Dispositivos** e confie no seu certificado de desenvolvedor.
5. No iPhone, abra **Ajustes → Privacidade e Segurança → Modo de Desenvolvedor**, ative, reinicie e confirme.
6. No app **Watch** do iPhone, vá em **Meu Relógio → Apps** e instale o **HermesEnabler2** no Watch.
7. No Apple Watch, abra **Ajustes → Privacidade e Segurança → Modo de Desenvolvedor**, ative, reinicie e confirme. Se a opção não aparecer, instale primeiro o app do Watch e verifique novamente.
8. Abra o **HermesEnabler2** no Apple Watch e siga as etapas exibidas no app.

#### Compilar com o Xcode

1. Abra [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) no Xcode.
2. Selecione o Apple Watch como destino de execução e clique em **Run**.
3. Abra o **HermesEnabler2** no Apple Watch e siga as etapas exibidas no app.

### Windows

No Windows, use o [WatchBridge](https://github.com/AdminZachary/iloader-for-windows), uma ferramenta da comunidade que prepara o Modo de Desenvolvedor e instala um IPA que contém tanto o app host do iPhone quanto o app do Watch. Ele não é afiliado à Apple nem a este projeto.

1. Instale o **Apple Mobile Device Service** instalando o [iTunes](https://www.apple.com/itunes/) ou o app **Apple Devices** da Microsoft Store. O WatchBridge precisa dele para a comunicação via USB e Wi-Fi. O WebView2 já vem incluído no Windows 11.
2. Verifique se o iPhone está emparelhado com o Apple Watch de destino. O WatchBridge suporta apenas um Watch emparelhado por vez; se houver mais de um, a etapa de preparação para em vez de adivinhar.
3. Baixe `watchbridge-windows.zip` em [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest), extraia e execute `WatchBridge.exe`. O executável não é assinado, então o Windows SmartScreen pode avisar na primeira execução.
4. Baixe o IPA em [Releases](https://github.com/pookjw/HermesEnabler/releases). Use o IPA original que contém tanto o app host do iPhone quanto `Watch/*.app`; pacotes somente para Watch não são suportados.
5. Conecte o iPhone emparelhado via USB e selecione-o no WatchBridge.
6. Emparelhe o Watch e confirme o aviso de confiança no Watch. Solicite a chave do **Modo de Desenvolvedor**; depois, no Watch, abra **Ajustes → Privacidade e Segurança → Modo de Desenvolvedor**, ative, reinicie e confirme. Volte ao WatchBridge e clique em **Check again**. O WatchBridge não ativa o Modo de Desenvolvedor nem reinicia o Watch por você.
7. Entre com seu Apple ID, selecione o IPA do HermesEnabler2 e inicie a assinatura e a instalação. O WatchBridge instala primeiro o app host do iPhone e depois o app do Watch.
8. Abra o **HermesEnabler2** no Apple Watch e siga as etapas exibidas no app.

> A preparação do Modo de Desenvolvedor exige conexão USB. Depois de emparelhar uma vez por USB, as instalações e renovações podem usar Wi-Fi.

## Precauções

- No Sideloadly, desative **Use automatic bundle ID** e use um Bundle Identifier fixo. Use o mesmo Bundle Identifier e o mesmo Apple ID em todas as atualizações para preservar os dados e o backup existentes.
- É necessária uma conta de Apple Developer paga devido ao recurso **App Groups**.
- Se o app do iPhone for instalado, mas o app do Watch não aparecer, procure `Watch apps will be stripped from the IPA` no log do Sideloadly. Isso indica que o app Watch incorporado foi removido; instale-o usando o Xcode.
- Antes de apagar o app, restaure sempre o backup do MobileGestalt pelo app HermesEnabler2.

## Créditos

Este projeto incorpora código do [Gester](https://github.com/sasobhabha/Gester).

Use por sua conta e risco.
