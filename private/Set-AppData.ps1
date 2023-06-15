function Add-CallParameters
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

  # Add all of the calling function's Parameters and default values
    (Get-PSCallStack)[1].InvocationInfo.MyCommand.ScriptBlock.Ast.Body.ParamBlock.Parameters |
        ForEach-Object {
            if ( $_.StaticType.Name -eq 'SwitchParameter' -and $null -eq $_.DefaultValue ) {
                $appData.Add( $_.Name.VariablePath.UserPath.ToString(), $false )
            }
            else {
                $appData.Add( $_.Name.VariablePath.UserPath.ToString(), $_.DefaultValue.Value )
            }
        }

  # Overwrite default values with any passed values.
    $appData.BoundParameters.GetEnumerator() |
        ForEach-Object {
            if ( $appData.ContainsKey($_.key) ) { $appData[$_.key] = $_.value }
        }

    $AppData.Remove('BoundParameters')

    return $appData
}

function Test-UserIsAdmin
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    $AppData.Add('UserIsAdmin',$isAdmin)

    return $appData
}

function Test-IsContainer
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    $isContainer = $false

    if ( $IsWindows ) {
        if     ( $(Get-Service -Name cexecsvc -ErrorAction SilentlyContinue) )   { $isContainer = $true }
        elseif ( $env:POWERSHELL_DISTRIBUTION_CHANNEL -like '*PSDocker*' )       { $isContainer = $true }
        elseif ( $env:USERNAME -in @('ContainerUser','ContainerAdministrator') ) { $isContainer = $true }
    }

    $AppData.Add('isContainer',$isContainer)

    return $appData
}

function Test-IsNanoServer
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    $isNanoServer = $false

    if ( $IsWindows ) {
        if ( $env:POWERSHELL_DISTRIBUTION_CHANNEL -like '*NanoServer*' ) { $isNanoServer = $true }
    }

    $AppData.Add('isNanoServer',$isNanoServer)

    return $appData
}

function Add-PhysicalMemory
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    $physicalMemory = $null

    if ( $IsWindows ) {
        if ( $null -eq $(Get-Service -Name cexecsvc -ErrorAction SilentlyContinue) ) {
            $physicalMemory = [math]::Round((Get-ComputerInfo).OsTotalVisibleMemorySize/1024)
        }
    }

    $AppData.Add('PhysicalMemory',$physicalMemory)

    return $appData
}

function Add-LogicalCores
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    $logicalCores = $null

    if ( $IsWindows ) {
        if ( $appData.IsContainer ) { $logicalCores = $Env:NUMBER_OF_PROCESSORS }
        else { $logicalCores = (Get-ComputerInfo).CsNumberOfLogicalProcessors }
    }

    $AppData.Add('LogicalCores',$logicalCores)

    return $appData
}

function Update-MemoryThreadCount
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    if ( $appData.MemThreads -eq 0 ) {
         $appData.MemThreads = if ( $appData.NoMemory ) { 0 }
                               elseif ($appData.PhysicalMemory -gt 16384 ) { 2 }
                               else { 1 }
    }

    return $appData
}

function Update-CpuThreadCount
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    if ( $appData.CpuThreads -eq 0 ) {
         $appData.CpuThreads = if     ( $appData.NoCPU )            { 0 }
                               elseif ( $appData.LogicalCores )     { $appData.LogicalCores - $appData.MemThreads }
                               elseif ( $appData.MemThreads -ge 2 ) { 0 }
                               else                                 { 2 - $appData.MemThreads }
    }

    return $appData
}

function Update-MaxStressDuration
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    if ( $appData.StressDuration -eq 0 ) { $appData.StressDuration = [int32]::MaxValue }

    return $AppData
}

