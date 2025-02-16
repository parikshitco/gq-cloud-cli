@echo off
:: Open PowerShell as Administrator and keep window open
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& { Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command ""Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(''https://raw.githubusercontent.com/parikshitco/gq-cloud-cli/main/install.ps1'')); pause""' -Verb RunAs }"
