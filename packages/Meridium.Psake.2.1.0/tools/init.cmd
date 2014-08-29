@echo off
echo %windir%
for /F "tokens=*" %%A in ('dir ..\packages\Meridium.Psake.* /O-N /B') do (
	%windir%\syswow64\windowspowershell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '..\packages\%%A\tools\initialize.ps1' %*; if ($psake.build_success -eq $false) { exit 1 } else { exit 0 }"
	goto :loopend
)

:loopend
