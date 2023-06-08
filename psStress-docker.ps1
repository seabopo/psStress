#==================================================================================================================
#==================================================================================================================
# psSTRESS - Docker Run File
#==================================================================================================================
#==================================================================================================================

Set-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

$noCPU    = $( if ([string]::IsNullOrEmpty($env:STRESS_NoCPU))    { $false } else { $true } )
$NoMemory = $( if ([string]::IsNullOrEmpty($env:STRESS_NoMemory)) { $false } else { $true } )

$params = @{
    TestTime       = $env:STRESS_TestTime       ??= 60
    WarmUpTime     = $env:STRESS_WarmUpTime     ??= 1
    CoolDownTime   = $env:STRESS_CoolDownTime   ??= 0
    StressInterval = $env:STRESS_StressInterval ??= 15
    RestInterval   = $env:STRESS_RestInterval   ??= 10
    CpuThreads     = $env:STRESS_CpuThreads
    MemThreads     = $env:STRESS_MemThreads
}
Start-Stressing @params -NoCPU:$noCPU -NoMemory:$NoMemory
