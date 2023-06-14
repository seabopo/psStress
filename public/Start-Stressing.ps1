function Start-Stressing
{
    <#
    .SYNOPSIS
        Executes CPU and/or memory stress tests.

    .DESCRIPTION
        Executes CPU and/or memory stress tests.

    .OUTPUTS
        Console status messages on the testing status only.

    .PARAMETER StressDuration
        OPTIONAL. Integer. Alias: -sd. The total time, in minutes, for a series of stress and rest intervals to
        execute. This does not include warm up or cool down intervals. Setting a StressDuration of 0 will make
        the intervals run for [int32]::MaxValue (2,147,483,647) minutes, which is 1,491,308 days or 4,086 years.
        Default Value: 30.

     .PARAMETER StressInterval
        OPTIONAL. Integer. Alias: -si. The time, in minutes, that each stress interval should run for. The stress
        interval puts CPU and/or Memory stress (load) on the instance.
        Default Value: 5.

    .PARAMETER RestInterval
        OPTIONAL. Integer. Alias: -ri. The time, in minutes, to remove all load after each stress interval.
        Default Value: 5.

    .PARAMETER WarmUpInterval
        OPTIONAL. Integer. Alias: -wi. The time, in minutes, to wait before starting the stress/rest intervals.
        A single Warm Up Interval is exectuted at the start of the session. The Warm Up Interval is not included
        in the StressDuration.
        Default Value: 0.

    .PARAMETER CoolDownInterval
        OPTIONAL. Integer. Alias: -ci. The time, in minutes, to wait after the stress/rest intervals have
        completed before exiting the PowerShell process. A single Coold Down Interval is exectuted at the end of
        the session. The Coold Down Interval is not included in the StressDuration.
        Default Value: 0.

    .PARAMETER CpuThreads
        OPTIONAL. Integer. Alias: -ct. The number of threads to use for CPU stressing.
        Default Value: 0 (Automatically calculated). Physical and virtualized Windows devices will use 1 thread
        per logical core. Mac OS, Linux and Window containers will use 2 threads. Passing a zero will enable
        automatic calculation. Use the NoCPU switch to ignore this test instead of setting CpuThreads to 0.
        Memory threads also stress the CPU, so when 0 (Automatically calculated) CPU threads the final CPU
        thread count will be CPU threads - Memory threads. Memory threads are not subtracted from CPU threads
        when CPU threads are manually set.

    .PARAMETER MemThreads
        OPTIONAL. Integer. Alias: -mt. The number of threads to use for memory stressing.
        Default Value: 0 (Automatically calculated). Physical and virtualized Windows devices will use 2 threads
        if memory is greater than 16GB. All other devices will use 1 thread. Passing a zero will enable
        automatic calculation. Use the NoMemory switch to ignore this test instead of setting MemThreads to 0.

    .PARAMETER RandomizeIntervals
        OPTIONAL. Array of String. Alias: -rz. An array of single characters indicating the intervals that should
        be randomized. If an interval is included in this parameter the randomized time will use the defined
        interval time as the minimum value and the MaxIntervalDuration as the maximum value.
        Default: none.
        Supported Values:
            Stress(D)uration
            (W)armUpInterval
            (C)oolDownInterval
            (S)tressInterval
            (R)estInterval

    .PARAMETER MaxIntervalDuration
        OPTIONAL. Integer. Alias: -md. The maximum time, in minutes, to use for interval randomization.
        Default: 1440 (24 hours)

    .PARAMETER NoCPU
        OPTIONAL. Switch. Alias: -nc. Disables CPU tests. This is exclusive with NoMemory.

    .PARAMETER NoMemory
        OPTIONAL. Switch. Alias: -nm. Disables memory tests. This is exclusive with NoCPU.

    .PARAMETER NoExit
        OPTIONAL. Switch. Alias: -nx. Prevents the PowerShell process from exiting after the Cool Down Interval
        has ended. Use this setting to emulate a service in k8s or other systems that use a scheduler so the
        StressDuration paramater is honored and scheduler doesn't keep restarting the the container/pod.

    .PARAMETER EnableWebServer
        OPTIONAL. Switch. Alias: -ws. Enables a webserver which displays the console log messages.

    .PARAMETER WebServerPort
        OPTIONAL. INT. Alias: -wp. Sets the WebServer port. Default: 8080

    .EXAMPLE

        Start-Stressing -sd 60 -wi 2 -ci 0 -si 5 -ri 5 -RandomizeIntervals d,s,r -NoExit

    #>
    [CmdletBinding()]
    param (
        [Parameter()] [Alias('sd')] [ValidateRange(0, [int]::MaxValue)] [Int]      $StressDuration      = 10,
        [Parameter()] [Alias('wi')] [ValidateRange(0, [int]::MaxValue)] [Int]      $WarmUpInterval      = 1,
        [Parameter()] [Alias('ci')] [ValidateRange(0, [int]::MaxValue)] [Int]      $CoolDownInterval    = 0,
        [Parameter()] [Alias('si')] [ValidateRange(0, [int]::MaxValue)] [Int]      $StressInterval      = 5,
        [Parameter()] [Alias('ri')] [ValidateRange(0, [int]::MaxValue)] [Int]      $RestInterval        = 5,
        [Parameter()] [Alias('ct')] [ValidateRange(0, [int]::MaxValue)] [Int]      $CpuThreads          = 0,
        [Parameter()] [Alias('mt')] [ValidateRange(0, [int]::MaxValue)] [Int]      $MemThreads          = 0,
        [Parameter()] [Alias('rz')] [ValidateSet("d","w","c","s","r")]  [String[]] $RandomizeIntervals  = @(),
        [Parameter()] [Alias('md')] [ValidateRange(0, [int]::MaxValue)] [Int]      $MaxIntervalDuration = 1440,
        [Parameter()] [Alias('nc')]                                     [Switch]   $NoCPU,
        [Parameter()] [Alias('nm')]                                     [Switch]   $NoMemory,
        [Parameter()] [Alias('nx')]                                     [Switch]   $NoExit,
        [Parameter()] [Alias('ws')]                                     [Switch]   $EnableWebServer,
        [Parameter()] [Alias('wp')] [ValidateRange(0, [int]::MaxValue)] [Int]      $WebServerPort       = 8080
    )

    begin
    {
      # Update the CPU and Memory threads based on the automatic setting (0)
        $CpuThreads, $MemThreads = Get-ThreadCounts -CPU $CpuThreads -NoCPU:$NoCPU `
                                                    -Memory $MemThreads -NoMemory:$NoMemory

      # Update the single-use intervals based on the the RandomizeIntervals parameter.
        if ( $StressDuration -eq 0 ) {
            $StressDuration = [int32]::MaxValue }
        elseif ( $RandomizeIntervals.Contains('d') ) {
            $StressDuration = Get-Random -Minimum $StressDuration -Maximum $MaxIntervalDuration
        }

        if ( $RandomizeIntervals.Contains('w') ) {
            $WarmUpInterval = Get-Random -Minimum $WarmUpInterval -Maximum $MaxIntervalDuration
        }

        if ( $RandomizeIntervals.Contains('c') ) {
            $CoolDownInterval = Get-Random -Minimum $CoolDownInterval -Maximum $MaxIntervalDuration
        }

      # The end time of the stress cycle
        $StressEndTime = (Get-Date) + ( New-TimeSpan -Minutes $StressDuration )

      # The total time for all intervals
        $totalIntervalTime = $WarmUpInterval + $StressDuration + $CoolDownInterval

      # The max Stress Cycle Interval for user messages
        $maxSCinterval = if ( $StressDuration -lt $MaxIntervalDuration ) { $StressDuration }
                         else { $MaxIntervalDuration }

      # User messages
        $msg = @{
            paramError = "Intervals aborted. Invalid parameters: 'NoCPU' and 'NoMemory' are exclusive."
            start      = "Starting intervals ..."
            warm       = "Starting warm up interval ..."
            startcycle = "Starting stress/rest interval cycle ..."
            cool       = "Starting cool down interval ..."
            complete   = "All intervals completed."
            error      = "Intervals failed."
            noexit     = "The NoExit switch was detected.`n`rThis process will now wait indefinitely ..."

            warmint    = "... Warm Interval: {0} minutes"   -f $WarmUpInterval
            coolint    = "... Cool Interval: {0} minutes"   -f $CoolDownInterval
            strescyc   = "... Stress Cycle: {0} minutes"    -f $StressDuration
            randomized = "... Randomized Interval(s): {0}"  -f $( $RandomizeIntervals -join ',' )
            stresint   = "... Stress Interval: {0} minutes" -f $( $RandomizeIntervals.Contains('s') ?
                                                                  $('{0}-{1}' -f $StressInterval,$maxSCinterval) :
                                                                  $StressInterval )
            restint    = "... Rest Interval: {0} minutes"   -f $( $RandomizeIntervals.Contains('r') ?
                                                                  $('{0}-{1}' -f $RestInterval,$maxSCinterval) :
                                                                  $RestInterval )

            startingws = "... Starting web server. THIS REQUIRES ADMIN RIGHTS."
            startedws  = "... Web server started on port {0}." -f $WebServerPort
        }

      # Clear the log files
        $null | Out-File $WS_APP_LOG_PATH
        $null | Out-File $WS_USR_LOG_PATH
    }

    process
    {
        try {

            if ( $NoCPU -and $NoMemory ) { Write-Info -e -m $msg.paramError; return }

            Write-EventMessages -m $msg.start -d $totalIntervalTime -c $CpuThreads -r $MemThreads
            Write-Info -M $msg.warmint
            Write-Info -M $msg.coolint
            Write-Info -M $msg.strescyc
            Write-Info -M $msg.stresint
            Write-Info -M $msg.restint
            Write-Info -M $msg.randomized

            if ( $EnableWebServer ) {
                Write-Info -M $msg.startingws
               #Start-Process -FilePath "pwsh" -Verb RunAs -ArgumentList ('-File', $WS_START_PATH, '-port', $WebServerPort)
                Start-Process -FilePath "pwsh" -ArgumentList ('-File', $WS_START_PATH, '-port', $WebServerPort)
                Write-Info -M $($msg.startedws -f $WebServerPort)
            }

            Write-EventMessages -m $msg.warm -d $WarmUpInterval -Wait

            Write-EventMessages -m $msg.startcycle -d $StressDuration

            $eventData = @{
                CPUthreads      = $CpuThreads
                MEMthreads      = $MemThreads
                StressInterval  = $StressInterval
                RestInterval    = $RestInterval
                MaxInterval     = $MaxIntervalDuration
                RandomizeStress = $RandomizeIntervals.Contains('s')
                RandomizeRest   = $RandomizeIntervals.Contains('r')
                EndTime         = $StressEndTime
            }
            Invoke-Tests @eventData

            Write-EventMessages -m $msg.cool -d $CoolDownInterval -Wait

            Write-Info -P -PS -M $msg.complete

            if ( $NoExit ) {
                Write-Info -P -PS -M $msg.noexit
                Wait-Event -1
            }
        }
        catch {
            Write-Info -E -M $msg.error
            $_
        }
    }
}
