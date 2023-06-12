#------------------------------------------------------------------------------------------------------------------
function Write-EventMessages
#------------------------------------------------------------------------------------------------------------------
{
    <#
    .DESCRIPTION
        Writes an event message. Includes 1-minute countdown messages until the end time is reached.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [Alias('m')] [String] $Message,
        [Parameter(Mandatory)] [Alias('d')] [Int]    $Duration,
        [Parameter()]          [Alias('c')] [Int]    $CPUthreads = $null,
        [Parameter()]          [Alias('r')] [Int]    $MEMthreads = $null,
        [Parameter()]          [Alias('w')] [Switch] $Wait
    )

    $PassedParameters = $PSBoundParameters # Powershell bug prevents direct access

    $StartTime = ( Get-Date )
    $EndTime   = ( Get-Date ) + ( New-TimeSpan -Minutes $Duration )

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

    If ( $Wait ) {
        If ( $Duration -gt 0 ) {
            $Duration..1 | ForEach-Object {
                Write-Info -I -M $( "... Interval will complete in {0} minute(s) ..." -f $_ )
                Start-Sleep -Seconds 60
            }
        }
        Write-Info -I -M $( "... Interval complete." )
    }

}