function Update-RandomizedIntervals
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    if ( $appData.RandomizeIntervals ) {

        if ( $appData.RandomizeIntervals.Contains('d') -and $appData.StressDuration -ne [int32]::MaxValue ) {
             $appData.StressDuration = Get-Random -Minimum $appData.StressDuration `
                                                  -Maximum $appData.MaxIntervalDuration
        }

        if ( $appData.RandomizeIntervals.Contains('w') ) {
             $appData.WarmUpInterval = Get-Random -Minimum $appData.WarmUpInterval `
                                                  -Maximum $appData.MaxIntervalDuration
        }

        if ( $appData.RandomizeIntervals.Contains('c') ) {
             $appData.CoolDownInterval = Get-Random -Minimum $appData.CoolDownInterval `
                                                    -Maximum $appData.MaxIntervalDuration
        }

        $appData.Add('RandomizeStress',$RandomizeIntervals.Contains('s'))
        $appData.Add('RandomizeRest',$RandomizeIntervals.Contains('r'))
    }
    else {
        $appData.Add('RandomizeStress',$false)
        $appData.Add('RandomizeRest',$false)
    }

    $stressEndTime = (Get-Date) + ( New-TimeSpan -Minutes $StressDuration )

    $maxSCinterval = if ( $appData.StressDuration -lt $appData.MaxIntervalDuration ) { $appData.StressDuration }
                     else { $appData.MaxIntervalDuration }

    $appData.Add('StressEndTime',$stressEndTime)
    $appData.Add('MaxStressCycleInterval',$maxSCinterval)

    return $AppData
}

function Add-TotalIntervalTime
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    $totalIntervalTime = if ( $appData.NoStress ) { 0 }
                         else { $appData.WarmUpInterval + $appData.StressDuration + $appData.CoolDownInterval }

    $appData.Add('TotalIntervalTime',$totalIntervalTime)

    return $AppData
}

function Add-UserMessages
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    if ( $appData.RandomizeIntervals ) {
        $stressVal = $appData.RandomizeIntervals.Contains('s') ?
                     $('{0}-{1}' -f $appData.StressInterval, $appData.MaxStressCycleInterval) :
                     $appData.StressInterval
        $restVal   = $appData.RandomizeIntervals.Contains('r') ?
                     $('{0}-{1}' -f $appData.RestInterval, $appData.MaxStressCycleInterval) :
                     $appData.RestInterval
        $randVal   = $appData.RandomizeIntervals -join ','
    }
    else {
        $stressVal = $appData.StressInterval
        $restVal   = $appData.RestInterval
        $randVal   = ''
    }

    $messages = @{

        paramError = "Intervals aborted. Invalid parameters: 'NoCPU' and 'NoMemory' are exclusive."
        start      = "Starting ..."
        warm       = "Starting warm up interval ..."
        startcycle = "Starting stress/rest interval cycle ..."
        stress     = "Starting stress interval ..."
        rest       = "Starting rest interval ..."
        cool       = "Starting cool down interval ..."
        completed  = "All intervals completed."
        error      = "Intervals failed."
        noexit     = "The NoExit switch was detected.`r`nThis process will now wait indefinitely."
        exit       = "The process is now exiting ..."
        nostress   = "The NoStress switch was detected.`r`nAll intervals will be skipped."

        warmint    = "... Warm Interval: {0} minutes"   -f $appData.WarmUpInterval
        coolint    = "... Cool Interval: {0} minutes"   -f $appData.CoolDownInterval
        strescyc   = "... Stress Cycle: {0} minutes"    -f $appData.StressDuration
        stresint   = "... Stress Interval: {0} minutes" -f $stressVal
        restint    = "... Rest Interval: {0} minutes"   -f $restVal
        randomized = "... Randomized Interval(s): {0}"  -f $randVal
        cputhreads = "... CPU Threads: {0}"             -f $appData.CPUthreads
        memthreads = "... Memory Threads: {0}"          -f $appData.MEMthreads

        container  = "... Running in Container: {0}"   -f $appData.isContainer
        adminuser  = "... User is Admin: {0}"          -f $appData.UserIsAdmin

        startingws = "Starting web server ..."
        wselevate  = "... User does not have admin rights. Attempting to elevate ..."
        startedws  = "... Web server started on port {0}." -f $appData.WebServerPort
        nostartws  = "... CANNOT START WEB SERVER. User does not have admin rights."

        jobs      = "... Jobs started: {0}"
        countdown = "... Interval will complete in {0} minute(s) ..."
        cleanup   = "... Cleaning up jobs ..."
        complete  = "... Interval complete."
    }

    $appData.Add('Messages',$messages)

    return $AppData
}















function Test-HasCIM
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    $hasCIM = $false

    if ( $IsWindows ) {
        try {
            Get-CimInstance -ClassName Win32_ComputerSystem
            $hasCIM = $true
        }
        catch { }
    }

    $AppData.Add('HasCIM',$hasCIM)

    return $appData
}

function Test-UserCanRunAs
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    try {
        $proc = Start-Process -FilePath "pwsh" -Verb RunAs -PassThru -ArgumentList('dir')
        $AppData.Add('UserCanRunAs',$true)
    }
    catch {
        $AppData.Add('UserCanRunAs',$false)
    }

    return $appData
}

function Test-UserCanRunWebServer
{
    [CmdletBinding()] [OutputType([PSCustomObject])]
    param ( [Parameter(Mandatory,ValueFromPipeline)] [PSCustomObject] $AppData )

    try {
        $wsListener = New-Object System.Net.HttpListener
        $wsListener.Prefixes.Add( $( "http://*:8888/") )
        $wsListener.Start()
        if ($wsListener.IsListening) { $wsListener.Stop() }
        $wsListener.Close()
        $AppData.Add('UserCanRunWebServer',$true)
    }
    catch {
        $AppData.Add('UserCanRunWebServer',$false)
    }

    return $appData
}
