@echo off
set arg1=%1

netstat -np TCP | find "%arg1%" /c