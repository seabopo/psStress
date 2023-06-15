#==================================================================================================================
#==================================================================================================================
# psSTRESS - WebServer Run File
#==================================================================================================================
#==================================================================================================================

param( [int] $Port = 8080, [switch] $EnableConsoleLogs )

Set-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

Start-WebServer -Port $Port -EnableConsoleLogs:$EnableConsoleLogs

Start-Sleep -Seconds 60
