# HermesEnabler 2
[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

HermesEnabler es una app para Apple Watch que modifica las capacidades y propiedades que MobileGestalt comunica sobre el dispositivo. La app complementaria del iPhone permite instalar la app del reloj. Los indicadores de capacidad no añaden hardware ni habilitan servicios para los que el dispositivo no cumple los requisitos.

> Compatible únicamente con watchOS 27.0 hasta watchOS 27.3 beta 1.

![Apple Watch](image.png)

## Compilar e instalar con Xcode

1. Instala Xcode con los SDK de iOS y watchOS. Conecta el iPhone enlazado al Apple Watch, confía en ambos dispositivos y activa el modo de desarrollador si Xcode lo solicita.
2. Clona el repositorio y abre `HermesEnabler2.xcodeproj` en Xcode.
3. En **Signing & Capabilities**, selecciona tu equipo de Apple Development para **HermesCompanion** y **HermesEnabler2**. Cambia `COMPANION_BUNDLE_IDENTIFIER` por un Bundle ID de iPhone único bajo tu control. El ID del reloj añade `.watchkitapp`.
4. Configura un App Group coincidente para los destinos y sus perfiles. El entitlement del reloj utiliza `group.$(COMPANION_BUNDLE_IDENTIFIER)`; si falta, pueden fallar el acceso a MobileGestalt y las copias de seguridad.
5. Selecciona el esquema **HermesCompanion** y el iPhone enlazado; ejecuta **Product → Run**. Si la app del reloj no se instala automáticamente, instálala desde **Mi reloj → Apps / Apps disponibles** en la app Watch del iPhone.
6. Abre HermesEnabler en el Apple Watch y crea primero la copia de seguridad inicial de MobileGestalt. Guarda una copia que sepas que funciona antes de probar varios ajustes.

Para comprobar la compilación sin firmar:

```sh
xcodebuild -project HermesEnabler2.xcodeproj \
  -scheme HermesEnabler2 -configuration Debug \
  -destination 'generic/platform=watchOS' \
  CODE_SIGNING_ALLOWED=NO build
```

`scripts/create_ipa.sh` genera un IPA de iPhone **sin firmar** que incluye la app del reloj. Firma ambas apps con certificados y perfiles adecuados antes de instalarlo.

## Instalar un IPA publicado

Descarga el IPA desde [Releases](https://github.com/pookjw/HermesEnabler/releases) e instálalo con un método adecuado para tu firma. Si hace falta, instala después la app del reloj desde la app Watch del iPhone.

## Funciones

| Elemento | Menú | Función y límites |
|---|---|---|
| Hermès | Esferas | Cambia la capacidad declarada de «Hermès». |
| Esferas Ultra | Esferas | Activa o desactiva las esferas Ultra. Al activarlas, la esfera Hermès Faubourg Party deja de estar disponible. Reinicia el reloj. |
| Mostrar siempre | Pantalla y controles | Cambia la capacidad declarada de «Mostrar siempre». |
| Mostrar siempre a 1 Hz | Pantalla y controles | Cambia la capacidad declarada de «Mostrar siempre a 1 Hz». |
| Intensidad de color de Mostrar siempre | Pantalla y controles | Cambia la capacidad declarada de «Intensidad de color de Mostrar siempre». |
| Actualización periódica de luz ambiental | Pantalla y controles | Cambia la capacidad declarada de «Actualización periódica de luz ambiental». |
| Resolución de pantalla | Pantalla y controles | Selecciona o restaura el tamaño de pantalla declarado; no cambia los píxeles físicos y puede recortar la interfaz. Reinicia el reloj. |
| Botón de acción | Pantalla y controles | Cambia la capacidad declarada de «Botón de acción». |
| Doble toque | Pantalla y controles | Cambia la capacidad declarada de «Doble toque». |
| Teclado en pantalla | Pantalla y controles | Cambia la capacidad declarada de «Teclado en pantalla». |
| Activar al levantar la muñeca | Pantalla y controles | Cambia la capacidad declarada de «Activar al levantar la muñeca». |
| Levantar para hablar | Pantalla y controles | Cambia la capacidad declarada de «Levantar para hablar». |
| Capacidad de escucha de Siri | Pantalla y controles | Cambia la capacidad declarada de «Capacidad de escucha de Siri». |
| Sensor de profundidad | Sensores y entrenamientos | Cambia la capacidad declarada de «Sensor de profundidad». |
| Altímetro absoluto | Sensores y entrenamientos | Cambia la capacidad declarada de «Altímetro absoluto». |
| Brújula siempre activa | Sensores y entrenamientos | Cambia la capacidad declarada de «Brújula siempre activa». |
| Orientación con brújula | Sensores y entrenamientos | Cambia la capacidad declarada de «Orientación con brújula». |
| Frecuencia cardiaca continua | Sensores y entrenamientos | Cambia la capacidad declarada de «Frecuencia cardiaca continua». |
| Exposición al ruido | Sensores y entrenamientos | Cambia la capacidad declarada de «Exposición al ruido». |
| Información de la batería | Sensores y entrenamientos | Cambia la capacidad declarada de «Información de la batería». |
| Entrenamientos de natación | Sensores y entrenamientos | Cambia la capacidad declarada de «Entrenamientos de natación». |
| Código de región | Siri e inteligencia | Modifica solo RegionCode; conserva el sufijo de región de venta. |
| Región de ventas | Siri e inteligencia | Modifica solo el sufijo de región de venta; las herramientas de fábrica pueden detectar una discrepancia. |
| Apple Intelligence / Siri AI | Siri e inteligencia | Cambia la capacidad; Siri AI requiere watchOS 27, un reloj compatible y un iPhone enlazado con Apple Intelligence. |
| Siri en el dispositivo | Siri e inteligencia | Cambia la capacidad declarada de «Siri en el dispositivo». |
| Inteligencia de audio | Siri e inteligencia | Cambia la capacidad de inteligencia de audio; la app indica que requiere hardware Series 12 / Ultra 4. |
| Copia de seguridad inicial | Copias de seguridad MG | Crea la copia inicial protegida, que no se puede sobrescribir desde la app. |
| Copia de seguridad manual | Copias de seguridad MG | Guarda manualmente el MobileGestalt actual. |
| Copia de seguridad automática | Copias de seguridad MG | Crea una copia automática antes de escribir o restaurar MG. |
| Restaurar MG | Copias de seguridad MG | Guarda primero el MG actual y restaura la copia seleccionada. Reinicia el reloj. |
| Reiniciar Carousel | Utilidades | Reinicia el proceso de interfaz del reloj para volver a cargar los cambios. |

Los indicadores no añaden pantallas, sensores, hardware de audio ni acceso a servicios que falten. Los menús de región y resolución ofrecen valores predefinidos. Los errores de escritura aparecen en la app.

## Créditos

Este proyecto incorpora código de [Gester](https://github.com/sasobhabha/Gester). Úsalo bajo tu propia responsabilidad.
