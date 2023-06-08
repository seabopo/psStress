#------------------------------------------------------------------------------------------------------------------
function Write-EventMessage
#------------------------------------------------------------------------------------------------------------------
{
    <#
    .DESCRIPTION
        Writes an event message. Includes 1-minute countdown messages until the end time is reached.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [String]   $Message,
        [Parameter(Mandatory)] [Int]      $Duration,
        [Parameter(Mandatory)] [DateTime] $StartTime,
        [Parameter(Mandatory)] [DateTime] $EndTime,
        [Parameter()]          [Int]      $CPUthreads = $null,
        [Parameter()]          [Int]      $MEMthreads = $null,
        [Parameter()]          [Switch]   $Wait
    )

    $PassedParameters = $PSBoundParameters # Powershell bug prevents direct access

    Write-Info -P -M $Message -PS
    Write-Info -I -M $( "... Duration: {0} minutes" -f $Duration  )
    Write-Info -I -M $( "... Start Time: {0}"       -f $StartTime )
    Write-Info -I -M $( "... End Time: {0}"         -f $EndTime   )

    if ( $PassedParameters.ContainsKey('CPUthreads') ) {
        Write-Info -I -M $("... CPU Threads: {0}"    -f $CPUthreads )
    }

    if ( $PassedParameters.ContainsKey('MEMthreads') ) {
        Write-Info -I -M $("... Memory Threads: {0}" -f $MEMthreads )
    }

    If ( $Wait -and $Duration -gt 0 ) {
        $Duration..1 | ForEach-Object {
            Write-Info -I -M $( "... Event will complete in {0} minute(s)." -f $_ )
            Start-Sleep -Seconds 60
        }
        Write-Info -I -M $( "... Event completed." )
    }

}
