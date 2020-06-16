@echo off
echo Running jaba...
call jaba.bat --gen-ref
echo Running MaMD...
pushd C:\projects\GitHub\MaMD\_builds
MaMD_windows_amd64.exe -i "%~dp0..\docs\src" -o "%~dp0..\docs\output"
popd
