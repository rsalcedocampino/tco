# Contexto del proyecto — Web TCO / Precios EV

Documento de referencia para mantener la calculadora TCO y la página de ruta.
Es la fuente de verdad del proyecto: si algo cambia (rutas, flujo de deploy, datos),
actualizar este archivo.

_Última actualización: integración del catálogo Maestro Unificado (672 EV + 2.702 ICE
únicos) y 645 cargadores en ruta.html, logos incrustados, y migración del deploy a
carpeta local (fin del problema de Git dentro de Google Drive)._

---

## 1. Qué es

- **Sitio:** Calculadora TCO (Costo Total de Propiedad) Eléctrico vs Combustión, para Chile.
- **URL:** https://tco.energiasfuturo.com
- **Hosting:** GitHub Pages, repo `rsalcedocampino/tco` (rama `main`). Gratis, siempre online.
- **Marca:** Energías Futuro (colabora AVEC).

## 2. Páginas del sitio

- **`index.html`** — la calculadora TCO principal (~873 KB, usa Chart.js).
  URL: https://tco.energiasfuturo.com
- **`ruta.html`** — "Calcula el costo de tu ruta": origen/destino en mapa, elige auto
  eléctrico y lo compara con uno a combustión (energía, peajes, mantención, CO₂) y muestra
  puntos de carga compatibles. Usa Leaflet + OpenStreetMap, Nominatim y OSRM.
  URL: https://tco.energiasfuturo.com/ruta.html
- **`calculadora-tco.html`** — copia/variante de respaldo (se publica pero no es la principal).
- **`CNAME`** — define el dominio tco.energiasfuturo.com.
- **`logo y nombre - copia.png`** — logo Energías Futuro (archivo fuente; ver nota de logos).
- **`README.md`** — texto del repo (no lo usa la página).

## 3. Cómo funciona la data (IMPORTANTE)

La web **NO lee ningún Excel ni JSON en vivo**. Todos los datos (vehículos, cargadores,
precios, tasación, etc.) van **incrustados dentro de `index.html` y `ruta.html`** como
variables JavaScript.

Flujo de actualización:

    Excel fuente  ->  se regeneran las listas  ->  se incrustan en el HTML  ->  se publica

Los Excel y JSON de la carpeta son la **fuente** y el **respaldo**, no se suben al sitio.

## 4. Qué hoja alimenta qué

**Archivo maestro: `Vehiculos_Homologados_TCO.xlsx`**

- **Maestro Unificado** (hoja más completa, ~7.085 filas) -> catálogo de vehículos:
  `tipo` (BEV / ICE / MHEV / PHEV / HEV / FCEV), marca, modelo, version, `año`,
  combustible, `km_kwh` (consumo EV en km/kWh), `km_l` (rendimiento combustión), precio, co2,
  mant_anual, seguro_anual, tasacion_2026, permiso_2026, impuesto verde (iv_utm), etc.
- **Precios Energia** -> precios de electricidad y combustibles (CLP/kWh, CLP/L).
- **Curva Tasacion-Permiso SII** -> depreciación y permiso de circulación por año.
- **Parametros** -> UTM y supuestos base.

**Archivo cargadores: `mapa_interactivo_cargadores_chile.xlsx`**

- **Conectores** (hoja usada) -> puntos de carga: lat/lon, estándar de conector
  (Tipo 2 / CCS 2 / CHAdeMO / GB-T...), potencia máx (kW), precio (CLP/kWh), operador,
  disponibilidad. 2.320 conectores que se agrupan por ubicación (`location_id`) en ~645 sitios
  (hoja Ubicaciones = 645 filas).

## 5. Listas actualmente publicadas en ruta.html

- **Eléctricos (BEV):** 672 modelos únicos (de Maestro Unificado, tipo = BEV, con km_kwh;
  vienen de 899 filas crudas que se deduplican por marca/modelo/año).
- **Combustión (ICE):** 2.702 modelos únicos (tipo = ICE, con km_l; de 4.926 filas crudas).
- **Cargadores:** 645 ubicaciones (hoja Conectores/Ubicaciones).
- Selección por filtros encadenados: Marca -> Modelo -> Año -> Conector (EV) / Combustible (ICE).

### Reglas exactas de transformación (para regenerar idéntico)

