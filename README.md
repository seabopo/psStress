# psStress
A PowerShell module for basic CPU and Memory stressing.

\
A Window Server Nano Docker version of this module is available here: 
[seabopo/psstress](https://hub.docker.com/repository/docker/seabopo/psstress/general)

    docker run `
        -e "STRESS_TestTime=5" `
        -e "STRESS_WarmUpTime=1" `
        -e "STRESS_CoolDownTime=0" `
        -e "STRESS_StressInterval=1" `
        -e "STRESS_RestInterval=1" `
        -it seabopo/psstress:nanoserver-1809 ( or :nanoserver-ltsc2022  )

To test in Microsoft's PowerShell container:

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


OPTIONS: 

    .PARAMETER WarmUpTime
        OPTIONAL. Integer. Alias: -wt. The time, in minutes, to wait before starting stress tests.
        Warm up time is not included in the total test time. Default Value: 0.

    .PARAMETER CoolDownTime
        OPTIONAL. Integer. Alias: -ct. The time, in minutes, to wait after the tests have been completed before
        exiting the script process. Cool down time is not included in the total test time. Default Value: 0.

    .PARAMETER TestTime
        OPTIONAL. Integer. Alias: -tt. The total time, in minutes, for the tests to run. Test time includes
        only Stress and Rest interval times. It does not include warm up or cool down times. Default Value: 30.

    .PARAMETER StressInterval
        OPTIONAL. Integer. Alias: -si. The time, in minutes, that each stress test should run for.
        Default Value: 5.

    .PARAMETER RestInterval
        OPTIONAL. Integer. Alias: -ri. The time, in minutes, to reduce all load between each stress interval.
        Default Value: 5.
        
     .PARAMETER NoCPU **
        OPTIONAL. Switch. Alias: -nc. Disables CPU tests.

    .PARAMETER NoMemory **
        OPTIONAL. Switch. Alias: -nm. Disables memory tests.

    ** NoCPU and NoMemory are exclusive - only one can be used per test.