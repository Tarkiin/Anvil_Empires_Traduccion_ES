# Traducción al español de Anvil Empires

Traducción comunitaria **no oficial** de *Anvil Empires* al español de España.
Esta traducción solo esta creada y mantenida por **Tarkin**

## Estado actual

- Compatible con **Anvil Empires Pre-Alpha, build 00235**.
- Incluye 3012 identidades localizables jugables revisadas: menús, opciones, tutoriales, objetivos, acciones, avisos, topónimos, objetos, estructuras, recursos, armas, armaduras y vehículos.
- Ya traduce `Town Keep`, `Town Keep Gate Front` y `Reinforced Wood Planks`.
- Ya traduce la plata, la fibra, la fibra resistente, las semillas de cáñamo y la explicación de cambio de avatar.
- Ya traduce las explicaciones de salud, resistencia y hambre, además del panel de la caja mágica.
- Ya traduce la espada corta de bronce, las flechas rudimentarias, el cuchillo de pedernal, materiales básicos, carros, caravanas y bases de roca cuadradas.
- Se han incorporado 42 identidades FText adicionales y se han corregido nueve variantes de topónimos que permanecían en inglés.
- Ya se traducen las descripciones breves del tablón de recompensas, la gestión de la Casa, la lista de jugadores cercanos y la organización del inventario.
- Ya se traducen también la entrega de vehículos, la ayuda de recuperación del avatar, las raciones auxiliares, la explicación general de los avatares, el límite de estatus urbano y el acceso al almacén privado.
- Corregida la plantilla de equipo de facción para mostrar solo `Equipo de Paganos`, sin la etiqueta `<img>` que el juego dejaba visible al localizar su ID interno.
- Todavía pueden aparecer cadenas remotas, dinámicas, keyless, pertenecientes a otros targets LOCRES o con un historial FText diferente.
- El rótulo `Actions` de la caja mágica puede seguir apareciendo en inglés porque el juego sustituye en ejecución el texto localizable por una cadena interna.
- El juego reutiliza `DamageTypeFooterText` con dos fuentes distintas; esta versión prioriza la plantilla de equipo y omite su icono incompatible, por lo que la variante de daño puede volver al inglés en otro contexto.
- El juego reutiliza `AvatarRecoveryTips` para tiendas y camas; esta versión prioriza la variante de tiendas observada en pantalla.
- La traducción puede dejar de funcionar después de una actualización del juego. Publicaremos una versión nueva cuando sea necesario.

## Progreso de la traducción

- Se han identificado **3012 identidades localizables jugables** en la build actual.
- **2855** tienen una traducción distinta de la fuente inglesa; las **157** coincidencias restantes se han revisado como nombres propios conservados, valores invariantes o textos técnicos/de muestra.
- Se han incorporado 1936 claves suplementarias; varias variantes de objetos y estructuras reutilizan la misma fuente con GUID diferentes.
- Este recuento corresponde a la **build 00235** y es provisional: incluye los FText Base recuperables del PAK completo y las claves nativas ya identificadas en el ejecutable.
- Se han excluido del denominador 194 entradas internas/TODO/editor y 57 valores de muestra o contadores. Tampoco se cuentan cadenas remotas del servidor, keyless/invariant ni historiales FText todavía no interpretados.

### Qué falta por traducir

- Claves nativas o historiales FText que todavía no se hayan podido identificar automáticamente.
- Cadenas que el juego genera o sustituye durante la ejecución, como `Actions` en la caja mágica.
- Ocho mensajes FString de voz y trece variantes FText que comparten identidad con otra fuente; no pueden resolverse de forma fiable añadiendo otra fila al LOCRES principal.
- Cincuenta y ocho mensajes potencialmente visibles de Engine y servicios online que pertenecen a targets LOCRES separados y requieren un parche y pruebas específicos.
- Cualquier texto nuevo que aparezca después de una actualización del juego.

## Instalación automática

1. Cierra Anvil Empires.
2. Descarga solamente el instalador desde este enlace:

   **[Descargar Instalar_Traduccion.bat](https://github.com/Tarkiin/Anvil_Empires_Traduccion_ES/releases/latest/download/Instalar_Traduccion.bat)**

   Es un archivo adjunto de GitHub Releases: el navegador lo descarga directamente en vez de mostrar su código. No tendrás que volver a descargar manualmente los parches posteriores.
3. Ejecuta `Instalar_Traduccion.bat`. El BAT consulta la última versión publicada en la rama `main`, descarga los archivos correspondientes y comprueba su SHA-256.
4. Acepta la solicitud de permisos de Windows. Es necesaria para copiar el PAK dentro de `Program Files`.
5. Cuando aparezca el mensaje de instalación completada, abre el juego desde Steam.

Cada revisión se descarga desde un único commit de GitHub para impedir que se mezclen archivos de versiones distintas. El PAK verificado queda guardado en caché, por lo que ejecutar de nuevo el BAT no vuelve a descargarlo si ya tienes la versión más reciente. Si GitHub no está disponible, el instalador puede reutilizar la última copia verificada guardada en el equipo.

El instalador busca la biblioteca de Steam, comprueba que el ejecutable corresponde a la build 00235, copia el parche y configura el idioma `es`. Si encuentra una versión anterior del parche o un archivo de configuración, crea una copia de seguridad. Las descargas verificadas y las copias de seguridad se guardan dentro de:

```text
%LOCALAPPDATA%\AnvilSpanishTranslation
```

El repositorio completo continúa disponible mediante **Code > Download ZIP** para quienes prefieran la instalación manual o quieran conservar todos los archivos.

## Publicar una versión

Cada etiqueta con formato `v...` crea o actualiza automáticamente una GitHub Release y adjunta `Instalar_Traduccion.bat`. El enlace de descarga anterior siempre apunta al BAT de la Release más reciente.

Ejemplo para publicar una versión después de integrar y verificar los cambios en `main`:

```powershell
git switch main
git pull --ff-only
git tag v0.3.3
git push origin v0.3.3
```

También se puede ejecutar manualmente el flujo **Publicar instalador descargable** desde la pestaña **Actions** de GitHub, indicando una versión como `v0.3.3`.

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

Cierra el juego y ejecuta `Desinstalar_Traduccion.bat`. El desinstalador guarda una copia, elimina solamente `AnvilSpanish_P.pak` y restaura el valor anterior de `Culture` cuando la traducción se instaló con el instalador incluido. No borra partidas ni archivos originales del juego. Por seguridad, se negará a borrar el PAK si no coincide con esta versión del parche.

También puedes desinstalarla eliminando manualmente:

```text
Anvil\Content\Paks\AnvilSpanish_P.pak
```

## Comprobación de integridad

El SHA-256 oficial del PAK incluido en esta versión está en `SHA256SUMS.txt`. El instalador lo comprueba antes de copiar el archivo.

## Problemas y textos sin traducir

Al informar de un texto sin traducir, adjunta una captura y explica en qué menú, edificio u objeto aparece.

## Aviso

Este proyecto es comunitario y no está afiliado, aprobado ni mantenido por Siege Camp. *Anvil Empires* y sus recursos pertenecen a sus respectivos propietarios. Este repositorio distribuye únicamente el parche necesario para aplicar la traducción. Consulta `NOTICE.txt` y `LICENSE` para conocer el alcance de los permisos.