Al regenerar las listas de ruta.html desde el Maestro Unificado:

1. **Filtro BEV:** `tipo == "BEV"` y `km_kwh > 0`.
   **Filtro ICE:** `tipo == "ICE"` y `km_l > 0`.
2. **Nombres:** `marca` y `modelo` en **Title Case** (Python `.title()`; ej. "BMW" -> "Bmw",
   "A6 TRON" -> "A6 Tron").
3. **Dedup:** una fila por clave `(marca, modelo, año)`, conservando la **primera aparición**
   en el orden de la hoja.
4. **Consumo EV:** el campo `kwh` de ruta.html es **kWh/100 km = round(100 / km_kwh, 1)**
   (unidad invertida respecto al Excel, que trae km/kWh).
5. **Rendimiento ICE:** el campo `kml` = `round(km_l, 1)`.
6. **Combustible ICE (`f`):** `Gasolina -> "bencina"`, `Diésel -> "diesel"`,
   `Gasolina/GLP -> "bencina"`.
7. **Conector EV (ac/dc):** por defecto `ac="Tipo 2"`, `dc="CCS2"`.
   **Excepción Nissan Leaf** -> `ac="Tipo 1"`, `dc="CHAdeMO"`.
8. **Orden final:** alfabético por `(marca, modelo, año)` ascendente.

Formato de cada fila (JSON compacto, sin espacios):

    BEV: {"marca":"Audi","modelo":"A6 Tron","anio":2025,"kwh":12.8,"ac":"Tipo 2","dc":"CCS2"}
    ICE: {"marca":"Aston Martin","modelo":"Aston Martin","anio":2021,"kml":8.1,"f":"bencina"}

Variables en ruta.html: `var BEV=[...]`, `var ICE=[...]`, `var CARGADORES=[...]`.
Cargadores: `[lat, lon, "nombre", "operador", kW, precio$/kWh, disponible(0/1), bits_conector]`
donde bits usa `CNAME=[[1,'Tipo 2'],[2,'CCS2'],[4,'CHAdeMO'],[8,'Tipo 1'],[16,'GB/T'],[32,'Tesla'],[64,'CCS1']]`.

### Conector exacto por modelo (opcional)
El maestro NO trae el conector por modelo; se asigna por defecto (regla 7). Si se quiere el
conector real por modelo, la fuente es `Catalogo_Maestro_EV_Chile.xlsx`, hoja "Maestro EVs"
(batería, autonomía, carga AC/DC, Conector 1/2). No está integrado hoy.

## 6. Precios de energía (index.html y ruta.html)

Referencia mar-2026, ya cargados en ambos archivos:
- Electricidad (RM): 150 CLP/kWh · Norte: 160 · Sur: 145
- Bencina 93: 1.539 · 95: 1.561 · 97: 1.582 CLP/L
- Diésel: 1.512 CLP/L
- Pérdidas de carga: 10 %

En `index.html` son los `value=""` de los inputs (`pkwh`, `pbenc`, `pdie`, `utm`, `perdidas`).
En `ruta.html` están en `var FUEL={bencina:{p:1539,...},diesel:{p:1512,...}}`.

## 7. Ajustes de la sección "3 · Extras (opcional)" en ruta.html

Los tres campos arrancan en **cero** al entrar a la web:
- Peaje por viaje ida (CLP): 0
- Mantención eléctrico (CLP/km) `id="mBev"`: 0  (antes 25)
- Mantención combustión (CLP/km) `id="mIce"`: 0  (antes 45)

La mantención solo se suma al resultado cuando el usuario escribe un valor.

## 8. Logos (incrustados en ruta.html)

En `ruta.html` **ambos logos van incrustados como base64** (data URI), así el archivo es
autocontenido y se ve aunque se abra suelto:
- Logo Energías Futuro: antes `src="logo%20y%20nombre%20-%20copia.png"` (archivo externo) ->
  ahora `data:image/png;base64,...`.
- Logo AVEC: antes `src="https://www.avec.cl/.../logo.png"` (URL externa) -> ahora base64.
  Fuentes de los PNG: `logo y nombre - copia.png` y `Logo_AVEC.png`.

Nota: `index.html` **todavía apunta al PNG externo** de Energías Futuro (no está incrustado).
Si se quiere, se puede incrustar también ahí.

