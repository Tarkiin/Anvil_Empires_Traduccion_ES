# Historial de cambios

## 0.3.3 — 2026-08-12

- Añadidas las cuatro identidades nativas omitidas para las descripciones del tablón de recompensas, la gestión de la Casa, la lista de jugadores cercanos y la organización del inventario.
- Corregida la plantilla de equipo de facción para conservar el identificador de icono y mostrar `Equipo de Paganos` en vez de la etiqueta `<img>` literal.
- Corregida la compilación de saltos `CRLF` para que se apliquen las traducciones multilínea de la introducción pagana, la piedra angular de la hacienda y los tramos de acueducto.
- Añadidas las descripciones omitidas de entrega de vehículos, recuperación del avatar, raciones auxiliares, avatares, límite de estatus urbano y almacén privado.
- Añadidas las indicaciones omitidas de condición física, combate cuerpo a cuerpo, combate a distancia, tala y minería.
- Traducido el aviso omitido `Space is occupied` mediante su identidad nativa exacta.
- Ampliado el conjunto identificado a 3012 identidades jugables, con 2855 traducciones distintas de la fuente y 157 coincidencias revisadas.
- Regenerado y validado el PAK con 3024 entradas LOCRES y únicamente los dos archivos de localización previstos.

## 0.3.2 — 2026-08-12

- Añadido un sistema de GitHub Releases que publica `Instalar_Traduccion.bat` como archivo descargable.
- Añadido un enlace estable que siempre descarga el instalador de la Release más reciente sin mostrar el código ni exigir descargar el repositorio.
- Incorporadas 42 identidades FText nuevas: 34 cadenas nativas y 8 textos de chat y señalización.
- Corregidas nueve identidades de topónimos que el contador anterior daba por traducidas aunque seguían en inglés.
- Sustituido el porcentaje engañoso por un control auditable: 2997 identidades jugables, 2841 traducciones distintas de la fuente y 156 coincidencias revisadas.
- Documentados por separado los textos keyless, las colisiones de identidad y 58 mensajes pertenecientes a otros targets LOCRES.

## 0.3.1 — 2026-08-12

- Auditoría completa del PAK: 2955 entradas localizables identificadas y 2955 verificadas en español (100 % del conjunto identificado).
- Traducidas 1884 claves nuevas correspondientes a 1125 fuentes inglesas distintas: objetos, estructuras, recursos, armas, armaduras, vehículos, categorías y textos narrativos.
- Resueltos los 2 conflictos donde la fuente almacenada no coincidía con el FText exacto del asset.
- Excluidas del porcentaje 194 entradas internas/TODO/editor y 57 muestras o contadores que no representan texto jugable.
- Añadido un inventario reproducible por clave, fuente y ruta para controlar futuras traducciones y cambios de build.
- Corregidas 73 claves de Blueprints con namespace vacío que se habían compilado con el prefijo literal `::` y no eran reconocidas por el juego.
- Traducidos la espada corta de bronce, las flechas rudimentarias para arco corto, el cuchillo de pedernal y sus descripciones.
- Traducidos los tablones de madera, las ramas, el pedernal, la grasa animal, las manos y el martillo de hierro.
- Traducidos el carro de mano, la caravana, sus descripciones de construcción y cuatro variantes de la base de roca cuadrada.
- Regenerado el PAK con las claves FText exactas extraídas de los Blueprints visuales.

## 0.3.0 — 2026-08-12

- Traducción ampliada a 1053 entradas de localización.
- Completado el conjunto identificado: 1053/1053 entradas localizables traducidas (100 %), sin entradas conocidas pendientes en esta versión.
- Traducidos los topónimos y rótulos del mapa identificados, manteniendo como nombres propios los términos de ambientación que no tienen equivalente oficial en español.
- Traducidos `Town Keep`, `Town Keep Gate Front` y `Reinforced Wood Planks`.
- Traducidos los tres niveles del arco corto, sus descripciones y el requisito de flechas.
- Traducidos los picos de pedernal, bronce y hierro, junto con sus descripciones.
- Traducidos la plata, el mineral de plata, el montón de plata y sus descripciones.
- Traducidas la fibra, la fibra resistente, la semilla de cáñamo y sus descripciones.
- Traducida la explicación del botón para cambiar de avatar.
- Traducidas las explicaciones de los indicadores de salud, resistencia y hambre.
- Traducidos el nombre, la descripción y el aviso de la caja mágica.
- Añadidos avisos localizables de conexión a Anvil Services y estado del chat de voz.
- Corregidos los identificadores internos de iconos de daño para evitar que aparezcan etiquetas `<img>` sin procesar.
- Añadida validación estricta de la build 00235 antes de instalar.
- Mejorada la reversión de `Engine.ini`, la elevación de permisos y la seguridad de los archivos temporales.
- Convertido `Instalar_Traduccion.bat` en un instalador online que descarga automáticamente la última revisión publicada en GitHub.
- Añadidas fijación por commit, verificación SHA-256, caché local y reutilización segura de la última versión verificada cuando GitHub no está disponible.

## 0.2.0 — 2026-08-12

- Traducción ampliada a 973 entradas de localización.
- Añadidos tutoriales, objetivos, acciones y mensajes de interacción de la partida.
- Corregida la lectura de textos con varias líneas durante la compilación.
- Añadidos instalador, desinstalador, copias de seguridad y verificación SHA-256.
- Compatibilidad comprobada con Anvil Empires Pre-Alpha build 00235.

## 0.1.0 — 2026-08-11

- Primera prueba funcional de la interfaz principal en español.
- Añadidos menús, opciones y textos básicos de conexión.
