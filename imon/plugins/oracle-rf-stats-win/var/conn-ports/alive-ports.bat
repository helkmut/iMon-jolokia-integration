@echo off
set arg1=%1

netstat -aon | find /i "listening" | find "%arg1%" /c