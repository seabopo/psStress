#==================================================================================================================
#==================================================================================================================
# psSTRESS - Tests
#==================================================================================================================
#==================================================================================================================

Clear-Host

Set-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

$Test = @{
    AutomaticThreads = $false
    ManualThreads    = $false
    RandomThreads    = $false
    CPU              = $false
    Memory           = $false
    None             = $false
    DockerCode       = $true
    DockerContainer  = $false
}

# Clean-up Jobs if you manually abort
#   get-job | stop-job
#   get-job | Remove-Job

if ( $Test.AutomaticThreads ) { Start-Stressing -sd 3 -wi 1 -ci 0 -si 1 -ri 1 }

if ( $Test.ManualThreads )    { Start-Stressing -sd 4 -wi 1 -ci 1 -si 1 -ri 1 -ct 3 -mt 3 }

if ( $Test.RandomThreads )    { Start-Stressing -sd 5 -wi 0 -ci 0 -si 2 -ri 2 -rz d,w -md 10 }

if ( $Test.CPU )              { Start-Stressing -sd 2 -wi 0 -ci 0 -si 1 -ri 1 -NoMemory }

if ( $Test.Memory )           { Start-Stressing -sd 2 -wi 0 -ci 0 -si 1 -ri 1 -NoCPU }

if ( $Test.None )             { Start-Stressing -sd 5 -wi 0 -ci 0 -si 2 -ri 2 -NoCPU -NoMemory }

if ( $Test.DockerContainer )
{
  # Test with automatically calculated CPU and memory threads
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_Duration=2" `
                -e "STRESS_WarmUpInterval=0" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/psstress-docker.ps1"

  # Test with manually specified CPU and memory threads
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_Duration=5" `
                -e "STRESS_WarmUpInterval=1" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_CpuThreads=3" `
                -e "STRESS_MemThreads=3" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/psstress-docker.ps1"

  # Test with randomized intervals
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_Duration=10" `
                -e "STRESS_WarmUpInterval=0" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_RandomizeIntervals=s,r" `
                -e "STRESS_MaxIntervalDuration=5" `
                -e "STRESS_CpuThreads=1" `
                -e "STRESS_MemThreads=1" `
                -e "STRESS_NoExit=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/psstress-docker.ps1"
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_Duration=2" `
                -e "STRESS_WarmUpInterval=0" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_NoMemory=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/psstress-docker.ps1"

    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_Duration=5" `
                -e "STRESS_WarmUpInterval=1" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_NoCPU=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/psstress-docker.ps1"

}

if ( $Test.DockerCode )
{
    Remove-Item -Path Env:\STRESS_*

    $env:STRESS_Duration            = 10
    #$env:STRESS_WarmUpInterval      = 1
    #$env:STRESS_CoolDownInterval    = 1
    $env:STRESS_StressInterval      = 1
    $env:STRESS_RestInterval        = 1
   #$env:STRESS_RandomizeIntervals  = "s,r"
   #$env:STRESS_MaxIntervalDuration = 10
    $env:STRESS_CpuThreads          = 1
    $env:STRESS_MemThreads          = 1
   #$env:STRESS_NoCPU               = 1
   #$env:STRESS_NoMemory            = 1
    $env:STRESS_NoExit              = 1

    #Remove-Item -Path Env:\STRESS_*

    .\psStress-docker.ps1

}
