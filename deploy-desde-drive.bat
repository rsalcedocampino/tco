@echo off
setlocal
title Sincronizar Drive -> Local y publicar (TCO Ruta)
cd /d "%~dp0"

REM === Carpeta de trabajo (Drive) donde editas los archivos ===
set "DRIVE=H:\Mi unidad\0.0 E-MOBILITY PERSONAL\5.0 Excel Estudios para PPT\000 Data de Estadisticas\Web TCO Precios EV - No borrar"

REM === Verificar que este .bat vive dentro de un repo git ===
if not exist ".git" (
  echo [ERROR] Este .bat debe estar dentro de la carpeta del repo:
  echo   C:\Users\SERVER10100\Desktop\Pagina Estadisticas - NO BORRAR\TCO Ruta
  echo.
  pause
  exit /b 1
)

REM === Verificar que la carpeta de Drive existe ===
if not exist "%DRIVE%\" (
  echo [ERROR] No se encuentra la carpeta de Drive:
  echo   %DRIVE%
  echo Revisa que Google Drive este montado en H:
  echo.
  pause
  exit /b 1
)

echo Copiando archivos de la web desde Drive...
robocopy "%DRIVE%" "%~dp0." index.html ruta.html calculadora-tco.html CNAME README.md "logo y nombre - copia.png" /NFL /NDL /NJH /NJS /NP
echo.

echo Publicando en GitHub...
git add -A
git diff --cached --quiet
if not errorlevel 1 (
  echo No hay cambios que publicar.
  echo.
  pause
  exit /b 0
)
git commit -m "Actualiza web TCO"
if errorlevel 1 (
  echo [ERROR] Fallo al confirmar los cambios.
  echo.
  pause
  exit /b 1
)
git push
if errorlevel 1 (
  echo [ERROR] Fallo al subir. Revisa tu internet o pega el token tco-deploy como contrasena.
  echo.
  pause
  exit /b 1
)
echo.
echo [OK] Publicado. En 1-2 minutos estara en https://tco.energiasfuturo.com
echo.
pause
