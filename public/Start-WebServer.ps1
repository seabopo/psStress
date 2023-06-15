function Start-WebServer
{
    <#
    .DESCRIPTION
        Runs a basic webserver which serves the log file holding a copy of the module's console messages.
    #>
    [CmdletBinding()]
    param (
        [Parameter()] [Alias('p')] [Int]    $Port = 8080,
        [Parameter()] [Alias('c')] [Switch] $EnableConsoleLogs
    )

    begin
    {
        $msg = @{
            starting   = "Starting web server ..."
            started    = "Web server started on port {0}."
        }
    }

    process
    {
        try
        {
            $wsListener = New-Object System.Net.HttpListener
            $wsListener.Prefixes.Add( $( "http://*:{0}/" -f $Port ) )
            $wsListener.Start()
            $Error.Clear()

            Write-Info -m -ps $( $msg.started -f $Port ) -nl

            :wsListener while ($wsListener.IsListening)
            {
                $context   = $wsListener.GetContext()
                $request   = $context.Request
                $response  = $context.Response
                $uri       = "{0} {1}" -f $request.httpMethod, $request.Url.LocalPath

                $log = $( "{0} {1} {2} {3} {4}" -f $(Get-Date -Format s),
                                                   $request.RemoteEndPoint.Address.ToString(),
                                                   $request.httpMethod,
                                                   $request.UserHostName,
                                                   $request.Url.PathAndQuery )

                $log | Out-File $WS_USR_LOG_PATH -Append

                if ( $EnableConsoleLogs ) { Write-Info -m $log -nl }

                $stressAndRedirect = $false

                switch ($uri)
                {
                    "GET /userlog" { $contentPath = $WS_USR_LOG_PATH; break }
                    "GET /applog"  { $contentPath = $WS_APP_LOG_PATH; break }
                    "GET /stop"    { $wsListener.Stop(); break wsListener }
                    "GET /stress10" {
                        Remove-Item -Path Env:\STRESS_*
                        $env:STRESS_WarmUpInterval = 0
                        $env:STRESS_StressDuration = 10
                        $env:STRESS_StressInterval = 10
                        $env:STRESS_RestInterval   = 0
                        $stressAndRedirect         = $true
                        break
                    }
                    "GET /stress10x4" {
                        Remove-Item -Path Env:\STRESS_*
                        $env:STRESS_WarmUpInterval = 0
                        $env:STRESS_StressDuration = 240
                        $env:STRESS_StressInterval = 10
                        $env:STRESS_RestInterval   = 20
                        $stressAndRedirect         = $true
                        break
                    }
                    "GET /stressrnd" {
                        Remove-Item -Path Env:\STRESS_*
                        $env:STRESS_WarmUpInterval      = 0
                        $env:STRESS_StressDuration      = 240
                        $env:STRESS_StressInterval      = 1
                        $env:STRESS_RestInterval        = 1
                        $env:STRESS_MaxIntervalDuration = 60
                        $env:STRESS_RandomizeIntervals  = "s,r"
                        $stressAndRedirect              = $true
                        break
                    }
                    default { $contentPath = $WS_APP_LOG_PATH; break }
                }

                if ( $stressAndRedirect ) {
                    Start-Process -FilePath "pwsh" -ArgumentList ('-File', $DOCKER_PATH)
                    $response.Redirect('/applog')
                }
                else {
                    $ResponseText = $((Get-Content -path $WS_HEADER_PATH) -Join "`r`n") +
                                    $((Get-Content -path $contentPath)    -Join "`r`n") +
                                    $((Get-Content -path $WS_FOOTER_PATH) -Join "`r`n")

                    $buffer = [Text.Encoding]::UTF8.GetBytes($ResponseText)

                    $response.AddHeader("Last-Modified", [IO.File]::GetLastWriteTime($contentPath).ToString('r'))
                    $response.AddHeader("Server", "psStress")
                    $response.SendChunked = $FALSE
                    $response.ContentType = "text/HTML"
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                }
                $response.Close()
            }
        }
        finally
        {
            if ($wsListener.IsListening) { $wsListener.Stop() }
            $wsListener.Close()
        }

    }
}
