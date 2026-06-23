set CLASS_NUMBER=26020
set CLASS_NAME=26020_RTOS4

echo Erasing old %CLASS_NAME% directory
del C:\Masters\%CLASS_NAME%\* /S /F /Q
echo Restoring class %CLASS_NAME%
xcopy C:\Backup\%CLASS_NAME% c:\Masters\%CLASS_NAME% /F /E /C /Y /i
echo Removing %CLASS_NUMBER%_Restore.bat file
del "C:\Masters\%CLASS_NAME%\%CLASS_NUMBER%_Restore.bat"
del "C:\Masters\%CLASS_NAME%\%CLASS_NAME%_Installer.bat"
del "C:\Masters\%CLASS_NAME%\README_%CLASS_NUMBER%_Installer.md"
exit