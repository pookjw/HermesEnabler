# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Compatible únicamente con watchOS 27.0 hasta watchOS 27.3 beta 1.

## Instalación

### Compilar con Xcode

#### Antes de empezar

Necesitarás:

- Un Mac con una versión de Xcode compatible con las versiones de iOS y watchOS de tus dispositivos.
- Un Apple Watch enlazado con tu iPhone.
- Una cuenta de Apple añadida a Xcode.
- El código fuente del proyecto. Descarga y extrae **Code → Download ZIP**, o clona este repositorio.

Aquí se recomienda Xcode porque se ha informado de un problema al instalar la app del Watch con Sideloadly 0.72 en la [incidencia #43](https://github.com/pookjw/HermesEnabler/issues/43). Las instrucciones alternativas para el IPA se conservan más abajo.

#### 1. Añadir tu cuenta de Apple a Xcode

1. Abre **Xcode → Settings → Accounts** o **Apple Accounts**, según tu versión de Xcode.
2. Pulsa **+** e inicia sesión con tu cuenta de Apple.
3. Si no tienes una suscripción de pago al Apple Developer Program, tu cuenta aparecerá como **Tu nombre (Personal Team)**.

«Team» identifica la cuenta de desarrollador de Apple que firma la app. No necesitas unirte al equipo del autor del proyecto.

Un Personal Team permite instalar apps de desarrollo, pero tiene limitaciones, como la caducidad de los perfiles y funciones no compatibles. Consulta **Limitaciones de firma y solución de problemas** más abajo.

#### 2. Conectar el iPhone y activar el modo de desarrollador

1. Conecta tu iPhone al Mac.
2. Desbloquéalo y acepta **Confiar en este ordenador** si aparece.
3. Abre el gestor de dispositivos de Xcode: **Device Hub** en versiones recientes, o **Window → Devices and Simulators** en versiones anteriores.
4. Espera a que Xcode reconozca el iPhone.
5. En el iPhone, abre **Ajustes → Privacidad y seguridad → Modo de desarrollador**.
6. Activa el modo de desarrollador y acepta el reinicio.
7. Tras reiniciar, desbloquea el iPhone y confirma la activación.

Si no aparece el ajuste, establece primero la conexión con Xcode y vuelve a comprobar Ajustes.

#### 3. Conectar el Apple Watch y activar el modo de desarrollador

1. Mantén el Watch desbloqueado y cerca del Mac y del iPhone.
2. Deja que Xcode detecte el Watch. En Device Hub, utiliza la opción de añadir o enlazar un dispositivo cercano si es necesario.
3. Acepta las solicitudes de conexión o confianza en tus dispositivos.
4. En el propio Watch, abre **Ajustes → Privacidad y seguridad → Modo de desarrollador**.
5. Activa el modo de desarrollador y acepta el reinicio.
6. Tras reiniciar, desbloquea el Watch y confirma cualquier solicitud de activación.
7. Vuelve a conectar el Watch en Xcode si es necesario.

El ajuste del Watch puede no aparecer hasta que Xcode intente conectarse a él. Si falta, establece la conexión inicial y vuelve a comprobar los Ajustes del Watch.

Para más información, consulta las [instrucciones de Apple sobre el modo de desarrollador](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

##### Si Device Hub no puede enlazar el Watch

Si el enlace o la conexión falla mientras el iPhone enlazado está encendido, prueba esta solución alternativa:

1. Completa primero la configuración del iPhone descrita arriba.
2. **Apaga temporalmente el iPhone.**
3. Deja el Watch encendido y desbloqueado, con Wi-Fi y Bluetooth activados.
4. Vuelve a intentar enlazar o conectar el Watch en **Device Hub/Xcode**.
5. Acepta las solicitudes de conexión en el Watch.
6. Cuando el Watch se conecte, vuelve a encender el iPhone.

Se ha informado de que esta solución ayuda en algunas configuraciones. No se ha confirmado que tener el iPhone encendido sea la causa de todos los problemas de enlace; este procedimiento puede no resolver todos los problemas de conexión.

#### 4. Configurar la firma y un identificador de paquete único

1. Abre `HermesEnabler2.xcodeproj`.
2. Selecciona el icono azul del proyecto en el navegador de proyectos de Xcode.
3. Bajo **PROJECT**, selecciona **HermesEnabler2**.
4. Abre **Build Settings**, selecciona **All** y busca:
   ```
   COMPANION_BUNDLE_IDENTIFIER
   ```
5. Sustituye `com.example.HermesEnabler` por un identificador único propio, por ejemplo:
   ```
   com.yourname.HermesEnabler12345
   ```
6. Aplica el mismo valor a **Debug** y **Release**.
7. Bajo **TARGETS**, selecciona **HermesEnabler2** y abre **Signing & Capabilities**.
8. Activa **Automatically manage signing** y selecciona tu equipo.
9. Repite los ajustes de firma para **HermesCompanion**, seleccionando el mismo equipo.

No cambies las expresiones existentes de los identificadores de paquete de los targets:

| Target | Bundle Identifier |
| --- | --- |
| HermesCompanion | `$(COMPANION_BUNDLE_IDENTIFIER)` |
| HermesEnabler2 | `$(COMPANION_BUNDLE_IDENTIFIER).watchkitapp` |

El ajuste compartido mantiene la coherencia entre los identificadores del iPhone y del Watch.

Si Xcode muestra **Failed Registering Bundle Identifier** o indica que el identificador no está disponible, elige un `COMPANION_BUNDLE_IDENTIFIER` más distintivo. Vuelve a **Signing & Capabilities** y pulsa **Try Again** si aparece ese botón.

Si persiste un error de App Groups, consulta **Errores de App Groups** más abajo.

#### 5. Compilar y ejecutar en el Watch

1. Selecciona el esquema **HermesEnabler2**.
2. Elige tu **Apple Watch físico** como destino de ejecución.
3. Pulsa **▶ Run**.
4. Deja que Xcode termine de preparar el dispositivo e instalar la app.
5. Cuando HermesEnabler2 se abra en el Watch, sigue las instrucciones de la app.

**Build Succeeded** significa que la compilación ha terminado correctamente. La instalación puede seguir en curso.

Si Xcode muestra **Installing built products**, espera a que termine la instalación. Mantén los dispositivos cerca y conectados.

La sesión de depuración puede permanecer activa mientras se ejecuta la app; es normal. Comprueba en la pantalla del Watch si se ha abierto.

### Alternativa: instalar el IPA con Sideloadly

> **Problema conocido con Sideloadly 0.72:** La [incidencia #43](https://github.com/pookjw/HermesEnabler/issues/43) informa de que esta versión elimina la app watchOS integrada durante la firma. La app del iPhone se instala, pero HermesEnabler2 no aparece en el Apple Watch ni en la app Watch del iPhone. Si te ocurre, utiliza las instrucciones **Compilar con Xcode** de arriba.
>
> Este informe se refiere a la versión 0.72. Aquí no se ha confirmado la compatibilidad con otras versiones de Sideloadly.

1. Descarga `HermesEnabler.ipa` desde [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Abre [Sideloadly](https://sideloadly.io).
3. Desactiva **Use automatic bundle ID** y elige un Bundle Identifier fijo y único.
4. Instala el IPA en tu iPhone.
5. En el iPhone, abre **Watch → Mi reloj → Apps** y busca **HermesEnabler2** en **Apps disponibles**.
6. Si aparece, instálala en el Watch, ábrela y sigue sus instrucciones.
7. Si no aparece, utiliza Xcode para instalar la app del Watch.

Usa el mismo Bundle Identifier y la misma cuenta de Apple en futuras actualizaciones para conservar los datos y la copia de seguridad existentes.

## Limitaciones de firma y solución de problemas

### Caducidad de Personal Team

Los perfiles de aprovisionamiento de un Personal Team gratuito caducan a los siete días. Vuelve a compilar e instalar la app con Xcode cuando caduque el perfil.

Sigue usando la misma cuenta de Apple y el mismo identificador de paquete para actualizar.

### Errores de App Groups

Este proyecto incluye un permiso **App Groups**. Un Personal Team gratuito no permite aprovisionar esta función.

Si Xcode indica que un App Group no está disponible:

- Comprueba que `COMPANION_BUNDLE_IDENTIFIER` se haya cambiado por un valor único.
- Si tienes una suscripción de desarrollador de pago, selecciona ese equipo y comprueba que se pueda registrar el App Group correspondiente.
- Cambiar el identificador no elimina las limitaciones de funciones de un Personal Team.

No supongas que eliminar App Groups es una solución completa. La incidencia #43 informa de una instalación correcta con Xcode, pero no confirma que la operación de MobileGestalt funcione sin App Groups en watchOS 27.2.1.

Una compilación o instalación correcta no demuestra por sí sola que funcione la función principal de la app.

### Se instala la app del iPhone, pero falta la del Watch

Si utilizaste Sideloadly 0.72, busca en su registro:

```
Watch apps will be stripped from the IPA
```

Esto indica que se eliminó la app del Watch integrada. Instalar solo la app del iPhone no hará que la app del Watch aparezca. Sigue las instrucciones de instalación con Xcode de arriba.

## Precauciones

- Usa el mismo identificador de paquete y la misma cuenta de Apple en las actualizaciones para conservar los datos y la copia de seguridad existentes.
- Antes de eliminar la app, restaura siempre la copia de seguridad de MobileGestalt desde HermesEnabler2.

## Créditos

Este proyecto incorpora código de [Gester](https://github.com/sasobhabha/Gester).

Úsalo bajo tu propia responsabilidad.
