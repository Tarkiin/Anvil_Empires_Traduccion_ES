# Traducción al español de Anvil Empires

Traducción comunitaria **no oficial** de *Anvil Empires* al español de España.
Esta traducción solo esta creada y mantenida por **Tarkin**

## Estado actual

- Compatible con **Anvil Empires Pre-Alpha, build 00235**.
- Incluye 1053 entradas de localización: menús, opciones, tutoriales, objetivos, acciones, avisos, topónimos y buena parte de la interfaz de juego.
- Ya traduce `Town Keep`, `Town Keep Gate Front` y `Reinforced Wood Planks`.
- Ya traduce la plata, la fibra, la fibra resistente, las semillas de cáñamo y la explicación de cambio de avatar.
- Ya traduce las explicaciones de salud, resistencia y hambre, además del panel de la caja mágica.
- Algunos nombres y descripciones de objetos todavía pueden aparecer en inglés mientras se completa el catálogo de recursos.
- El rótulo `Actions` de la caja mágica puede seguir apareciendo en inglés porque el juego sustituye en ejecución el texto localizable por una cadena interna.
- La traducción puede dejar de funcionar después de una actualización del juego. Publicaremos una versión nueva cuando sea necesario.

## Progreso de la traducción

- **1053/1053 entradas localizables identificadas** están incluidas en español (**100 %**).
- No quedan entradas pendientes dentro del conjunto identificado y revisado para esta versión.
- Este recuento corresponde a la **build 00235** y es provisional: el total aumenta cuando se localizan nuevos textos dentro de recursos cocinados que el extractor no puede interpretar automáticamente.
- No se cuentan como pendientes los textos internos del editor de Unreal, notas de desarrollo, datos de prueba ni cadenas binarias inválidas que nunca aparecen al jugar.

### Qué falta por traducir

- Textos aún no identificados que puedan estar almacenados dentro de Blueprints cocinados u otros recursos que el extractor no interpreta automáticamente.
- Cadenas que el juego genera o sustituye durante la ejecución, como `Actions` en la caja mágica.
- Cualquier texto nuevo que aparezca después de una actualización del juego.

## Instalación automática

1. Cierra Anvil Empires.
2. Descarga solamente `Instalar_Traduccion.bat` desde GitHub. No tendrás que volver a descargar manualmente los parches posteriores.
3. Ejecuta `Instalar_Traduccion.bat`. El BAT consulta la última versión publicada en la rama `main`, descarga los archivos correspondientes y comprueba su SHA-256.
4. Acepta la solicitud de permisos de Windows. Es necesaria para copiar el PAK dentro de `Program Files`.
5. Cuando aparezca el mensaje de instalación completada, abre el juego desde Steam.

Cada revisión se descarga desde un único commit de GitHub para impedir que se mezclen archivos de versiones distintas. El PAK verificado queda guardado en caché, por lo que ejecutar de nuevo el BAT no vuelve a descargarlo si ya tienes la versión más reciente. Si GitHub no está disponible, el instalador puede reutilizar la última copia verificada guardada en el equipo.

El instalador busca la biblioteca de Steam, comprueba que el ejecutable corresponde a la build 00235, copia el parche y configura el idioma `es`. Si encuentra una versión anterior del parche o un archivo de configuración, crea una copia de seguridad. Las descargas verificadas y las copias de seguridad se guardan dentro de:

```text
%LOCALAPPDATA%\AnvilSpanishTranslation
```

El repositorio completo continúa disponible mediante **Code > Download ZIP** para quienes prefieran la instalación manual o quieran conservar todos los archivos.

## Instalación manual

1. Cierra el juego.
2. Copia `AnvilSpanish_P.pak` en:

```text
C:\Program Files (x86)\Steam\steamapps\common\Anvil Playtest\Anvil\Content\Paks
```

Si Steam está instalado en otra unidad, utiliza la carpeta equivalente de esa biblioteca.

1. Abre o crea este archivo:

```text
%LOCALAPPDATA%\Anvil\Saved\Config\Windows\Engine.ini
```

1. Añade al final:

```ini
[Internationalization]
Culture=es
```

## Desinstalación

Cierra el juego y ejecuta `Desinstalar_Traduccion.bat`. El desinstalador guarda una copia, elimina solamente `AnvilSpanish_P.pak` y restaura el valor anterior de `Culture` cuando la traducción se instaló con el instalador incluido. No borra partidas ni archivos originales del juego. Por seguridad, se negará a borrar el PAK si no coincide con esta versión del parche.

También puedes desinstalarla eliminando manualmente:

```text
Anvil\Content\Paks\AnvilSpanish_P.pak
```

## Comprobación de integridad

El SHA-256 oficial del PAK incluido en esta versión está en `SHA256SUMS.txt`. El instalador lo comprueba antes de copiar el archivo.

## Problemas y textos sin traducir

Al informar de un texto sin traducir, adjunta una captura y explica en qué menú, edificio u objeto aparece. No incluyas datos personales ni credenciales en la captura.

## Aviso

Este proyecto es comunitario y no está afiliado, aprobado ni mantenido por Siege Camp. *Anvil Empires* y sus recursos pertenecen a sus respectivos propietarios. Este repositorio distribuye únicamente el parche necesario para aplicar la traducción. Consulta `NOTICE.txt` y `LICENSE` para conocer el alcance de los permisos.
