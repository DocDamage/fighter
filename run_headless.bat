@echo off
REM Run Street Fighter — DocRoshi Remix in headless mode for testing
set GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_mono_win64\Godot_v4.6.2-stable_mono_win64.exe
"%GODOT_EXE%" --headless --path "%CD%"
