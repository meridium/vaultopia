@echo off  
 if '%1' ==''  (
 echo  USAGE: %0  web application path "[..\episerversitepath or c:\episerversitepath]" 
	) else (
epideploy.exe  -a sql -s "%~f1"  -p "EPiServer.CMS.Core.7.13.3\epiupdates\*" -c "EPiServerDB"
) 

