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
    DockerCode       = $true
    DockerContainer  = $false
    WebServer        = $false
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

if ( $Test.DockerCode )
{
    Remove-Item -Path Env:\PS_STRESS_*

    $env:PS_STRESS_StressDuration      = 33
    $env:PS_STRESS_WarmUpInterval      = 3
    $env:PS_STRESS_CoolDownInterval    = 3
    $env:PS_STRESS_StressInterval      = 3
    $env:PS_STRESS_RestInterval        = 3
    $env:PS_STRESS_RandomizeIntervals  = "s,r"
    $env:PS_STRESS_MaxIntervalDuration = 33
    $env:PS_STRESS_CpuThreads          = 3
    $env:PS_STRESS_MemThreads          = 3
    #$env:PS_STRESS_NoExit              = 1
    #$env:PS_STRESS_NoCPU               = 1
    #$env:PS_STRESS_NoMemory            = 1
    #$env:PS_STRESS_NoStress            = 1
    $env:PS_STRESS_WebServerPort       = 80
    $env:PS_STRESS_EnableWebServer     = 1
    $env:PS_STRESS_ShowDebugData       = 1

    #Remove-Item -Path Env:\PS_STRESS_*

    .\docker.ps1

}

if ( $Test.DockerContainer )
{
  # NOTES:
  #  - If the NoExit switch is not used the containers will exit when the stress intervals
  #    have completed. If the container is run as a K8s servive the scheduler will restart the
  #    pod, and the tests. Use the NoExit parameter to avoid this. Alternatively, use this to
  #    test pod restarts and alerting. You can also use the cooldown period to delay the pod
  #    from exiting.
  #  - Running the webserver requires that the user context is ContainerAdministrator. You'll
  #    get an authorization error otherwise and the webserver will not start.
  #  - Running the tests from the web server will stress only the individual pod - there is
  #    no communication to other pods, so any additional pods that are spun up based on pod
  #    autoscaling will produce no load.
  #  - To stress pod autoscaling run tests at pod launch. This will max out your
  #    autoscaling counts. Make sure to allow rest intervals that will allow all pods to
  #    scale down via the autoscaler before the stress cycle starts again.


  # Open an interactive container that uses the PowerShell Nano Server base image.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -it --user ContainerAdministrator `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass

  # DEBUG
  # Dumps the container's environment and application variables and waits for the container to be killed.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "PS_STRESS_NoExit=1" `
                -e "PS_STRESS_NoStress=1" `
                -e "PS_STRESS_ShowDebugData=1" `
                -it `
                -p 8080:8080 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # SINGLE POD TESTS
  # Run the web server and skip all tests. A few basic tests can be run from the web
  # server, but these only stress the single container you are connected to. This will
  # allow you to test a singe container/pod for logging, monitoring, alterting. Stressing
  # this pod will cause the K8s HPA to run a new instance, but the second instance will
  # not generate any load.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "PS_STRESS_EnableWebServer=1" `
                -e "PS_STRESS_NoExit=1" `
                -e "PS_STRESS_NoStress=1" `
                -e "PS_STRESS_EnableWebServerConsoleLogs=1" `
                -it --user ContainerAdministrator `
                -p 8080:8080 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # AUTOMATED STRESSING
  # Runs a stress session with the default values and exits. The default settings do
  # not enable the webserver, which requires the --user ContainerAdministrator switch.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -it `
                -p 8080:8080 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # AUTOMATED STRESSING - CPU Only
  # Runs a stress session with the default values, but skips memory stressing, and exits.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "PS_STRESS_NoMemory=1" `
                -it `
                -p 8080:8080 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # AUTOMATED STRESSING - Memory Only
  # Runs a stress session with the default values, but skips memory stressing, and exits.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "PS_STRESS_NoCPU=1" `
                -it `
                -p 8080:8080 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

   # MANUAL STRESSING
   # Runs a test with manually specified values. The stress values listed below are the defaults.
   # Setting CPU/Memory threads to zero automatically calculates them based on environment.
   # The web server is enabled, which requires --user ContainerAdministrator.
   # The NoExit switch is enabled so the container will not exit and will run indefinitely.
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "PS_STRESS_StressDuration=10" `
                -e "PS_STRESS_WarmUpInterval=1" `
                -e "PS_STRESS_CoolDownInterval=0" `
                -e "PS_STRESS_StressInterval=5" `
                -e "PS_STRESS_RestInterval=5" `
                -e "PS_STRESS_CpuThreads=0" `
                -e "PS_STRESS_MemThreads=0" `
                -e "PS_STRESS_MaxIntervalDuration=1440" `
                -e "PS_STRESS_NoExit=1" `
                -e "PS_STRESS_EnableWebServer=1" `
                -e "PS_STRESS_WebServerPort=8080" `
                -it --user ContainerAdministrator `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # RANDOMIZED STRESSING
  # Runs a 4-hour test with randomized stress and rest cycles. The stress and rest
  # cycle intervals will range from 5 minutes (StressInterval/RestInterval) to
  # 60 minutes (MaxIntervalDuration).
    docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                -e "PS_STRESS_StressDuration=240" `
                -e "PS_STRESS_WarmUpInterval=1" `
                -e "PS_STRESS_CoolDownInterval=0" `
                -e "PS_STRESS_StressInterval=5" `
                -e "PS_STRESS_RestInterval=5" `
                -e "PS_STRESS_RandomizeIntervals=s,r" `
                -e "PS_STRESS_CpuThreads=1" `
                -e "PS_STRESS_MemThreads=1" `
                -e "PS_STRESS_MaxIntervalDuration=60" `
                -e "PS_STRESS_NoExit=1" `
                -e "PS_STRESS_EnableWebServer=1" `
                -e "PS_STRESS_WebServerPort=80" `
                -it --user ContainerAdministrator `
                -p 80:80 `
                mcr.microsoft.com/powershell:nanoserver-1809 `
                pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

  # Test dockerhub images.
    docker run `
                -e "PS_STRESS_EnableWebServer=1" `
                -e "PS_STRESS_NoExit=1" `
                -e "PS_STRESS_NoStress=1" `
                -p 8080:8080 `
                seabopo/psstress:nanoserver-1809

    docker run `
                -e "PS_STRESS_ShowDebugData=1" `
                -e "PS_STRESS_StressDuration=10" `
                -e "PS_STRESS_WarmUpInterval=1" `
                -e "PS_STRESS_CoolDownInterval=1" `
                -e "PS_STRESS_StressInterval=1" `
                -e "PS_STRESS_RestInterval=1" `
                -e "PS_STRESS_RandomizeIntervals=s,r" `
                -e "PS_STRESS_MaxIntervalDuration=5" `
                -e "PS_STRESS_CpuThreads=1" `
                -e "PS_STRESS_MemThreads=1" `
                -e "PS_STRESS_NoExit=1" `
                -e "PS_STRESS_EnableWebServer=1" `
                -e "PS_STRESS_WebServerPort=80" `
                -e "PS_STRESS_EnableWebServerConsoleLogs=1" `
                -p 8080:8080 `
                seabopo/psstress:nanoserver-1809

}
