# HermesEnabler 2

[English](README.md) · [Nederlands](README.nl.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Compatible únicamente con watchOS 27.0 hasta watchOS 27.3 beta 1.

## Instalación

### macOS

En macOS puedes instalar el IPA ya compilado con Sideloadly o compilar la app directamente con Xcode. En ambos casos, el iPhone debe estar emparejado con el Apple Watch de destino y el Watch debe ejecutar una versión compatible de watchOS.

#### Instalar el IPA

> **Problema conocido de Sideloadly 0.72:** En el [issue #43](https://github.com/pookjw/HermesEnabler/issues/43) se informa que esta versión puede eliminar la app Watch incluida en el IPA al firmarlo. Si se instala la app del iPhone pero HermesEnabler2 no aparece en el Watch, usa Xcode. El informe corresponde a la versión 0.72; no se ha confirmado la compatibilidad con otras versiones.

1. Descarga el IPA desde [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Instala [Sideloadly](https://sideloadly.io) en el Mac, conecta el iPhone con un cable y selecciónalo en Sideloadly.
3. Arrastra el IPA a Sideloadly e introduce tu Apple ID. Desactiva **Use automatic bundle ID**, indica un Bundle Identifier fijo y comienza la firma.
4. En el iPhone, abre **Ajustes → General → VPN y gestión de dispositivos** y confía en tu certificado de desarrollador.
5. En el iPhone, abre **Ajustes → Privacidad y seguridad → Modo de desarrollador**, actívalo, reinicia y confirma.
6. En la app **Watch** del iPhone, ve a **Mi reloj → Apps** e instala **HermesEnabler2** en el Watch.
7. En el Apple Watch, abre **Ajustes → Privacidad y seguridad → Modo de desarrollador**, actívalo, reinicia y confirma. Si la opción no aparece, instala primero la app del Watch y vuelve a comprobarlo.
8. Abre **HermesEnabler2** en el Apple Watch y sigue los pasos de la app.

#### Compilar con Xcode

Necesitas un Mac con una versión de Xcode compatible con las versiones de iOS y watchOS de tus dispositivos, y un Apple Watch emparejado con tu iPhone.

1. Descarga y extrae el código fuente mediante **Code → Download ZIP**, o clona este repositorio. Abre [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) en Xcode.
2. Añade tu cuenta de Apple en **Xcode → Settings → Accounts** (o **Apple Accounts**). Bajo **TARGETS**, abre **Signing & Capabilities** para **HermesEnabler2** y **HermesCompanion**, activa **Automatically manage signing** y selecciona tu propio equipo en ambos.
3. Selecciona el icono azul del proyecto y después **PROJECT → HermesEnabler2 → Build Settings → All**. Busca `COMPANION_BUNDLE_IDENTIFIER` y sustituye `com.example.HermesEnabler` por un identificador único propio, con el mismo valor para **Debug** y **Release**. Conserva las expresiones existentes de Bundle Identifier de los targets.
4. Conecta y desbloquea el iPhone, acepta los avisos de confianza y deja que Xcode detecte el Watch mediante **Device Hub** o **Window → Devices and Simulators**. En ambos dispositivos, activa **Ajustes → Privacidad y seguridad → Modo de desarrollador**, reinicia y confirma. Si no aparece el ajuste, deja que Xcode intente conectarse primero y vuelve a comprobarlo.
5. Selecciona el esquema **HermesEnabler2** y tu **Apple Watch físico** como destino de ejecución, y pulsa **▶ Run**. Espera a que termine la instalación, abre **HermesEnabler2** en el Watch y sigue los pasos de la app. **Build Succeeded** significa que terminó la compilación; la instalación puede seguir en curso.

> Si Device Hub no puede conectarse al Watch, a algunos usuarios les ha ayudado apagar temporalmente el iPhone emparejado y volver a intentarlo. Mantén el Watch desbloqueado, con Wi-Fi y Bluetooth activados, y vuelve a encender el iPhone después de conectar. Esta solución puede no funcionar en todas las configuraciones.
>
> Consulta **Precauciones** más abajo para conocer la caducidad de Personal Team y las limitaciones de firma de App Groups. Mantén la misma cuenta de Apple y Bundle Identifier en futuras actualizaciones.

### Windows

En Windows se utiliza [WatchBridge](https://github.com/AdminZachary/iloader-for-windows), una herramienta comunitaria que prepara el modo de desarrollador e instala un IPA que contiene tanto la app anfitriona del iPhone como la app del Watch. No está afiliada a Apple ni a este proyecto.

1. Instala **Apple Mobile Device Service** instalando [iTunes](https://www.apple.com/itunes/) o la app **Apple Devices** de Microsoft Store. WatchBridge lo necesita para la comunicación por USB y Wi-Fi. WebView2 viene incluido en Windows 11.
2. Comprueba que el iPhone esté emparejado con el Apple Watch de destino. WatchBridge admite un solo Watch emparejado a la vez; si hay más de uno, el paso de preparación se detiene en lugar de adivinar.
3. Descarga `watchbridge-windows.zip` desde [WatchBridge Releases](https://github.com/AdminZachary/iloader-for-windows/releases/latest), extráelo y ejecuta `WatchBridge.exe`. El ejecutable no está firmado, por lo que Windows SmartScreen puede avisar en el primer inicio.
4. Descarga el IPA desde [Releases](https://github.com/pookjw/HermesEnabler/releases). Usa el IPA original que contiene tanto la app anfitriona del iPhone como `Watch/*.app`; los paquetes solo para Watch no son compatibles.
5. Conecta el iPhone emparejado por USB y selecciónalo en WatchBridge.
6. Empareja el Watch y confirma el aviso de confianza en el Watch. Solicita el interruptor de **Modo de desarrollador**; después, en el Watch, abre **Ajustes → Privacidad y seguridad → Modo de desarrollador**, actívalo, reinicia y confirma. Vuelve a WatchBridge y pulsa **Check again**. WatchBridge no activa el modo de desarrollador ni reinicia el Watch por ti.
7. Inicia sesión con tu Apple ID, selecciona el IPA de HermesEnabler2 y comienza la firma e instalación. WatchBridge instala primero la app anfitriona del iPhone y después la app del Watch.
8. Abre **HermesEnabler2** en el Apple Watch y sigue los pasos de la app.

> La preparación del modo de desarrollador requiere conexión USB. Después de emparejar una vez por USB, las instalaciones y renovaciones pueden usar Wi-Fi.

## Precauciones

- En Sideloadly, desactiva **Use automatic bundle ID** y utiliza un Bundle Identifier fijo. Usa el mismo Bundle Identifier y Apple ID en cada actualización para conservar los datos y la copia de seguridad existentes.
- Los perfiles de aprovisionamiento de Apple Personal Team gratuito caducan a los siete días. Cuando ocurra, vuelve a compilar e instalar la app con el mismo Apple ID y Bundle Identifier.
- Este proyecto usa la capacidad **App Groups**, que un Personal Team gratuito no puede aprovisionar. Puede ser necesario un equipo de desarrollador de pago; cambiar el Bundle Identifier no elimina esta limitación. No des por hecho que quitar la capacidad sea una solución completa: no se ha confirmado que la función principal de la app opere sin ella.
- Si se instala la app del iPhone pero no aparece la del Watch, busca `Watch apps will be stripped from the IPA` en el registro de Sideloadly. Significa que se eliminó la app Watch incluida; instala la app Watch con Xcode.
- Antes de eliminar la app, restaura siempre la copia de seguridad de MobileGestalt desde la app HermesEnabler2.

## Créditos

Este proyecto incorpora código de [Gester](https://github.com/sasobhabha/Gester).

Úsalo bajo tu propia responsabilidad.
