@echo off
cls
echo ==========================================
echo    Starting CS 1.6 Zombie Plague Server
echo ==========================================

:loop
hlds.exe -console -game cstrike +map de_dust2 +maxplayers 32 +port 27015 +sv_lan 1 -secure

echo.
echo [!] Server crashed or closed. Restarting in 5 seconds...
timeout /t 5 >nul
goto loop