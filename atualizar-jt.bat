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
set "NOVA=%DOCS%\jt-express-extensao.novo"
set "LISTA=%TEMP%\jt-lista-%RANDOM%%RANDOM%.txt"

echo.
echo Documentos: "%DOCS%"
echo.
echo [1/4] Baixando a extensao...
if exist "%ZIP%" del /q "%ZIP%"
curl -fSL --retry 2 -# -o "%ZIP%" "%REPO%/jt-express-extensao.zip?t=%RANDOM%%RANDOM%"
if errorlevel 1 (
  echo.
  echo O download falhou. A mensagem do curl esta logo acima.
  goto erro
)
rem o antivirus pode apagar o arquivo logo depois de baixar
timeout /t 2 /nobreak >nul
if not exist "%ZIP%" (
  echo.
  echo O arquivo baixado sumiu: o antivirus provavelmente apagou ou bloqueou.
  echo Veja em Seguranca do Windows ^> Protecao contra virus ^> Historico de protecao.
  goto erro
)
rem confere se o .zip veio inteiro antes de mexer na extensao antiga
tar -tf "%ZIP%" > "%LISTA%" 2>&1
if errorlevel 1 (
  echo.
  echo O .zip baixado nao abre ^(veio cortado ou foi bloqueado^):
  type "%LISTA%"
  del /q "%LISTA%" >nul 2>&1
  goto erro
)
findstr /i /c:"jt-express-extensao/manifest.json" "%LISTA%" >nul || (del /q "%LISTA%" >nul 2>&1 & echo. & echo O .zip nao tem a extensao dentro. & goto erro)
del /q "%LISTA%" >nul 2>&1

echo [2/4] Trocando a extensao...
rem Extrai primeiro numa pasta ao lado e confere; so depois apaga a antiga.
rem Se algo falhar no meio, a extensao antiga continua funcionando.
if exist "%NOVA%" rmdir /s /q "%NOVA%"
mkdir "%NOVA%" || goto erro
tar -xf "%ZIP%" -C "%NOVA%" || (rmdir /s /q "%NOVA%" & goto erro)
if not exist "%NOVA%\jt-express-extensao\manifest.json" (rmdir /s /q "%NOVA%" & goto erro)
if exist "%PASTA%" rmdir /s /q "%PASTA%"
if exist "%PASTA%" (rmdir /s /q "%NOVA%" & goto erro_pasta)
move "%NOVA%\jt-express-extensao" "%PASTA%" >nul || tar -xf "%ZIP%" -C "%DOCS%"
rmdir /s /q "%NOVA%" >nul 2>&1
if not exist "%PASTA%\manifest.json" goto erro
del /q "%ZIP%"

echo [3/4] Removendo o JT Bipe (Autobipe descontinuado), se ainda estiver neste PC...
rem Fecha o programa e o adb que vinham com ele
taskkill /im JT-Bipe.exe /f >nul 2>&1
if exist "%LOCALAPPDATA%\JTBipe\adb\adb.exe" "%LOCALAPPDATA%\JTBipe\adb\adb.exe" kill-server >nul 2>&1
rem Tira o registro do JT Bipe de todos os navegadores (o que nao existir e ignorado)
for %%K in ("Google\Chrome" "Microsoft\Edge" "BraveSoftware\Brave-Browser" "Chromium" "Vivaldi" "Opera Software" "Opera Software\Opera GX Stable" "Yandex\YandexBrowser" "Thorium" "CentBrowser" "The Browser Company\Arc") do (
  reg delete "HKCU\Software\%%~K\NativeMessagingHosts\com.jtexpress.bipe" /f >nul 2>&1
)
rem Apaga a pasta do JT Bipe (adb, registro e arquivos dele)
if exist "%LOCALAPPDATA%\JTBipe" (
  timeout /t 1 /nobreak >nul
  rmdir /s /q "%LOCALAPPDATA%\JTBipe" >nul 2>&1
)
rem O JT-Bipe.exe antigo, de quando ficava solto nos Documentos
if exist "%DOCS%\JT-Bipe.exe" del /q "%DOCS%\JT-Bipe.exe" >nul 2>&1

echo [4/4] Pronto!
echo.
echo   Extensao: "%PASTA%"
echo.
echo No navegador (Chrome, Brave, Edge, Opera...), abra a pagina de extensoes e clique em recarregar (seta em circulo)
echo na extensao JT Express.
echo.
echo 1a vez neste PC (ou vindo de uma versao antiga, que tinha outro ID):
echo   1. Remova a extensao JT Express antiga.
echo   2. Ligue o "Modo do desenvolvedor" e clique em "Carregar sem compactacao".
echo   3. Escolha a pasta "%PASTA%"
echo   4. Digite seu nome de novo na extensao.
echo.
pause
exit /b 0

:erro_pasta
echo.
echo ERRO: nao consegui apagar a pasta antiga ^(algum arquivo dela esta aberto?^).
echo A extensao antiga continua no lugar.
echo Feche o que estiver usando a pasta e rode de novo.
pause
exit /b 1

:erro
echo.
echo ERRO: nao consegui terminar. Confira a internet e se o arquivo esta no GitHub:
echo   %REPO%/jt-express-extensao.zip
pause
exit /b 1