## 9. Publicación (deploy) — FLUJO ACTUAL

> **REGLA DE ORO: Git NO funciona dentro de Google Drive.** Drive es un disco virtual que
> sincroniza y bloquea los archivos internos de `.git`, y git se cuelga ("no pasa nada",
> "update_ref failed", "Function not implemented"). Por eso el repo de trabajo vive en un
> **disco local**, y Drive se usa solo para editar/respaldar. Nunca poner la carpeta `.git`
> dentro de Drive.

**Dos carpetas, roles distintos:**

- **Edición (Google Drive, unidad H:):**
  `H:\Mi unidad\0.0 E-MOBILITY PERSONAL\5.0 Excel Estudios para PPT\000 Data de Estadisticas\Web TCO Precios EV - No borrar`
  Aquí viven los Excel fuente y aquí se editan/guardan los HTML.

- **Repo git / deploy (disco local, Escritorio):**
  `C:\Users\SERVER10100\Desktop\Pagina Estadisticas - NO BORRAR\TCO Ruta`
  Es el clon de GitHub. Git corre sano aquí. (El Escritorio de este PC es LOCAL, no está
  sincronizado con OneDrive — verificado.)

**Puente entre ambas: `deploy-desde-drive.bat`** (vive en la carpeta local `TCO Ruta`).
Con doble clic: copia con robocopy solo los archivos web desde Drive -> carpeta local
(index.html, ruta.html, calculadora-tco.html, CNAME, README.md, logo) **sin tocar `.git`**,
y hace `git add / commit / push`. En 1-2 min queda online.

Flujo normal de actualización:
1. Editar/guardar los HTML en la carpeta de **Drive**.
2. Doble clic en `deploy-desde-drive.bat` (en `TCO Ruta`).
3. Listo: publicado en https://tco.energiasfuturo.com

Alternativa manual (desde `TCO Ruta`, en cmd):

    git add -A
    git commit -m "descripcion"
    git push

**Token:** el push pide autenticación la primera vez -> usuario `rsalcedocampino`,
contraseña = token `tco-deploy` (fine-grained PAT). El token NO se guarda en archivos; lo
recuerda Windows Credential Manager. Se regenera en GitHub -> Settings -> Developer Settings
-> Fine-grained tokens (permisos: Contents = Read and write, Metadata = Read-only).

**`.gitignore`** (en el repo) excluye de la publicación: el propio `deploy-desde-drive.bat`,
`Vehiculos_Homologados_TCO.xlsx`, `web_data/`, `COMO-PUBLICAR.txt`, `README-deploy.txt`,
`plan-fuentes-tco.md`, `calculadora-tco.html` (si aplica) y el archivo basura `Local`.

## 10. Servicios externos que carga la web (no son archivos)

- **Chart.js** (CDN) — gráficos de index.html.
- **Leaflet + tiles de OpenStreetMap** — mapa de ruta.html.
- **Nominatim** (OpenStreetMap) — autocompletado de direcciones.
- **OSRM** — trazado de la ruta.
- Sin API keys. Los logos ya NO dependen de avec.cl (van incrustados). OpenChargeMap fue
  retirado; los cargadores son offline desde el Excel.

## 11. Archivos fuente (viven en la carpeta de Drive)

- `Vehiculos_Homologados_TCO.xlsx`   (catálogo + precios + SII + parámetros)
- `mapa_interactivo_cargadores_chile.xlsx`  (cargadores, hoja Conectores)
- (opcional) `Catalogo_Maestro_EV_Chile.xlsx`  (conector/batería exactos por modelo EV)

## 12. REGLA para actualizar la web con ayuda de Claude

El entorno de código de Claude es un contenedor Linux aislado: **NO puede leer la unidad H:
(Google Drive) ni ninguna ruta de Windows.** Solo ve lo que se sube al chat.

Para actualizar listas/precios:
1. El usuario **arrastra al chat** los Excel fuente y los HTML a editar
   (`ruta.html` / `index.html`).
2. Claude procesa los Excel, regenera las listas según las reglas de la sección 5 y las
   incrusta en el HTML.
3. Claude entrega el HTML nuevo; el usuario lo guarda en la carpeta de **Drive** y publica
   con `deploy-desde-drive.bat`.

---
