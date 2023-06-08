#==================================================================================================================
#==================================================================================================================
# psSTRESS - Tests
#==================================================================================================================
#==================================================================================================================

Clear-Host

Set-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

$Test = @{
    All       = $false
    CPU       = $false
    Memory    = $false
    None      = $false
    Docker    = $true
}

if ( $Test.All )
{
    Start-Stressing -tt 30 -wt 0 -ct 0 -si 2 -ri 2
}

if ( $Test.CPU )
{
    Start-Stressing -tt 30 -wt 0 -ct 0 -si 2 -ri 2 -NoMemory
}

if ( $Test.Memory )
{
    Start-Stressing -tt 30 -wt 0 -ct 0 -si 2 -ri 2 -NoCPU
}

if ( $Test.None )
{
    Start-Stressing -tt 30 -wt 0 -ct 0 -si 2 -ri 2 -NoCPU -NoMemory
}

if ( $Test.Docker )
{
    $env:STRESS_WarmUpTime     = 1
    $env:STRESS_CoolDownTime   = 0
    $env:STRESS_TestTime       = 10
    $env:STRESS_StressInterval = 2
    $env:STRESS_RestInterval   = 1

    Remove-Item -Path Env:\STRESS_* -Verbose

    $params = @{
        WarmUpTime     = $env:STRESS_WarmUpTime     ??= 2
        CoolDownTime   = $env:STRESS_CoolDownTime   ??= 0
        TestTime       = $env:STRESS_TestTime       ??= 60
        StressInterval = $env:STRESS_StressInterval ??= 15
        RestInterval   = $env:STRESS_RestInterval   ??= 10
    }
    Start-Stressing @params

    # $params = @{
    #     WarmUpTime     = $( if ([string]::IsNullOrEmpty($env:STRESS_WarmUpTime))     {  2 } else {$env:STRESS_WarmUpTime} )
    #     CoolDownTime   = $( if ([string]::IsNullOrEmpty($env:STRESS_CoolDownTime))   {  0 } else {$env:STRESS_CoolDownTime} )
    #     TestTime       = $( if ([string]::IsNullOrEmpty($env:STRESS_TestTime))       { 60 } else {$env:STRESS_TestTime} )
    #     StressInterval = $( if ([string]::IsNullOrEmpty($env:STRESS_StressInterval)) { 15 } else {$env:STRESS_StressInterval} )
    #     RestInterval   = $( if ([string]::IsNullOrEmpty($env:STRESS_RestInterval))   { 10 } else {$env:STRESS_RestInterval} )
    # }
    # Start-Stressing @params -NoCPU:$env:STRESS_NoCPU -NoMemory:$env:STRESS_NoMemory
}

