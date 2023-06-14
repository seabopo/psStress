function Start-WebServer
{
    <#
    .DESCRIPTION
        Runs a basic webserver which serves the log file holding a copy of the module's console messages.
    #>
    [CmdletBinding()]
    param (
        [Parameter()] [Alias('p')] [Int] $Port = 8080
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
            Write-Info -p -m $msg.starting -nl

            $wsListener = New-Object System.Net.HttpListener
            $wsListener.Prefixes.Add( $( "http://*:{0}/" -f $Port ) )
            $wsListener.Start()
            $Error.Clear()

            Write-Info -m $( $msg.started -f $Port ) -nl

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

                Write-Info -m $log -nl

                switch ($uri)
                {
                    "GET /userlog" { $contentPath = $WS_USR_LOG_PATH; break }
                    "GET /applog"  { $contentPath = $WS_APP_LOG_PATH; break }
                    "GET /stop"    { $wsListener.Stop(); break wsListener }
                    default        { $contentPath = $WS_APP_LOG_PATH; break }
                }

                $ResponseText = $((Get-Content -path $WS_HEADER_PATH) -Join "`r`n") +
                                $((Get-Content -path $contentPath) -Join "`r`n") +
                                $((Get-Content -path $WS_FOOTER_PATH) -Join "`r`n")

                $buffer = [Text.Encoding]::UTF8.GetBytes($ResponseText)

                $response.AddHeader("Last-Modified", [IO.File]::GetLastWriteTime($contentPath).ToString('r'))
                $response.AddHeader("Server", "psStress")
                $response.SendChunked = $FALSE
                $response.ContentType = "text/HTML"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
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
