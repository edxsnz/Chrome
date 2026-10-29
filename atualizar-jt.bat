@echo off
setlocal
chcp 65001 >nul
title Atualizar JT Express

rem ===== De onde baixa (seu GitHub) =====
set "REPO=https://raw.githubusercontent.com/edxsnz/Chrome/main"
rem ID fixo da extensao (vem da "key" do manifest.json) e nome do JT Bipe para o Chrome
set "EXT_ID=caolkdhekpnghlfcihnmcpclkplajffi"
set "HOST=com.jtexpress.bipe"
rem ======================================

rem Pasta Documentos de quem estiver usando (funciona em qualquer PC,
rem inclusive quando os Documentos ficam no OneDrive)
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; [Environment]::GetFolderPath('MyDocuments')"`) do set "DOCS=%%D"
if not defined DOCS set "DOCS=%USERPROFILE%\Documents"
if not exist "%DOCS%" goto erro

set "ZIP=%DOCS%\jt-express-extensao.zip"
set "PASTA=%DOCS%\jt-express-extensao"
set "JTEXE=%PASTA%\JT-Bipe.exe"
set "JTDADOS=%LOCALAPPDATA%\JTBipe"

echo.
echo Documentos: %DOCS%
echo.
echo [1/5] Baixando a extensao...
curl -fsSL --retry 2 -o "%ZIP%" "%REPO%/jt-express-extensao.zip?t=%RANDOM%%RANDOM%" || goto erro
rem confere se o .zip veio inteiro (extensao + JT Bipe) antes de apagar a antiga
tar -tf "%ZIP%" | findstr /i /c:"jt-express-extensao/manifest.json" >nul || goto erro
tar -tf "%ZIP%" | findstr /i /c:"jt-express-extensao/JT-Bipe.exe" >nul || goto erro

echo [2/5] Fechando o JT Bipe e o adb (se estiverem abertos)...
taskkill /im JT-Bipe.exe /f >nul 2>&1
if exist "%JTDADOS%\adb\adb.exe" "%JTDADOS%\adb\adb.exe" kill-server >nul 2>&1
taskkill /im adb.exe /f >nul 2>&1
timeout /t 1 /nobreak >nul

echo [3/5] Trocando a extensao (apaga a pasta antiga e extrai a nova)...
if exist "%PASTA%" rmdir /s /q "%PASTA%"
if exist "%PASTA%" goto erro_pasta
tar -xf "%ZIP%" -C "%DOCS%" || goto erro
if not exist "%PASTA%\manifest.json" goto erro
if not exist "%JTEXE%" goto erro
del /q "%ZIP%"
rem o JT-Bipe.exe antigo, que ficava solto nos Documentos, agora vem dentro da extensao
if exist "%DOCS%\JT-Bipe.exe" del /q "%DOCS%\JT-Bipe.exe"

echo [4/5] Registrando o JT Bipe no Chrome (para o Autobipe abrir ele sozinho)...
if not exist "%JTDADOS%" mkdir "%JTDADOS%"
powershell -NoProfile -Command "$j = [ordered]@{ name = $env:HOST; description = 'JT Bipe - Autobipe da extensao JT Express'; path = $env:JTEXE; type = 'stdio'; allowed_origins = @('chrome-extension://' + $env:EXT_ID + '/') } | ConvertTo-Json; [IO.File]::WriteAllText((Join-Path $env:JTDADOS ($env:HOST + '.json')), $j)" || goto erro
if not exist "%JTDADOS%\%HOST%.json" goto erro
reg add "HKCU\Software\Google\Chrome\NativeMessagingHosts\%HOST%" /ve /t REG_SZ /d "%JTDADOS%\%HOST%.json" /f >nul || goto erro
rem (Edge, Brave e Chromium tambem, caso a extensao seja usada neles)
reg add "HKCU\Software\Microsoft\Edge\NativeMessagingHosts\%HOST%" /ve /t REG_SZ /d "%JTDADOS%\%HOST%.json" /f >nul 2>&1
reg add "HKCU\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\%HOST%" /ve /t REG_SZ /d "%JTDADOS%\%HOST%.json" /f >nul 2>&1
reg add "HKCU\Software\Chromium\NativeMessagingHosts\%HOST%" /ve /t REG_SZ /d "%JTDADOS%\%HOST%.json" /f >nul 2>&1

echo [5/5] Pronto!
echo.
echo   Extensao: %PASTA%
echo.
echo No Chrome (ou Brave/Edge), abra a pagina de extensoes e clique em recarregar (seta em circulo)
echo na extensao JT Express.
echo.
echo 1a vez neste PC (ou vindo de uma versao antiga, que tinha outro ID):
echo   1. Remova a extensao JT Express antiga.
echo   2. Ligue o "Modo do desenvolvedor" e clique em "Carregar sem compactacao".
echo   3. Escolha a pasta %PASTA%
echo   4. Digite seu nome de novo na extensao.
echo.
pause
exit /b 0

:erro_pasta
echo.
echo ERRO: nao consegui apagar a pasta antiga (algum arquivo dela esta aberto?).
echo Feche o que estiver usando a pasta e rode de novo.
pause
exit /b 1

:erro
echo.
echo ERRO: nao consegui terminar. Confira a internet e se o arquivo esta no GitHub:
echo   %REPO%/jt-express-extensao.zip
pause
exit /b 1
