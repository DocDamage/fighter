@echo off
REM Launch Street Fighter — DocRoshi Remix without .NET popup
set GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_mono_win64\Godot_v4.6.2-stable_mono_win64.exe
"%GODOT_EXE%" --path "%CD%"
