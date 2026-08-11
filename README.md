# Traducción al español de Anvil Empires

Traducción comunitaria **no oficial** de *Anvil Empires* al español de España.

## Estado actual

- Compatible con **Anvil Empires Pre-Alpha, build 00235**.
- Incluye 973 entradas de localización: menús, opciones, tutoriales, objetivos, acciones, avisos y buena parte de la interfaz de juego.
- Algunos nombres internos de edificios y objetos todavía pueden aparecer en inglés, por ejemplo `Town Keep`.
- La traducción puede dejar de funcionar después de una actualización del juego. Publicaremos una versión nueva cuando sea necesario.

## Instalación automática

1. Cierra Anvil Empires.
2. Descarga el repositorio desde **Code > Download ZIP** y extrae todo el contenido.
3. Ejecuta `Instalar_Traduccion.bat` y acepta la solicitud de permisos de Windows. Es necesaria para copiar el PAK dentro de `Program Files`.
4. Cuando aparezca el mensaje de instalación completada, abre el juego desde Steam.

El instalador busca la biblioteca de Steam, copia el parche y configura el idioma `es`. Si encuentra una versión anterior del parche o un archivo de configuración, crea una copia de seguridad en:

```text
%LOCALAPPDATA%\AnvilSpanishTranslation\Backups
```

## Instalación manual

1. Cierra el juego.
2. Copia `AnvilSpanish_P.pak` en:

```text
C:\Program Files (x86)\Steam\steamapps\common\Anvil Playtest\Anvil\Content\Paks
```

Si Steam está instalado en otra unidad, utiliza la carpeta equivalente de esa biblioteca.

3. Abre o crea este archivo:

```text
%LOCALAPPDATA%\Anvil\Saved\Config\Windows\Engine.ini
```

4. Añade al final:

```ini
[Internationalization]
Culture=es
```

## Desinstalación

Cierra el juego y ejecuta `Desinstalar_Traduccion.bat`. El desinstalador guarda una copia y elimina solamente `AnvilSpanish_P.pak`; no borra partidas ni archivos originales del juego. Por seguridad, se negará a borrar el archivo si no coincide con esta versión del parche.

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
