function Invoke-Tests
{
    <#
    .DESCRIPTION
        Runs CPU and memory stress tests.
    #>
    [CmdletBinding()]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    process
    {
        do {

            if ( $stress ) { $stress = $false; $rest = $true;  $duration = $appData.RestInterval   }
            else           { $stress = $true;  $rest = $false; $duration = $appData.StressInterval }

            if ( ($stress -and $appData.RandomizeStress) -or ($rest -and $appData.RandomizeRest) ) {
                $duration = Get-Random -Minimum $duration -Maximum $appData.MaxStressCycleInterval
            }

            if ( ( (Get-Date) + (New-TimeSpan -Minutes $duration) ) -gt $appData.StressEndTime ) {
                $duration = (NEW-TIMESPAN -Start ( Get-Date ) -End $appData.StressEndTime).Minutes
            }

            if ( $stress -and $duration -gt 0 ) {

                Write-EventMessages -m $appData.messages.stress `
                                    -d $duration `
                                    -c $appData.CPUthreads `
                                    -r $appData.MEMthreads

                if ( $appData.CPUthreads -gt 0 ) {
                    foreach ( $thread in 1..$appData.CPUthreads ){
                        Start-Job -ScriptBlock {
                            foreach ( $number in 1..2147483647)  {
                                1..2147483647 | ForEach-Object { $x = 1 }{ $x = $x * $_ }
                            }
                        } | Out-Null
                    }
                }

                if ( $appData.MEMthreads -gt 0 ) {
                    foreach ( $thread in 1..$appData.MEMthreads ){
                        Start-Job -ScriptBlock {
                            1..50 | ForEach-Object { $x = 1 }{ [array]$x += $x }
                        } | Out-Null
                    }
                }

                Write-Info -m $( $appData.messages.jobs -f @(get-job).count )

                $duration..1 | ForEach-Object {
                    Write-Info -m $( $appData.messages.countdown -f $_ )
                    Start-Sleep -Seconds 60
                }

                Write-Info -m $appData.messages.cleanup
                get-job | stop-job
                get-job | Remove-Job
               #[System.GC]::GetTotalMemory(‘forcefullcollection’) | out-null
                [System.GC]::Collect()
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()

                Write-Info -m $appData.messages.complete

            }
            elseif ( $rest -and $duration -gt 0 ) {

                Write-EventMessages -m $appData.messages.rest -d $duration -wait

            }

        } until ( (Get-Date) -ge $appData.StressEndTime )
    }
}
