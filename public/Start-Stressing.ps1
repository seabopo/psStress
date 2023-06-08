function Start-Stressing
{
    <#
    .SYNOPSIS
        Executes CPU and/or memory stress tests.

    .DESCRIPTION
        Executes CPU and/or memory stress tests.

    .OUTPUTS
        Console status messages on the testing status only.

    .PARAMETER NoCPU
        OPTIONAL. Switch. Alias: -nc. Disables CPU tests.

    .PARAMETER NoMemory
        OPTIONAL. Switch. Alias: -nm. Disables memory tests.

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

    .EXAMPLE

        Start-Stressing -tt 60 -wt 2 -ct 1 -si 5 -ri 5

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter()] [Alias('nc')] [Switch] $NoCPU,
        [Parameter()] [Alias('nm')] [Switch] $NoMemory,
        [Parameter()] [Alias('wt')] [Int]    $WarmUpTime     = 0,
        [Parameter()] [Alias('ct')] [Int]    $CoolDownTime   = 0,
        [Parameter()] [Alias('tt')] [Int]    $TestTime       = 30,
        [Parameter()] [Alias('si')] [Int]    $StressInterval = 5,
        [Parameter()] [Alias('ri')] [Int]    $RestInterval   = 5
    )

    begin
    {
        if ( $null -eq $(Get-Service -Name cexecsvc -ErrorAction SilentlyContinue) ) {
            $logicalCPUs = (Get-ComputerInfo).CsNumberOfLogicalProcessors
            $physicalMem = [math]::Round((Get-ComputerInfo).OsTotalVisibleMemorySize/1024)
        }
        else {
            $logicalCPUs = $null
            $physicalMem = $null
        }
        $memThreads      = if ( $NoMemory ) { 0 } elseif ( $null -eq $physicalMem -or $physicalMem -ge 16384 ) { 2 } else { 1 }
        $cpuThreads      = if ( $NoCPU    ) { 0 } elseif ( $null -eq $logicalCPUs ) { 2 } else { $logicalCPUs - $memThreads }
        $TestStartTime   = ( Get-Date )
        $TestEndTime     = $TestStartTime + ( New-TimeSpan -Minutes $TestTime )
    }

    process
    {
        try {

            if ( $NoCPU -and $NoMemory ) {
                Write-Info -e -m $( "Stress test failed. 'NoCPU' and 'NoMemory' switches were both used." )
                return
            }

            $eventData = @{
                Message   = "Starting Tests ..."
                Duration  = $TestTime
                StartTime = $TestStartTime
                EndTime   = $TestEndTime
            }
            Write-EventMessage @eventData
            if ($null -ne $logicalCPUs ) { Write-Info -I -M $( "... Logical CPUs: {0}"    -f $logicalCPUs ) }
            if ($null -ne $physicalMem ) { Write-Info -I -M $( "... Total Memory: {0} MB" -f $physicalMem ) }

            $eventData = @{
                Message   = "Starting warm up ..."
                Duration  = $WarmUpTime
                StartTime = ( Get-Date )
                EndTime   = ( Get-Date ) + ( New-TimeSpan -Minutes $WarmUpTime )
            }
            Write-EventMessage @eventData -Wait

            $eventData = @{
                CPUthreads     = $cpuThreads
                MEMthreads     = $memThreads
                StressInterval = $StressInterval
                RestInterval   = $RestInterval
                EndTime        = $TestEndTime
            }
            Invoke-Tests @eventData

            $eventData = @{
                Message   = "Starting cool down ..."
                Duration  = $CoolDownTime
                StartTime = ( Get-Date )
                EndTime   = ( Get-Date ) + ( New-TimeSpan -Minutes $CoolDownTime )
            }
            Write-EventMessage @eventData -Wait

            Write-Info -P -PS -M "All tests completed."

        }
        catch {
            Write-Info -E -M $( "Stress test failed." )
            Write-Info -E -M $( "... Message: {0}" -f $_.Exception.Message )
            Write-Info -E -M $( "... Details: {0}" -f $_.ErrorDetails.Message )
            $_
        }
    }
}
