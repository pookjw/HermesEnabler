# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Compatível somente com watchOS 27.0 até watchOS 27.3 beta 1.

## Instalação

### Compilar com o Xcode

#### Antes de começar

Você precisará de:

- Um Mac com uma versão do Xcode compatível com as versões do iOS e watchOS dos seus dispositivos.
- Um Apple Watch emparelhado com seu iPhone.
- Uma Conta Apple adicionada ao Xcode.
- O código-fonte do projeto. Baixe e extraia **Code → Download ZIP**, ou clone este repositório.

O Xcode é o método recomendado aqui porque um problema na instalação do app do Watch com o Sideloadly 0.72 foi relatado na [issue #43](https://github.com/pookjw/HermesEnabler/issues/43). As instruções alternativas para o IPA foram mantidas abaixo.

#### 1. Adicionar sua Conta Apple ao Xcode

1. Abra **Xcode → Settings → Accounts** ou **Apple Accounts**, dependendo da versão do Xcode.
2. Clique em **+** e entre com sua Conta Apple.
3. Sem uma assinatura paga do Apple Developer Program, sua conta aparece como **Seu nome (Personal Team)**.

“Team” identifica a conta de desenvolvedor Apple usada para assinar o app. Você não precisa entrar na equipe do autor do projeto.

Uma Personal Team permite instalar apps de desenvolvimento, mas tem limitações, incluindo expiração dos perfis e recursos não compatíveis. Consulte **Limitações de assinatura e solução de problemas** abaixo.

#### 2. Conectar o iPhone e ativar o Modo de Desenvolvedor

1. Conecte o iPhone ao Mac.
2. Desbloqueie-o e aceite **Confiar Neste Computador**, se solicitado.
3. Abra o gerenciador de dispositivos do Xcode: **Device Hub** nas versões recentes, ou **Window → Devices and Simulators** nas anteriores.
4. Aguarde o Xcode reconhecer seu iPhone.
5. No iPhone, abra **Ajustes → Privacidade e Segurança → Modo de Desenvolvedor**.
6. Ative o Modo de Desenvolvedor e aceite a reinicialização.
7. Após reiniciar, desbloqueie o iPhone e confirme a ativação.

Se a opção não aparecer, estabeleça primeiro a conexão com o Xcode e verifique os Ajustes novamente.

#### 3. Conectar o Apple Watch e ativar o Modo de Desenvolvedor

1. Mantenha o Watch desbloqueado e perto do Mac e do iPhone.
2. Deixe o Xcode detectar o Watch. No Device Hub, use a opção de adicionar ou emparelhar um dispositivo próximo, se necessário.
3. Aceite as solicitações de conexão ou confiança nos dispositivos.
4. No próprio Watch, abra **Ajustes → Privacidade e Segurança → Modo de Desenvolvedor**.
5. Ative o Modo de Desenvolvedor e aceite a reinicialização.
6. Após reiniciar, desbloqueie o Watch e confirme qualquer solicitação de ativação.
7. Reconecte o Watch ao Xcode, se necessário.

A opção no Watch pode aparecer somente depois que o Xcode tentar se conectar a ele. Se estiver ausente, estabeleça a conexão inicial e verifique os Ajustes do Watch novamente.

Para mais informações, consulte as [instruções da Apple sobre o Modo de Desenvolvedor](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

##### Se o Device Hub não conseguir emparelhar o Watch

Se o emparelhamento ou a conexão falhar enquanto o iPhone emparelhado estiver ligado, tente esta alternativa:

1. Primeiro, conclua a configuração do iPhone descrita acima.
2. **Desligue temporariamente o iPhone.**
3. Deixe o Watch ligado e desbloqueado, com Wi-Fi e Bluetooth ativados.
4. Tente emparelhar ou conectar o Watch novamente no **Device Hub/Xcode**.
5. Aceite as solicitações de conexão no Watch.
6. Assim que o Watch se conectar, ligue o iPhone novamente.

Há relatos de que essa alternativa ajuda em algumas configurações. O iPhone ligado não é uma causa confirmada de todos os problemas de emparelhamento; este procedimento pode não resolver todos os problemas de conexão.

#### 4. Configurar a assinatura e um identificador de pacote exclusivo

1. Abra `HermesEnabler2.xcodeproj`.
2. Selecione o ícone azul do projeto no navegador de projetos do Xcode.
3. Em **PROJECT**, selecione **HermesEnabler2**.
4. Abra **Build Settings**, selecione **All** e pesquise por:
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. Substitua `com.example.HermesEnabler` por um identificador exclusivo seu, por exemplo:
   ```
   com.yourname.HermesEnabler12345
   ```
6. Aplique o mesmo valor a **Debug** e **Release**.
7. Em **TARGETS**, selecione **HermesEnabler2** e abra **Signing & Capabilities**.
8. Ative **Automatically manage signing** e selecione sua equipe.
9. Repita os ajustes de assinatura para **HermesCompanion**, selecionando a mesma equipe.

Mantenha as expressões existentes dos identificadores de pacote dos targets:

| Target | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

O ajuste compartilhado mantém a consistência entre os identificadores do iPhone e do Watch.

Se o Xcode mostrar **Failed Registering Bundle Identifier** ou informar que o identificador não está disponível, escolha um `COMPANION_BUNDLE_IDENTIFIER` mais distinto. Volte a **Signing & Capabilities** e clique em **Try Again**, se o botão aparecer.

Se um erro de App Groups persistir, consulte **Erros de App Groups** abaixo.

#### 5. Compilar e executar no Watch

1. Selecione o esquema **HermesEnabler2**.
2. Escolha seu **Apple Watch físico** como destino de execução.
3. Clique em **▶ Run**.
4. Aguarde o Xcode terminar de preparar o dispositivo e instalar o app.
5. Quando o HermesEnabler2 abrir no Watch, siga as instruções do app.

**Build Succeeded** significa que a compilação terminou com sucesso. A instalação ainda pode estar em andamento.

Se o Xcode mostrar **Installing built products**, aguarde o fim da instalação. Mantenha os dispositivos próximos e conectados.

Uma sessão de depuração pode continuar ativa enquanto o app está em execução; isso é normal. Verifique a tela do Watch para saber se o app abriu.

### Alternativa: instalar o IPA com Sideloadly

> **Problema conhecido com Sideloadly 0.72:** A [issue #43](https://github.com/pookjw/HermesEnabler/issues/43) relata que essa versão remove o app watchOS incorporado durante a assinatura. O app do iPhone é instalado, mas o HermesEnabler2 não aparece no Apple Watch nem no app Watch do iPhone. Se isso acontecer, use as instruções **Compilar com o Xcode** acima.
>
> Esse relato se refere à versão 0.72. A compatibilidade com outras versões do Sideloadly não foi confirmada aqui.

1. Baixe `HermesEnabler.ipa` em [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Abra o [Sideloadly](https://sideloadly.io).
3. Desative **Use automatic bundle ID** e escolha um Bundle Identifier fixo e exclusivo.
4. Instale o IPA no iPhone.
5. No iPhone, abra **Watch → Meu Relógio → Apps** e procure **HermesEnabler2** em **Apps Disponíveis**.
6. Se aparecer, instale-o no Watch, abra-o e siga as instruções do app.
7. Se não aparecer, use o Xcode para instalar o app do Watch.

Use o mesmo Bundle Identifier e a mesma Conta Apple nas próximas atualizações para preservar os dados e o backup existentes.

## Limitações de assinatura e solução de problemas

### Expiração da Personal Team

Os perfis de provisionamento de uma Personal Team gratuita expiram após sete dias. Recompile e reinstale o app pelo Xcode quando o perfil expirar.

Continue usando a mesma Conta Apple e o mesmo identificador de pacote nas atualizações.

### Erros de App Groups

Este projeto inclui uma permissão **App Groups**. Uma Personal Team gratuita não permite provisionar esse recurso.

Se o Xcode informar que um App Group não está disponível:

- Verifique se `COMPANION_BUNDLE_IDENTIFIER` foi alterado para um valor exclusivo.
- Se você tem uma assinatura de desenvolvedor paga, selecione essa equipe e verifique se o App Group correspondente pode ser registrado.
- Alterar o identificador não remove as limitações de recursos de uma Personal Team.

Não considere a remoção de App Groups uma solução completa. A issue #43 relata uma instalação bem-sucedida com o Xcode, mas não confirma se a operação MobileGestalt funciona sem App Groups no watchOS 27.2.1.

Uma compilação ou instalação bem-sucedida, por si só, não confirma que a funcionalidade principal do app funciona.

### O app do iPhone instala, mas o app do Watch não aparece

Se você usou Sideloadly 0.72, procure esta linha no log:

```
Watch apps will be stripped from the IPA
```

Ela indica que o app do Watch incorporado foi removido. Instalar apenas o app do iPhone não disponibilizará o app do Watch ausente. Siga as instruções de instalação com o Xcode acima.

## Precauções

- Use o mesmo identificador de pacote e a mesma Conta Apple nas atualizações para preservar os dados e o backup existentes.
- Antes de apagar o app, restaure sempre o backup do MobileGestalt pelo HermesEnabler2.

## Créditos

Este projeto incorpora código do [Gester](https://github.com/sasobhabha/Gester).

Use por sua conta e risco.
