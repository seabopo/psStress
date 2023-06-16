#==================================================================================================================
#==================================================================================================================
# psSTRESS - Docker Run File
#==================================================================================================================
#==================================================================================================================
<#
    Calling this file from Windows:
    -------------------------------

        Remove-Item -Path Env:\PS_STRESS_*

        $env:PS_STRESS_StressDuration      = 10
        $env:PS_STRESS_WarmUpInterval      = 1
        $env:PS_STRESS_CoolDownInterval    = 1
        $env:PS_STRESS_StressInterval      = 1
        $env:PS_STRESS_RestInterval        = 1
        $env:PS_STRESS_CpuThreads          = 1
        $env:PS_STRESS_MemThreads          = 1

        $env:PS_STRESS_RandomizeIntervals  = "s,r"
        $env:PS_STRESS_MaxIntervalDuration = 10

        $env:PS_STRESS_NoCPU               = 1
        $env:PS_STRESS_NoMemory            = 1
        $env:PS_STRESS_NoExit              = 1

        $env:PS_STRESS_EnableWebServer     = 1
        $env:PS_STRESS_WebServerPort       = 8080

      NOTES:
       - PS_STRESS_NoCPU and PS_STRESS_NoMemory are exclusive. Only one may be used at a time.
       - PS_STRESS_NoCPU, PS_STRESS_NoMemory and PS_STRESS_NoExit are SWITCHES ... their presence indicates they should
         be used. Their value is irrelevant. If you don't want to enable these praramaters do not set their
         associated environment variables.

    Calling this file via Docker:
    -----------------------------

        docker run  --mount type=bind,source=C:\Repos\Github\psStress,target=C:\psStress `
                    -e "PS_STRESS_StressDuration=10" `
                    -e "PS_STRESS_WarmUpInterval=0" `
                    -e "PS_STRESS_CoolDownInterval=0" `
                    -e "PS_STRESS_StressInterval=1" `
                    -e "PS_STRESS_RestInterval=1" `
                    -e "PS_STRESS_RandomizeIntervals=s,r" `
                    -e "PS_STRESS_MaxIntervalDuration=5" `
                    -e "PS_STRESS_CpuThreads=1" `
                    -e "PS_STRESS_MemThreads=1" `
                    -e "PS_STRESS_NoExit=1" `
                    -it `
                    mcr.microsoft.com/powershell:nanoserver-1809 `
                    pwsh -ExecutionPolicy Bypass -command "/psstress/docker.ps1"

#>

Set-Location -Path $PSScriptRoot
Push-Location -Path $PSScriptRoot

Import-Module $(Split-Path $Script:MyInvocation.MyCommand.Path) -Force

if ( $env:PS_STRESS_EnableWebServerOnly ) {

    $port = $env:PS_STRESS_WebServerPort ??= '8080'

    Start-Process -FilePath "pwsh" -Verb RunAs -ArgumentList ('-File','.\webserver.ps1','-port',$port)

}
else {

    $switchParams = @('PS_STRESS_NoCPU','PS_STRESS_NoMemory','PS_STRESS_NoStress','PS_STRESS_NoExit',
                      'PS_STRESS_ShowDebugData','PS_STRESS_EnableWebServer', 'PS_STRESS_EnableWebServerConsoleLogs')
    $arrayParams  = @('PS_STRESS_RandomizeIntervals')

    $params = @{}

    if ( $env:PS_STRESS_ShowDebugData ) {
        write-host "`nThe following environment variables were found:" -ForegroundColor Magenta
        Get-Item -Path Env:* | Out-String
        write-host "`nThe following environment variables will be used:" -ForegroundColor Magenta
    }

    Get-Item -Path Env:\PS_STRESS_* |
        ForEach-Object {
            if ( $env:PS_STRESS_ShowDebugData ) { "... $($_.Name) = $($_.Value)" }
            $key   = $_.Name.Replace('PS_STRESS_','')
            $value = if    ( $_.Name -in $switchParams ) { $true }
                    elseif ( $_.Name -in $arrayParams )  { $_.value -split ',' }
                    else                                 { $_.value }
            $params.Add($key,$value)
        }

    Start-Stressing @params

}
