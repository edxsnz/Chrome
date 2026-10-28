@echo off
setlocal
chcp 65001 >nul
title Atualizar JT Express

rem ===== De onde baixa (seu GitHub) =====
set "REPO=https://raw.githubusercontent.com/edxsnz/Chrome/main"
rem ======================================

rem Pasta Documentos de quem estiver usando (funciona em qualquer PC,
rem inclusive quando os Documentos ficam no OneDrive)
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; [Environment]::GetFolderPath('MyDocuments')"`) do set "DOCS=%%D"
if not defined DOCS set "DOCS=%USERPROFILE%\Documents"
if not exist "%DOCS%" goto erro

set "ZIP=%DOCS%\jt-express-extensao.zip"
set "PASTA=%DOCS%\jt-express-extensao"
set "EXE=%DOCS%\JT-Bipe.exe"

echo.
echo Documentos: %DOCS%
echo.
echo [1/4] Baixando a extensao e o JT-Bipe...
curl -fsSL --retry 2 -o "%ZIP%" "%REPO%/jt-express-extensao.zip?t=%RANDOM%%RANDOM%" || goto erro
curl -fsSL --retry 2 -o "%EXE%.novo" "%REPO%/JT-Bipe.exe?t=%RANDOM%%RANDOM%" || goto erro
rem confere se o .zip veio inteiro (tem a extensao dentro) antes de apagar a antiga
tar -tf "%ZIP%" | findstr /i /c:"jt-express-extensao/manifest.json" >nul || goto erro

echo [2/4] Trocando a extensao (apaga a pasta antiga e extrai a nova)...
if exist "%PASTA%" rmdir /s /q "%PASTA%"
if exist "%PASTA%" goto erro_pasta
tar -xf "%ZIP%" -C "%DOCS%" || goto erro
if not exist "%PASTA%\manifest.json" goto erro
del /q "%ZIP%"

echo [3/4] Trocando o JT-Bipe (fecha ele e o adb)...
set "ESTAVA=0"
tasklist /fi "imagename eq JT-Bipe.exe" | find /i "JT-Bipe.exe" >nul && set "ESTAVA=1"
taskkill /im JT-Bipe.exe /f >nul 2>&1
if exist "%LOCALAPPDATA%\JTBipe\adb\adb.exe" "%LOCALAPPDATA%\JTBipe\adb\adb.exe" kill-server >nul 2>&1
taskkill /im adb.exe /f >nul 2>&1
timeout /t 1 /nobreak >nul
move /y "%EXE%.novo" "%EXE%" >nul || goto erro

echo [4/4] Pronto!
if "%ESTAVA%"=="1" start "" "%EXE%"
echo.
echo   Extensao: %PASTA%
echo   JT-Bipe:  %EXE%
echo.
echo No Chrome: abra chrome://extensions e clique em recarregar (seta em circulo)
echo na extensao JT Express. Na 1a vez: "Carregar sem compactacao" e escolha a
echo pasta %PASTA%
echo.
pause
exit /b 0

:erro_pasta
echo.
echo ERRO: nao consegui apagar a pasta antiga (algum arquivo dela esta aberto?).
echo Feche o que estiver usando a pasta e rode de novo.
goto fim_erro

:erro
echo.
echo ERRO: nao consegui terminar. Confira a internet e se os arquivos estao no GitHub:
echo   %REPO%/jt-express-extensao.zip
echo   %REPO%/JT-Bipe.exe

:fim_erro
if exist "%EXE%.novo" del /q "%EXE%.novo"
pause
exit /b 1
