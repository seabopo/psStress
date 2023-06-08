#==================================================================================================================
#==================================================================================================================
# psSTRESS - Tests
#==================================================================================================================
#==================================================================================================================

Clear-Host

Set-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

$Test = @{
    All             = $false
    CPU             = $false
    Memory          = $false
    None            = $false
    DockerCode      = $true
    DockerContainer = $false
}

# Clean-up Jobs if you manually abort
#   get-job | stop-job
#   get-job | Remove-Job

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

if ( $Test.DockerContainer )
{
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_TestTime=5" `
                -e "STRESS_WarmUpTime=1" `
                -e "STRESS_CoolDownTime=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/psstress-docker.ps1"

    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_TestTime=5" `
                -e "STRESS_WarmUpTime=1" `
                -e "STRESS_CoolDownTime=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_NoMemory=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/psstress-docker.ps1"

    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_TestTime=5" `
                -e "STRESS_WarmUpTime=1" `
                -e "STRESS_CoolDownTime=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_NoCPU=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/psstress-docker.ps1"

}

if ( $Test.DockerCode )
{
    # Remove-Item -Path Env:\STRESS_* -Verbose

    # $env:STRESS_WarmUpTime     = 1
    # $env:STRESS_CoolDownTime   = 0
    # $env:STRESS_TestTime       = 10
    # $env:STRESS_StressInterval = 2
    # $env:STRESS_RestInterval   = 1
    # $env:STRESS_RestInterval   = 1
    # $env:STRESS_NoCPU          = $true
    # $env:STRESS_NoMemory       = $false

    #Remove-Item -Path Env:\STRESS_* -Verbose

    $noCPU    = $( if ([string]::IsNullOrEmpty($env:STRESS_NoCPU))    { $false } else { $true } )
    $NoMemory = $( if ([string]::IsNullOrEmpty($env:STRESS_NoMemory)) { $false } else { $true } )

    $params = @{
        WarmUpTime     = $env:STRESS_WarmUpTime     ??= 2
        CoolDownTime   = $env:STRESS_CoolDownTime   ??= 0
        TestTime       = $env:STRESS_TestTime       ??= 60
        StressInterval = $env:STRESS_StressInterval ??= 15
        RestInterval   = $env:STRESS_RestInterval   ??= 10
    }
    Start-Stressing @params -NoCPU:$noCPU -NoMemory:$NoMemory

    # For PowerShell 5
    # $params = @{
    #     WarmUpTime     = $( if ([string]::IsNullOrEmpty($env:STRESS_WarmUpTime))     {  2 } else {$env:STRESS_WarmUpTime} )
    #     CoolDownTime   = $( if ([string]::IsNullOrEmpty($env:STRESS_CoolDownTime))   {  0 } else {$env:STRESS_CoolDownTime} )
    #     TestTime       = $( if ([string]::IsNullOrEmpty($env:STRESS_TestTime))       { 60 } else {$env:STRESS_TestTime} )
    #     StressInterval = $( if ([string]::IsNullOrEmpty($env:STRESS_StressInterval)) { 15 } else {$env:STRESS_StressInterval} )
    #     RestInterval   = $( if ([string]::IsNullOrEmpty($env:STRESS_RestInterval))   { 10 } else {$env:STRESS_RestInterval} )
    # }
    # Start-Stressing @params -NoCPU:$env:STRESS_NoCPU -NoMemory:$env:STRESS_NoMemory
}
