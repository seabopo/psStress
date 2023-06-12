function Invoke-Tests
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
        [Parameter(Mandatory)] [Int]      $MaxInterval,
        [Parameter(Mandatory)] [Bool]     $RandomizeStress,
        [Parameter(Mandatory)] [Bool]     $RandomizeRest,
        [Parameter(Mandatory)] [DateTime] $EndTime
    )

    begin
    {
      # User messages
        $msg = @{
            stress    = "Starting stress interval ..."
            rest      = "Starting rest interval ..."
            jobs      = "... Jobs started: {0}"
            countdown = "... Interval will complete in {0} minute(s) ..."
            cleanup   = "... Cleaning up jobs ..."
            complete  = "... Interval complete."
        }
    }

    process
    {
        do {

            if ( $stress ) { $stress = $false; $rest = $true;  $duration = $RestInterval   }
            else           { $stress = $true;  $rest = $false; $duration = $StressInterval }

            if ( ($stress -and $RandomizeStress) -or ($rest -and $RandomizeRest) ) {
                $duration = Get-Random -Minimum $duration -Maximum $MaxInterval
            }

            if ( ( (Get-Date) + (New-TimeSpan -Minutes $duration) ) -gt $EndTime ) {
                $duration = (NEW-TIMESPAN -Start ( Get-Date ) -End $EndTime).Minutes
            }

            if ( $stress -and $duration -gt 0 ) {

                Write-EventMessages -m $msg.stress -d $duration -c $CPUthreads -r $MEMthreads

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

                Write-Info -I -M $( $msg.jobs -f @(get-job).count )

                $duration..1 | ForEach-Object {
                    Write-Info -I -M $( $msg.countdown -f $_ )
                    Start-Sleep -Seconds 60
                }

                Write-Info -I -M $msg.cleanup
                get-job | stop-job
                get-job | Remove-Job
               #[System.GC]::GetTotalMemory(‘forcefullcollection’) | out-null
                [System.GC]::Collect()
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()

                Write-Info -I -M $msg.complete

            }
            elseif ( $rest -and $duration -gt 0 ) {

                Write-EventMessages -m $msg.rest -d $duration -wait

            }

        } until ( (Get-Date) -ge $EndTime )
    }
}
