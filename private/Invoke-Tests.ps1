#------------------------------------------------------------------------------------------------------------------
function Invoke-Tests
#------------------------------------------------------------------------------------------------------------------
{
    <#
    .DESCRIPTION
        Runs CPU and memory stress tests.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [Int]      $CPUthreads,
        [Parameter(Mandatory)] [Int]      $MEMthreads,
        [Parameter(Mandatory)] [Int]      $StressInterval,
        [Parameter(Mandatory)] [Int]      $RestInterval,
        [Parameter(Mandatory)] [DateTime] $EndTime
    )

    do {

        $intervalType      = $( if ( $intervalType -eq 'stress' ) { 'rest' } else { 'stress' } )
        $intervalTime      = $( if ( $intervalType -eq 'stress' ) { $StressInterval } else { $RestInterval } )
        $intervalStartTime = ( Get-Date )
        $intervalEndTime   = ( Get-Date ) + ( New-TimeSpan -Minutes $intervalTime )

        if ( $intervalEndTime -gt $EndTime ) {
            $intervalEndTime = $EndTime
            $intervalTime = (NEW-TIMESPAN -Start ( Get-Date ) -End $EndTime).Minutes
        }

        if ( $intervalTime -gt 0 ) {

            if ( $intervalType -eq 'stress' ) {

                $eventData = @{
                    Message    = "Starting stress interval ..."
                    Duration   = $intervalTime
                    StartTime  = $intervalStartTime
                    EndTime    = $intervalEndTime
                    CPUthreads = $CPUthreads
                    MEMthreads = $MEMthreads
                }
                Write-EventMessage @eventData

                if ( $CPUthreads -gt 0 ) {
                    foreach ( $thread in 1..$CPUthreads ){
                        Start-Job -ScriptBlock {
                            foreach ( $number in 1..2147483647)  {
                                1..2147483647 | ForEach-Object { $x = 1 }{ $x = $x * $_ }
                            }
                        } | Out-Null
                    }
                }

                if ( $MEMthreads -gt 0 ) {
                    foreach ( $thread in 1..$MEMthreads ){
                        Start-Job -ScriptBlock {
                            1..50 | ForEach-Object { $x = 1 }{ [array]$x += $x }
                        } | Out-Null
                    }
                }

                Write-Info -I -M $( "... {0} Jobs started ..." -f @(get-job).count )

                $intervalTime..1 | ForEach-Object {
                    Write-Info -I -M $( "... Event will complete in {0} minute(s)." -f $_ )
                    Start-Sleep -Seconds 60
                }

                Write-Info -I -M $( "... Cleaning up jobs." )
                get-job | stop-job
                get-job | Remove-Job

                Write-Info -I -M $( "... Event completed." )

            }
            else {

                $eventData = @{
                    Message   = "Starting rest interval ..."
                    Duration  = $intervalTime
                    StartTime = ( Get-Date )
                    EndTime   = ( Get-Date ) + ( New-TimeSpan -Minutes $intervalTime )
                }
                Write-EventMessage @eventData -wait

            }
        }

    } until ( (Get-Date) -ge $EndTime )

}
