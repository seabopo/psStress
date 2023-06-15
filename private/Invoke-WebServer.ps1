function Invoke-WebServer
{
    <#
    .DESCRIPTION
        Runs a local webserver.
    #>
    [CmdletBinding()]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    process
    {
        Write-Info -p -ps -m $appData.messages.startingws

        if ( $appData.UserIsAdmin ) {
            try {
                Start-Process -FilePath "pwsh" `
                              -ArgumentList ('-File', $WS_START_PATH, `
                                             '-Port', $appData.WebServerPort, `
                                             "-EnableConsoleLogs:$($appData.EnableWebServerConsoleLogs)")
                Write-Info -m $($appData.messages.startedws -f $appData.WebServerPort)
            }
            catch {
                Write-Info -e -m $( "... WebServer failed to start: {0}" -f $_.Exception.Message )
            }
        }

        if ( -not $appData.UserIsAdmin -and $appData.IsContainer ) {
            Write-Info -e -m $appData.messages.nostartws
        }

        if ( $isWindows -and -not $appData.UserIsAdmin -and -not $appData.IsContainer ) {
            Write-Info -w -m $appData.messages.wselevate
            try {
                Start-Process -FilePath "pwsh" -Verb RunAs `
                              -ArgumentList ('-File', $WS_START_PATH, `
                                             '-Port', $appData.WebServerPort, `
                                             "-EnableConsoleLogs:$($appData.EnableWebServerConsoleLogs)")
                Write-Info -m $($appData.messages.startedws -f $appData.WebServerPort)
            }
            catch {
                Write-Info -e -m $( "... WebServer failed to start: {0}" -f $_.Exception.Message )
            }
        }

    }
}
