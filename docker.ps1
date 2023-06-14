#==================================================================================================================
#==================================================================================================================
# psSTRESS - Docker Run File
#==================================================================================================================
#==================================================================================================================
<#
    Calling this file from Windows:
    -------------------------------

        Remove-Item -Path Env:\STRESS_*

        $env:STRESS_StressDuration      = 10
        $env:STRESS_WarmUpInterval      = 1
        $env:STRESS_CoolDownInterval    = 1
        $env:STRESS_StressInterval      = 1
        $env:STRESS_RestInterval        = 1
        $env:STRESS_CpuThreads          = 1
        $env:STRESS_MemThreads          = 1

        $env:STRESS_RandomizeIntervals  = "s,r"
        $env:STRESS_MaxIntervalDuration = 10

        $env:STRESS_NoCPU               = 1
        $env:STRESS_NoMemory            = 1
        $env:STRESS_NoExit              = 1

        $env:STRESS_EnableWebServer     = 1
        $env:STRESS_WebServerPort       = 8080

      NOTES:
       - STRESS_NoCPU and STRESS_NoMemory are exclusive. Only one may be used at a time.
       - STRESS_NoCPU, STRESS_NoMemory and STRESS_NoExit are SWITCHES ... their presence indicates they should
         be used. Their value is irrelevant. If you don't want to enable these praramaters do not set their
         associated environment variables.

    Calling this file via Docker:
    -----------------------------

        docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                    -e "STRESS_StressDuration=10" `
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
                    pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

#>

Set-Location -Path $PSScriptRoot
Push-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

if ( $env:STRESS_EnableWebServerOnly ) {

    $port = $env:STRESS_WebServerPort ??= '8080'

    Start-Process -FilePath "pwsh" -Verb RunAs -ArgumentList ('-File','.\webserver.ps1','-port',$port)

}
else {

    $switchParams = @('STRESS_NoCPU','STRESS_NoMemory','STRESS_NoExit','STRESS_EnableWebServer')
    $arrayParams  = @('STRESS_RandomizeIntervals')

    $params = @{}

    Get-Item -Path Env:\STRESS_* |
        ForEach-Object {
            $key   = $_.Name.Replace('STRESS_','')
            $value = if     ( $_.Name -in $switchParams ) { $true }
                    elseif ( $_.Name -in $arrayParams )  { $_.value -split ',' }
                    else                                 { $_.value }
            $params.Add($key,$value)
        }

    Start-Stressing @params

}
