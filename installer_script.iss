; Inno Setup Script for pos_app (Flutter Windows Desktop)
; Download Inno Setup from https://jrsoftware.org/isdl.php

#define MyAppName "Caskly POS"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "Caskly"
#define MyAppExeName "pos_app.exe"
#define MyAppBuildDir "build\windows\x64\runner\Release"

[Setup]
AppId={{D37E8C94-4F9A-4B6A-912A-684B2822181C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=build\windows\installer
OutputBaseFilename=Caskly_POS_Setup_v{#MyAppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Primary executable
Source: "{#MyAppBuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; All DLLs (including bundled VC++ runtime DLLs) and data folder
Source: "{#MyAppBuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppBuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; AppUserModelID: "Caskly.POS.Desktop"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; AppUserModelID: "Caskly.POS.Desktop"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
