#==================================================================================================================
#==================================================================================================================
# psSTRESS - Tests
#==================================================================================================================
#==================================================================================================================

Clear-Host

Set-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

$Test = @{
    All       = $true
    CPU       = $false
    Memory    = $false
    None      = $false
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
