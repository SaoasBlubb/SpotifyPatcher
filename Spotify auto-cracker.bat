@echo off
powershell -Command "& {Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/SaoasBlubb/SpotifyPatcher/main/install.ps1' | Invoke-Expression}"
pause
exit