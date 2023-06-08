#==================================================================================================================
#==================================================================================================================
# psSTRESS - Docker Run File
#==================================================================================================================
#==================================================================================================================

Set-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

$params = @{
    WarmUpTime     = $env:STRESS_WarmUpTime     ??= 2
    CoolDownTime   = $env:STRESS_CoolDownTime   ??= 0
    TestTime       = $env:STRESS_TestTime       ??= 60
    StressInterval = $env:STRESS_StressInterval ??= 15
    RestInterval   = $env:STRESS_RestInterval   ??= 10
}
Start-Stressing @params
