#==================================================================================================================
#==================================================================================================================
# psSTRESS - Tests
#==================================================================================================================
#==================================================================================================================

Clear-Host

Set-Location  -Path $PSScriptRoot
Push-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

$null | Out-File $( '{0}/http/app.log' -f $PSScriptRoot )
$null | Out-File $( '{0}/http/usr.log' -f $PSScriptRoot )

$Test = @{
    AutomaticThreads = $false
    ManualThreads    = $false
    RandomThreads    = $false
    CPU              = $false
    Memory           = $false
    None             = $false
    DockerCode       = $false
    DockerContainer  = $false
    WebServer        = $true
    DumpDebugData    = $false
}

# Clean-up Jobs if you manually abort
#   get-job | stop-job
#   get-job | Remove-Job

if ( $Test.WebServer )        { Start-Stressing -ws -ns -nx -wc }

if ( $Test.DumpDebugData )    { Start-Stressing -ns -dd }

if ( $Test.AutomaticThreads ) { Start-Stressing -sd 3 -wi 1 -ci 0 -si 1 -ri 1 -ws }

if ( $Test.ManualThreads )    { Start-Stressing -sd 4 -wi 1 -ci 1 -si 1 -ri 1 -ct 3 -mt 3 }

if ( $Test.RandomThreads )    { Start-Stressing -sd 5 -wi 0 -ci 0 -si 2 -ri 2 -rz d,w -md 10 }

if ( $Test.CPU )              { Start-Stressing -sd 2 -wi 0 -ci 0 -si 1 -ri 1 -NoMemory }

if ( $Test.Memory )           { Start-Stressing -sd 2 -wi 0 -ci 0 -si 1 -ri 1 -NoCPU }

if ( $Test.None )             { Start-Stressing -sd 5 -wi 0 -ci 0 -si 2 -ri 2 -NoCPU -NoMemory }

if ( $Test.DockerContainer )
{
  # Open an interactive container
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -it --user ContainerAdministrator `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass

  # Test only the web server.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_EnableWebServer=1" `
                -e "STRESS_NoExit=1" `
                -e "STRESS_NoStress=1" `
                -e "STRESS_EnableWebServerConsoleLogs=1" `
                -it --user ContainerAdministrator `
                -p 8080:8080 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # Test with only the web server and debug dump.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_EnableWebServer=1" `
                -e "STRESS_NoExit=1" `
                -e "STRESS_NoStress=1" `
                -e "STRESS_ShowDebugData=1" `
                -it --user ContainerAdministrator `
                -p 8080:8080 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # Test with automatically calculated CPU and memory threads
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_StressDuration=5" `
                -e "STRESS_WarmUpInterval=1" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_EnableWebServer=1" `
                -it --user ContainerAdministrator `
                -p 8080:8080 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # Test with manually specified CPU and memory threads
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_StressDuration=5" `
                -e "STRESS_WarmUpInterval=1" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_CpuThreads=3" `
                -e "STRESS_MemThreads=3" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # Test with randomized intervals
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_StressDuration=10" `
                -e "STRESS_WarmUpInterval=1" `
                -e "STRESS_CoolDownInterval=1" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_RandomizeIntervals=s,r" `
                -e "STRESS_MaxIntervalDuration=5" `
                -e "STRESS_CpuThreads=1" `
                -e "STRESS_MemThreads=1" `
                -e "STRESS_NoExit=1" `
                -e "STRESS_EnableWebServer=1" `
                -e "STRESS_WebServerPort=80" `
                -it --user ContainerAdministrator `
                -p 80:80 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # Test CPU-only stressing.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_StressDuration=2" `
                -e "STRESS_WarmUpInterval=0" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_NoMemory=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # Test memory-only stressing.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "STRESS_StressDuration=5" `
                -e "STRESS_WarmUpInterval=1" `
                -e "STRESS_CoolDownInterval=0" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_NoCPU=1" `
                -it `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # Test dockerhub images.
    docker run `
                -e "STRESS_EnableWebServer=1" `
                -e "STRESS_NoWebServerConsoleLogs=1" `
                -e "STRESS_NoExit=1" `
                -e "STRESS_NoStress=1" `
                -e "STRESS_ShowDebugData=1" `
                -p 8080:8080 `
                seabopo/psstress:nanoserver-1809

    docker run `
                -e "STRESS_StressDuration=10" `
                -e "STRESS_WarmUpInterval=1" `
                -e "STRESS_CoolDownInterval=1" `
                -e "STRESS_StressInterval=1" `
                -e "STRESS_RestInterval=1" `
                -e "STRESS_RandomizeIntervals=s,r" `
                -e "STRESS_MaxIntervalDuration=5" `
                -e "STRESS_CpuThreads=1" `
                -e "STRESS_MemThreads=1" `
                -e "STRESS_NoExit=1" `
                -e "STRESS_EnableWebServer=1" `
                -e "STRESS_WebServerPort=80" `
                -e "STRESS_NoWebServerConsoleLogs=1" `
                -p 8080:8080 `
                seabopo/psstress:nanoserver-1809

}

if ( $Test.DockerCode )
{
    Remove-Item -Path Env:\STRESS_*

    $env:STRESS_StressDuration      = 10
    $env:STRESS_WarmUpInterval      = 1
    $env:STRESS_CoolDownInterval    = 1
    $env:STRESS_StressInterval      = 1
    $env:STRESS_RestInterval        = 1
    $env:STRESS_RandomizeIntervals  = "s,r"
    $env:STRESS_MaxIntervalDuration = 5
    $env:STRESS_CpuThreads          = 1
    $env:STRESS_MemThreads          = 1
   #$env:STRESS_NoCPU               = 1
   #$env:STRESS_NoMemory            = 1
    $env:STRESS_NoExit              = 1
    $env:STRESS_NoStress              = 1
    $env:STRESS_WebServerPort       = 80
    $env:STRESS_EnableWebServer     = 1
    #$env:STRESS_ShowDebugData       = 1

    #Remove-Item -Path Env:\STRESS_*

    .\docker.ps1

}
