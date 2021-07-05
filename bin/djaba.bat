@echo off
echo Running jaba...
call jaba.bat genref

IF %ERRORLEVEL% EQU 0 (
  pushd C:\projects\GitHub\MaMD\_builds
  echo Running MaMD...
  MaMD_windows_amd64.exe -i "%~dp0..\docs_src" -o "%~dp0..\docs"
  popd
)
