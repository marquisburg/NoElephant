@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist "bin\mettle.exe" (
  echo error: bin\mettle.exe not found.
  echo Place the Mettle compiler and stdlib under bin\ before building.
  exit /b 1
)

if not exist "build" mkdir "build"

echo Building db_demo...
bin\mettle.exe --build -s ^
  examples\db_demo\db_demo.mettle ^
  -o build\db_demo.exe ^
  -I src\mdb ^
  --stdlib bin\stdlib

if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

echo.
echo Built build\db_demo.exe
echo Run: build\db_demo.exe ^<database_dir^>
